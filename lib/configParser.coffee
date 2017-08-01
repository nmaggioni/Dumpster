logger = require('./logger')
yubikey = require('./yubikey.js')
fs = require('fs')
parsed = exports.parsed = false

exports.parse = ->
  config = JSON.parse(fs.readFileSync __dirname + '/../config/config.json')

  if config.skipAuth != true
    if Object::toString.call(config.yubicoApiId) == '[object Array]'
      if Object::toString.call(config.yubicoApiKey) == '[object Array]'
        if config.yubicoApiId.length != config.yubicoApiKey.length
          if config.yubicoApiId.length == 0 or config.yubicoApiKey.length == 0
            logger.error 'Configuration missing: have you edited the defaults in "lib/config.json"?'
          else
            logger.error 'Configuration mismatch: not the same number of API IDs and Keys.'
          return false
      else
        logger.error 'Configuration mismatch: API Keys field is not an array.'
        return false
    else
      logger.error 'Configuration mismatch: API IDs field is not an array.'
      return false

  if config.skipAuth != true
    yubikey.apiId = config.yubicoApiId
    yubikey.apiKey = config.yubicoApiKey
  uploadPath = exports.uploadPath = config.uploadFolder or 'uploads/'
  exports.enableWebUI = config.enableWebUI
  exports.domainUrl = (config.baseUrl or 'http://localhost:9980/') + uploadPath
  exports.maxFileSize = config.maxFileSize or 52428800
  exports.maxFileExpiration = config.maxFileExpiration or 30
  exports.port = config.port or 9980
  exports.maxFileExpirationEnabled = config.maxFileExpirationEnabled
  exports.debug = config.debug
  exports.skipAuth = config.skipAuth

  if exports.maxFileExpirationEnabled == undefined
    exports.maxFileExpirationEnabled = true
  if exports.debug == undefined
    exports.debug = false
  if exports.skipAuth == undefined
    exports.skipAuth = false
  if exports.enableWebUI == undefined
    exports.enableWebUI = true

  parsed = true
  parsed
