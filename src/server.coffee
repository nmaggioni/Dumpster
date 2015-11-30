multer = require('multer')
bodyParser = require('body-parser')
express = require('express')
app = express()
logger = require('./lib/logger.js')
validator = require('./lib/validator.js')
configParser = require('./lib/configParser')

if !configParser.parsed
    if !configParser.parse()
        process.exit 1
uploadPath = configParser.uploadPath
maxFileSize = configParser.maxFileSize
debug = configParser.debug

app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: true)

storage = multer.diskStorage(
    destination: (req, file, cb) ->
        cb null, uploadPath
    filename: (req, file, cb) ->
        cb null, Date.now() + '-' + file.originalname.replace(new RegExp('[^0-9A-Za-z\\.]+', 'g'), '_').replace(new RegExp('\\.\\.+', 'g'), '_')
)

upload = multer(
    storage: storage
    limits:
        fields: 0
        fileSize: maxFileSize).single('file')

app.all '/*', (req, res, next) ->
    res.header 'X-Powered-By', 'Dumpster'
    next()

app.post '/api/upload', validator.auth, validator.date, ((req, res, next) ->
    upload req, res, (err) ->
        if err
            res.status(400).send 'UPLOAD FAILED - FILE TOO BIG?\n'
        else
            next()
), validator.md5, validator.scheduleDeletion, validator.sendLink

app.get '/uploads/*', (req, res) ->
    res.sendFile __dirname + req.url

app.listen 9980, ->
    logger.info 'Starting Dumpster on port 9980'
    if debug
        logger.warning 'Debug mode is enabled!'
    validator.checkUploadsDirectory()
