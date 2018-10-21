winston = require('winston')
logger = winston.createLogger({
  format: winston.format.simple()
  transports: [
    new winston.transports.Console()
  ]
});

exports.info = (message) ->
  timestamp = (new Date).toISOString().replace(/T/, ' ').replace(new RegExp('\\..+'), '')
  logger.log 'info', '[' + timestamp + '] ' + message
  return

exports.warning = (message) ->
  timestamp = (new Date).toISOString().replace(/T/, ' ').replace(new RegExp('\\..+'), '')
  logger.log 'warn', '[' + timestamp + '] ' + message
  return

exports.error = (message) ->
  timestamp = (new Date).toISOString().replace(/T/, ' ').replace(new RegExp('\\..+'), '')
  logger.log 'error', '[' + timestamp + '] ' + message
  return
