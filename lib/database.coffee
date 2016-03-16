logger = require './logger'
configParser = require './configParser'
schedule = require 'node-schedule'
path = require 'path'
fs = require 'fs'
levelup = require 'level'
db = levelup './database'

if !configParser.parsed
  if !configParser.parse()
    process.exit 1

debug = configParser.debug

logError = (err) ->
  console.log 'LevelDB error: ' + err
  return err

exports.put = (key, value) ->
  db.put key, value, (err) ->
    if err
      return logError err

exports.get = (key) ->
  db.get key, (err, value) ->
    if err
      logError err

    returnObj =
      err: err
      value: value
    return returnObj

exports.del = del = (key) ->
  db.del key, (err) ->
    if err
      return logError err

importScheduledDates = (data) ->
  filesPaths = data.keys
  deletionDates = data.values

  filesPaths.forEach (filePath, i) ->
    now = new Date()
    deletionDate = deletionDates[i]
    deletionDateCompare = new Date(deletionDate)

    if now > deletionDateCompare
      if debug
        logger.warning 'Deletion job for file "' + path.basename(filePath) + '" is outdated, deleting it now.'
      fs.unlinkSync filePath
      del filePath
    else
      schedule.scheduleJob deletionDate, ((filePath) ->
        fs.unlinkSync filePath
        logger.info 'Deleted file: ' + path.basename(filePath)
        del filePath
      ).bind(null, filePath)
      if debug
        logger.info 'Deletion job scheduled for file "' + path.basename(filePath) + '": ' + deletionDate.toString()

  logger.info 'Done loading deletion dates from database.'

keys = []
values = []

exports.loadScheduledDates = ->
  if debug
    logger.info 'Loading deletion dates from database...'

  returnData = ->
    returnObj =
      keys: keys
      values: values
    importScheduledDates returnObj

  db.createReadStream()
    .on 'data', (data) ->
      keys.push data.key
      values.push data.value

    .on 'error', (err) ->
      logError err

    .on 'end', ->
      returnData()
