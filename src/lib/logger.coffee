winston = require('winston')

exports.info = (message) ->
  timestamp = (new Date).toISOString().replace(/T/, ' ').replace(new RegExp('\\..+'), '')
  winston.log 'info', '[' + timestamp + '] %s', message
  return

exports.warning = (message) ->
  timestamp = (new Date).toISOString().replace(/T/, ' ').replace(new RegExp('\\..+'), '')
  winston.log 'warn', '[' + timestamp + '] %s', message
  return

exports.error = (message) ->
  timestamp = (new Date).toISOString().replace(/T/, ' ').replace(new RegExp('\\..+'), '')
  winston.log 'error', '[' + timestamp + '] %s', message
  return
