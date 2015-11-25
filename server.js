var winston = require('winston');
var multer = require('multer');
var bodyParser = require('body-parser');
var express = require("express");
var app = express();
var path = require('path');
var fs = require('fs');
var md5File = require('md5-file');
var moment = require('moment');
var schedule = require('node-schedule');
var yubikey = require('./lib/yubikey.js');
moment().format();

function infoWrapper(message) {
    var timestamp = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
    winston.log('info', "[" + timestamp + "] %s", message);
}

function warningWrapper(message) {
    var timestamp = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
    winston.log('warn', "[" + timestamp + "] %s", message);
}

function errorWrapper(message) {
    var timestamp = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
    winston.log('error', "[" + timestamp + "] %s", message);
}

/* --- Configuration parsing --- */

var config = JSON.parse(fs.readFileSync('lib/config.js'));

if (Object.prototype.toString.call(config.apiId) === '[object Array]') {
    if (Object.prototype.toString.call(config.apiKey) === '[object Array]') {
        if (config.apiId.length !== config.apiKey.length) {
            if (config.apiId.length === 0 || config.apiKey.length === 0) {
                errorWrapper('Configuration missing: have you edited the defaults in "lib/config.js"?');
            } else {
                errorWrapper('Configuration mismatch: not the same number of API IDs and Keys.');
            }
            process.exit(1);
        }
    } else {
        errorWrapper('Configuration mismatch: API Keys field is not an array.');
        process.exit(1);
    }
} else {
    errorWrapper('Configuration mismatch: API IDs field is not an array.');
    process.exit(1);
}

yubikey.apiId = config.apiId;
yubikey.apiKey = config.apiKey;
var uploadPath = config.uploadFolder || "uploads/",
    domainUrl = (config.domainName || "http://localhost:9980/") + uploadPath,
    maxFileSize = config.maxFileSize || 52428800,
    maxFileExpiration = config.maxFileExpiration || 30,
    debug = config.debug || false;
/* --- End configuration parsing --- */

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({
    extended: true
}));

var authUpload = function(req, res, next) {
    if (debug) {
        warningWrapper("Bypassing token validation.");
        next();
        return;
    }
    var token = req.query.token;
    yubikey.verify(token, function(isValid, status) {
        if (isValid) {
            infoWrapper("Valid token received.");
            next();
        } else {
            warningWrapper("Invalid token received! Reason: " + status);
            res.status(401).send("AUTH ERROR - " + status + "\n");
        }
    });
}

