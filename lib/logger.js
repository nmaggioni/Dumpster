var winston = require('winston');

exports.info = function (message) {
    var timestamp = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
    winston.log('info', "[" + timestamp + "] %s", message);
}

exports.warning = function (message) {
    var timestamp = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
    winston.log('warn', "[" + timestamp + "] %s", message);
}

exports.error = function (message) {
    var timestamp = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
    winston.log('error', "[" + timestamp + "] %s", message);
}
