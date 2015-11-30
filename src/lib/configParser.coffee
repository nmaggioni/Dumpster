logger = require('./logger.js')
yubikey = require('./yubikey.js')
fs = require('fs')
parsed = exports.parsed = false

exports.parse = ->
    config = JSON.parse(fs.readFileSync('lib/config.json'))

    if Object::toString.call(config.apiId) == '[object Array]'
        if Object::toString.call(config.apiKey) == '[object Array]'
            if config.apiId.length != config.apiKey.length
                if config.apiId.length == 0 or config.apiKey.length == 0
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

    yubikey.apiId = config.apiId
    yubikey.apiKey = config.apiKey
    uploadPath = exports.uploadPath = config.uploadFolder or 'uploads/'
    exports.domainUrl = (config.domainName or 'http://localhost:9980/') + uploadPath
    exports.maxFileSize = config.maxFileSize or 52428800
    exports.maxFileExpiration = config.maxFileExpiration or 30
    exports.maxFileExpirationEnabled = config.maxFileExpirationEnabled

    if exports.maxFileExpirationEnabled == undefined
        exports.maxFileExpirationEnabled = true
    exports.debug = config.debug
    if exports.debug == undefined
        exports.debug = false

    parsed = true
    parsed
