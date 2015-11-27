var multer = require('multer'),
    bodyParser = require('body-parser'),
    express = require("express"),
    app = express(),
    logger = require('./lib/logger.js'),
    validator = require('./lib/validator.js'),
    configParser = require('./lib/configParser');

if (!configParser.parsed) {
    if (!configParser.parse()) {
        process.exit(1);
    }
}
var uploadPath = configParser.uploadPath,
    maxFileSize = configParser.maxFileSize,
    debug = configParser.debug;

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({
    extended: true
}));

var storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, uploadPath);
    },
    filename: function (req, file, cb) {
        cb(null, Date.now() + '-' + file.originalname.replace(/[^0-9A-Za-z\.]+/g, "_").replace(/\.\.+/g, "_"));
    }
});

var upload = multer({
    storage: storage,
    limits: {
        fields: 0, // No extra POST fields
        fileSize: maxFileSize
    }
}).single('file');

app.all('/*', function (req, res, next) {
    res.header('X-Powered-By', 'Dumpster');
    next();
});

app.post('/api/upload', validator.auth, validator.date, function (req, res, next) {
    upload(req, res, function (err) {
        if (err) {
            res.status(400).send("UPLOAD FAILED - FILE TOO BIG?\n");
        } else {
            next();
        }
    });
}, validator.md5);

app.get('/uploads/*', function (req, res) {
    res.sendFile(__dirname + req.url);
});

app.listen(9980, function () {
    logger.info("Starting Dumpster on port 9980");
    if (debug) {
        logger.warning("Debug mode is enabled!");
    }
});

