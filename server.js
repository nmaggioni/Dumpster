var winston = require('winston');
var multer = require('multer');
var bodyParser = require('body-parser');
var express = require("express");
var app = express();
var path = require('path');
var fs = require('fs');
var yubikey = require('./lib/yubikey.js');

function logWrapper(message) {
    var timestamp = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
    winston.log('info', "[" + timestamp + "] %s", message);
}

/* --- Configuration parsing --- */

var config = JSON.parse(fs.readFileSync('lib/config.js'));
var apiConfigIsArray = false;

if (Object.prototype.toString.call(config.apiId) === '[object Array]') {
    if (Object.prototype.toString.call(config.apiKey) === '[object Array]') {
        if (config.apiId.length !== config.apiKey.length) {
            logWrapper('Configuration mismatch: not the same number of API IDs and Keys.');
            process.exit(1);
        }
    } else {
        logWrapper('Configuration mismatch: API Keys field is not an array.');
        process.exit(1);
    }
} else {
    logWrapper('Configuration mismatch: API IDs field is not an array.');
    process.exit(1);
}
yubikey.apiId = config.apiId;
yubikey.apiKey = config.apiKey;

var uploadPath = config.uploadFolder;
var domainUrl = config.domainName + uploadPath;

/* --- End configuration parsing --- */

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({
    extended: true
}));

var authUpload = function(req, res, next) {
    var token = req.query.token;
    yubikey.verify(token, function(isValid, status) {
        if (isValid) {
            logWrapper("Valid token: " + token);
            next();
        } else {
            logWrapper("Invalid token: " + token + " (Reason: " + status + ")");
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
        logWrapper("Accepting upload: " + file.originalname + " (" + file.size + " bytes, " + file.mimetype + ")");
        uploadedFileURL = null;
    },
    onFileUploadComplete: function(file) {
        logWrapper("File '" + file.originalname + "' uploaded to " + file.path);
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
    logWrapper("Starting Dumpster on port 9980");
});

