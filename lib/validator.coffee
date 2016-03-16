yubikey = require './yubikey.js'
logger = require './logger'
configParser = require './configParser'
schedule = require 'node-schedule'
md5File = require 'md5-file'
path = require 'path'
fs = require 'fs'
database = require './database'
moment = require 'moment'
moment().format()

if !configParser.parsed
  if !configParser.parse()
    process.exit 1

uploadPath = configParser.uploadPath
maxFileExpiration = configParser.maxFileExpiration
maxFileExpirationEnabled = configParser.maxFileExpirationEnabled
domainUrl = configParser.domainUrl
debug = configParser.debug
skipAuth = configParser.skipAuth

exports.auth = (req, res, next) ->
  if debug or skipAuth
    logger.warning 'Bypassing token validation.'
    next()
    return
  token = req.query.token
  yubikey.verify token, (isValid, status) ->
    if isValid
      logger.info 'Valid token received.'
      next()
    else
      logger.warning 'Invalid token received! Reason: ' + status
      res.status(401).send 'AUTH ERROR - ' + status + '\n'

dateOk = undefined
deletionDate = undefined

exports.date = (req, res, next) ->
  dateOk = false
  deletionQuery = req.query.del
  deletionDate = undefined
  deletionDay = undefined
  deletionMonth = undefined
  deletionYear = undefined
  deletionHour = undefined
  deletionMinute = undefined

  if deletionQuery
    if new RegExp('^[0-9]+s$').test(deletionQuery)
      deletionDate = moment().add(deletionQuery.substr(0, deletionQuery.indexOf('s')), 'seconds')
    else if new RegExp('^[0-9]+m$').test(deletionQuery)
      deletionDate = moment().add(deletionQuery.substr(0, deletionQuery.indexOf('m')), 'minutes')
    else if new RegExp('^[0-9]+h$').test(deletionQuery)
      deletionDate = moment().add(deletionQuery.substr(0, deletionQuery.indexOf('h')), 'hours')
    else if new RegExp('^[0-9]+d$').test(deletionQuery)
      deletionDate = moment().add(deletionQuery.substr(0, deletionQuery.indexOf('d')), 'days')
    else if new RegExp('^[0-9]{2}D[0-9]{2}M[0-9]{4}Y$').test(deletionQuery)
      deletionDay = deletionQuery.substr(0, deletionQuery.indexOf('D'))
      deletionMonth = deletionQuery.substr(deletionQuery.indexOf('D') + 1, deletionQuery.indexOf('M'))
      deletionYear = deletionQuery.substr(deletionQuery.indexOf('M') + 1, deletionQuery.indexOf('Y'))
      deletionDate = moment(deletionDay + '-' + deletionMonth + '-' + deletionYear, 'DD-MM-YYYY')
    else if new RegExp('^[0-9]{2}D[0-9]{2}M[0-9]{4}Y[0-9]{2}h[0-9]{2}m$').test(deletionQuery)
      deletionDay = deletionQuery.substr(0, deletionQuery.indexOf('D'))
      deletionMonth = deletionQuery.substr(deletionQuery.indexOf('D') + 1, deletionQuery.indexOf('M'))
      deletionYear = deletionQuery.substr(deletionQuery.indexOf('M') + 1, deletionQuery.indexOf('Y'))
      deletionHour = deletionQuery.substr(deletionQuery.indexOf('Y') + 1, deletionQuery.indexOf('h'))
      deletionMinute = deletionQuery.substr(deletionQuery.indexOf('h') + 1, deletionQuery.indexOf('m'))
      deletionDate = moment(deletionDay + '-' + deletionMonth + '-' + deletionYear +
        ' ' + deletionHour + ':' + deletionMinute, 'DD-MM-YYYY HH:mm')
    else
      deletionDate = moment.invalid()

    if deletionDate.isValid()
      # TODO: return codes (http://momentjs.com/docs/#/parsing/is-valid/)
      if deletionDate.isAfter(moment().add(maxFileExpiration, 'days'))
        if debug
          logger.warning 'Too big deletion date received: ' + deletionDate.toString() + ' - setting to maximum value.'
        else
          logger.warning 'Too big deletion date received, setting to maximum value.'
        deletionDate = moment().add(maxFileExpiration, 'days')
        res.header 'Dumpster-Deletion-Date', 'MAX'
      else
        if debug
          logger.info 'Valid deletion date received: ' + deletionDate.toString()
        else
          logger.info 'Valid deletion date received.'
        res.header 'Dumpster-Deletion-Date', 'OK'
      dateOk = true
      next()
    else
      if debug
        logger.warning 'Invalid deletion date received: ' + deletionDate.toString()
      else
        logger.warning 'Invalid deletion date received!'
      res.status(400).send 'BAD DELETION DATE\n'
  else
    if maxFileExpirationEnabled
      logger.info 'No deletion date received, setting to maximum.'
      deletionDate = moment().add(maxFileExpiration, 'days')
      res.header 'Dumpster-Deletion-Date', 'MAX'
      dateOk = true
    else
      res.header 'Dumpster-Deletion-Date', 'NONE'
    next()

exports.scheduleDeletion = (req, res, next) ->
  if dateOk
    database.put req.file.path, deletionDate

    schedule.scheduleJob deletionDate.toDate(), ((file) ->
      fs.unlinkSync file.path
      logger.info 'Deleted file: ' + file.filename
      database.del file.path
    ).bind(null, req.file)
    if debug
      logger.info 'Deletion job scheduled for: ' + deletionDate.toString()
    else
      logger.info 'Deletion job scheduled.'
  next()

exports.md5 = (req, res, next) ->
  md5query = req.query.md5
  md5uploaded = undefined
  if md5query
    if md5query.indexOf(' ') != -1
      md5query = md5query.substr(0, md5query.indexOf(' '))
      # allows piping from md5sum
    md5uploaded = md5File(req.file.path).toString()
    if md5uploaded == md5query
      logger.info 'File \'' + req.file.originalname + '\' uploaded to \'' + req.file.path + '\', MD5 OK'
      res.header 'Dumpster-Checksum', 'OK'
    else
      if debug
        logger.info 'File \'' + req.file.originalname + '\' uploaded to \'' + req.file.path + '\', MD5 BAD (' +
          md5uploaded + ' vs ' + md5query + ')'
      else
        logger.info 'File \'' + req.file.originalname + '\' uploaded to \'' + req.file.path + '\', MD5 BAD'
      res.header 'Dumpster-Checksum', 'BAD'
  else
    res.header 'Dumpster-Checksum', 'NONE'
  next()

exports.sendLink = (req, res) ->
  res.status 200
  if req.query.json?
    res.json downloadUrl: domainUrl + path.basename(req.file.path)
    res.end()
  else
    res.end domainUrl + path.basename(req.file.path) + '\n'

# coffeelint: disable=unused_variables
missingUploadsDirectory = ->
  logger.warning 'Missing uploads directory, now creating it...'
  try
    fs.mkdirSync uploadPath
    logger.info 'Uploads directory created successfully.'
  catch
    logger.error 'There was an error during directory creation.'
    process.exit 1
  return

exports.checkUploadsDirectory = ->
  try
    if !fs.lstatSync(uploadPath).isDirectory() and !fs.lstatSync(uploadPath).isSymbolicLink()
      missingUploadsDirectory()
  catch error
    missingUploadsDirectory(error)