var dateOk = false;
var deletionDate;
var validateUpload = function(req, res, next) {
    var deletionQuery = req.query.del,
        deletionDay,
        deletionMonth,
        deletionYear;
    if (deletionQuery) {
        if (/^[0-9]+s$/.test(deletionQuery)) {
            deletionDate = moment().add(deletionQuery.substr(0, deletionQuery.indexOf('s')), 'seconds');
        } else if (/^[0-9]+m$/.test(deletionQuery)) {
            deletionDate = moment().add(deletionQuery.substr(0, deletionQuery.indexOf('m')), 'minutes');
        } else if (/^[0-9]+h$/.test(deletionQuery)) {
            deletionDate = moment().add(deletionQuery.substr(0, deletionQuery.indexOf('h')), 'hours');
        } else if (/^[0-9]+d$/.test(deletionQuery)) {
            deletionDate = moment().add(deletionQuery.substr(0, deletionQuery.indexOf('d')), 'days');
        } else if (/^[0-9]{2}D[0-9]{2}M[0-9]{4}Y$/.test(deletionQuery)) {
            deletionDay = deletionQuery.substr(0, deletionQuery.indexOf('D'));
            deletionMonth = deletionQuery.substr(deletionQuery.indexOf('D') + 1, deletionQuery.indexOf('M'));
            deletionYear = deletionQuery.substr(deletionQuery.indexOf('M') + 1, deletionQuery.indexOf('Y'));
            deletionDate = moment(deletionDay + "-" + deletionMonth + "-" + deletionYear, "DD-MM-YYYY");
        } else if (/^[0-9]{2}D[0-9]{2}M[0-9]{4}Y[0-9]{2}h[0-9]{2}m$/.test(deletionQuery)) {
            deletionDay = deletionQuery.substr(0, deletionQuery.indexOf('D'));
            deletionMonth = deletionQuery.substr(deletionQuery.indexOf('D') + 1, deletionQuery.indexOf('M'));
            deletionYear = deletionQuery.substr(deletionQuery.indexOf('M') + 1, deletionQuery.indexOf('Y'));
            deletionHour = deletionQuery.substr(deletionQuery.indexOf('Y') + 1, deletionQuery.indexOf('h'));
            deletionMinute = deletionQuery.substr(deletionQuery.indexOf('h') + 1, deletionQuery.indexOf('m'));
            deletionDate = moment(deletionDay + "-" + deletionMonth + "-" + deletionYear + " " + deletionHour + ":" + deletionMinute, "DD-MM-YYYY HH:mm");
        } else {
            deletionDate = moment.invalid();
        }
        if (deletionDate.isValid()) {  // TODO: return codes (http://momentjs.com/docs/#/parsing/is-valid/)
            if (deletionDate.isAfter(moment().add(maxFileExpiration, 'days'))) {
                warningWrapper("Too big deletion date received: " + deletionDate.toString() + " - setting to maximum value.");
                deletionDate = moment().add(maxFileExpiration, 'days');
            } else {
                if (debug) {
                    infoWrapper("Valid deletion date received: " + deletionDate.toString());
                } else {
                    infoWrapper("Valid deletion date received.");
                }
                dateOk = true;
                next();
            }
        } else {
            if (debug) {
                warningWrapper("Invalid deletion date received: " + deletionDate.toString());
            } else {
                warningWrapper("Invalid deletion date received!");
            }
            res.status(400).send("BAD DELETION DATE\n");
        }
    } else {
        next();
    }
}

var storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadPath);
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + '-' + file.originalname.replace(/[^0-9A-Za-z\.]+/g, "_").replace(/\.\.+/g, "_"));
  }
})

var upload = multer({ storage: storage,
    limits: {
        fields: 0, // No extra POST fields
        fileSize: maxFileSize
    }
}).single('file');

var postUpload = function(req, res) {
    var responseText;
    if (dateOk) {
        var j = schedule.scheduleJob(deletionDate.toDate(), function(path){
            fs.unlinkSync(path);
        }.bind(null, req.file.path));
        if (debug) {
            infoWrapper("Deletion job scheduled for: " + deletionDate.toString());
        } else {
            infoWrapper("Deletion job scheduled.");
        }
    }
    var md5query = req.query.md5;
    var md5uploaded;
    if (md5query) {
        if (md5query.indexOf(' ') !== -1) {
            md5query = md5query.substr(0, md5query.indexOf(' '));  // allows piping from md5sum
        }
        md5uploaded = md5File(req.file.path).toString();
        if (md5uploaded === md5query) {
            infoWrapper("File '" + req.file.originalname + "' uploaded to '" + req.file.path + "', MD5 OK");
            responseText = "OK - GOOD CHECKSUM";
        } else {
            if (debug) {
                infoWrapper("File '" + req.file.originalname + "' uploaded to '" + req.file.path + "', MD5 BAD (" + md5uploaded + " vs " + md5query + ")");
            } else {
                infoWrapper("File '" + req.file.originalname + "' uploaded to '" + req.file.path + "', MD5 BAD");
            }
            responseText = "OK - BAD CHECKSUM";
        }
    } else {
        responseText = "OK - NO CHECKSUM";
    }
    if (dateOk) {
        responseText = responseText + " - GOOD DELETION DATE";
    }
    res.end(responseText + " - " + domainUrl + path.basename(req.file.path) + "\n");
}

app.post('/api/upload', authUpload, validateUpload, upload, postUpload);

app.get('/uploads/*', function(req, res) {
    res.sendFile(__dirname + req.url);
});

app.listen(9980, function() {
    infoWrapper("Starting Dumpster on port 9980");
    if (debug) {
        warningWrapper("Debug mode is enabled!");
    }
});

