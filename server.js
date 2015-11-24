var winston = require('winston');
var multer = require('multer');
var bodyParser = require('body-parser');
var express = require("express");
var app = express();
var path = require('path');
var fs = require('fs');
var yubikey = require('./lib/yubikey.js');

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
var apiConfigIsArray = false;

if (Object.prototype.toString.call(config.apiId) === '[object Array]') {
    if (Object.prototype.toString.call(config.apiKey) === '[object Array]') {
        if (config.apiId.length !== config.apiKey.length) {
            errorWrapper('Configuration mismatch: not the same number of API IDs and Keys.');
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

var uploadPath = config.uploadFolder;
var domainUrl = config.domainName + uploadPath;
var debug = config.debug || false;

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

var uploadedFileURL = null;
var upload = multer({
    dest: uploadPath,
    rename: function(fieldname, filename) {
        return filename + Date.now();
    },
    limits: {
        fields: 0, // No extra POST fields
        fieldSize: config.maxFileSize,
        fileSize: config.maxFileSize
    },
    onFileUploadStart: function(file) {
        infoWrapper("Accepting upload: " + file.originalname + " (" + file.size + " bytes, " + file.mimetype + ")");
        uploadedFileURL = null;
    },
    onFileUploadComplete: function(file) {
        infoWrapper("File '" + file.originalname + "' uploaded to " + file.path);
        uploadedFileURL = domainUrl + path.basename(file.path);
    }
}).single('file');

var postUpload = function(req, res) {
    res.end("OK - " + uploadedFileURL + "\n");
}

app.post('/api/upload', authUpload, upload, postUpload);

app.get('/uploads/*', function(req, res) {
    res.sendFile(__dirname + req.url);
});

app.listen(9980, function() {
    infoWrapper("Starting Dumpster on port 9980");
    if (debug) {
        warningWrapper("Debug mode is enabled!");
    }
});

