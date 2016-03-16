fs = require 'fs'
multer = require 'multer'
bodyParser = require 'body-parser'
express = require 'express'
cors = require 'cors'
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
    fileSize: maxFileSize).single('file')

router.all '/*', (req, res, next) ->
  res.setHeader 'X-Powered-By', 'Dumpster'
  next()

router.post '/api/upload', validator.auth, validator.date, ((req, res, next) ->
  upload req, res, (err) ->
    if err
      logger.error err
      res.status 400
      res.send 'Upload failed, file too big?\n'
    else
      next()
), validator.md5, validator.scheduleDeletion, validator.sendLink

router.get '/uploads/*', (req, res) ->
  try
    if fs.statSync(__dirname + req.url).isFile()
      res.status 200
      res.setHeader('Content-Type', 'application/force-download')
      res.setHeader('Content-Disposition', 'attachment')
      res.sendFile __dirname + req.url
    else
      res.status 404
      res.end 'Nothing here.\n'
  catch error
    logger.error error
    res.status 404
    res.end 'Nothing here.\n'

router.all '/*', (req, res) ->
  res.status 404
  res.end 'Nothing here.\n'

app.use cors()
app.use '/', router

app.listen 9980, ->
  logger.info 'Starting Dumpster on port 9980'
  if debug
    logger.warning 'Debug mode is enabled!'
  validator.checkUploadsDirectory()
  database.loadScheduledDates()
