var winston = require('winston');
var multer = require('multer');
var bodyParser = require('body-parser');
var express = require("express");
var app = express();
var path = require('path');
var yubikey = require('./lib/yubikey.js'); // https://github.com/evilpacket/node-yubikey
yubikey.apiId = 0; // <-- Fill in
yubikey.apiKey = ''; // <-- Fill in

var uploadPath = 'uploads/';
var domainUrl = 'http://your.domain.name/' + uploadPath; // <-- Fill in

function logWrapper(message) {
	var timestamp = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
	winston.log('info', "[" + timestamp + "] %s", message);
}

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

var authUpload = function (req, res, next) {
  var user = req.query.user;
  var token = req.query.token;
  if (user == "yourUser") { // <-- Fill in
    yubikey.verify(token, function(isValid) {
      if (isValid) {
        logWrapper("Valid token: " + token);
        next();
      } else {
        logWrapper("Invalid token: " + token);
        res.status(401).send("AUTH ERROR - Invalid token\n");
      }
    });
  } else {
        logWrapper("Invalid user: " + user);
        res.status(401).send("AUTH ERROR - Invalid user\n");
  }
}

var uploadedFileURL = null;
var upload = multer({
  dest: uploadPath,
  rename: function(fieldname, filename) {
    return filename + Date.now();
  },
  limits: {
    files: 1, // Max 1 file per upload
    fields: 0, // No extra POST fields
    fieldSize: 52428800, // 50MB
    fileSize: 52428800 // 50MB
  },
  onFileUploadStart: function(file) {
	  logWrapper("Accepting upload: " + file.originalname + " (" + file.size + " bytes, "+ file.mimetype + ")");
	  uploadedFileURL = null;
  },
  onFileUploadComplete: function(file) {
    logWrapper("File '" + file.originalname + "' uploaded to " + file.path);
    uploadedFileURL = domainUrl + path.basename(file.path);
  }
});

var postUpload = function (req, res, next) {
    res.end("OK - " + uploadedFileURL + "\n");
}

app.post('/api/upload', [authUpload, upload, postUpload]);

app.get('/uploads/*', function(req, res) {
  res.sendFile(__dirname + req.url);
});

app.listen(9980, function() {
  logWrapper("Starting Dumpster on port 9980");
});
