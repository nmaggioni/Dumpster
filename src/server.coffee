fs = require 'fs'
multer = require 'multer'
bodyParser = require 'body-parser'
express = require 'express'
app = express()
router = express.Router()
logger = require './lib/logger'
validator = require './lib/validator'
configParser = require './lib/configParser'
database = require './lib/database'

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
    cb null, Date.now() + '-' +
      file.originalname.replace(new RegExp('[^0-9A-Za-z\\.]+', 'g'), '_').replace(new RegExp('\\.\\.+', 'g'), '_')
)

upload = multer(
  storage: storage
  limits:
    fields: 0
    fileSize: maxFileSize).single('file')

router.post '/api/upload', validator.auth, validator.date, ((req, res, next) ->
  upload req, res, (err) ->
    if err
      res.writeHead 400, 'X-Powered-By': 'Dumpster'
      res.send 'Upload failed, file too big?\n'
    else
      next()
), validator.md5, validator.scheduleDeletion, validator.sendLink

router.get '/uploads/*', (req, res) ->
  try
    fs.accessSync __dirname + req.url, fs.F_OK
    res.writeHead 200,
      'X-Powered-By': 'Dumpster'
      'Content-Type': 'application/force-download',
      'Access-Control-Allow-Origin': '*',
      'Content-Disposition': 'attachment;'
    res.sendFile __dirname + req.url
  catch error
    logger.error error
    res.writeHead 404, 'X-Powered-By': 'Dumpster'
    res.end 'Nothing here.'

router.all '/*', (req, res) ->
  res.writeHead 404, 'X-Powered-By': 'Dumpster'
  res.end 'Nothing here.'

app.use '/', router

app.listen 9980, ->
  logger.info 'Starting Dumpster on port 9980'
  if debug
    logger.warning 'Debug mode is enabled!'
  validator.checkUploadsDirectory()
  database.loadScheduledDates()
