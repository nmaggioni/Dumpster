# Dumpster
A self-hosted and API-based file upload server supporting YubiKey OTP authentication. Written in *NodeJS*.

## Installation
+ Clone the repo.
+ Navigate to the cloned directory and issue `npm install`.
+ Edit the configuration file (see the **Configuration** section).
+ Enjoy *Dumpster* with `node server.js`!
  + Protip: schedule a cron job to delete uploaded files every fixed time lapse, and voilà! You've got your personal temporary file upload server.

## Configuration
Edit the `config.js` file in the `lib` directory according to the following table.

| Key | Type | Example | Description |
| --- | --- | --- | --- |
| apiId | *Integer*| 123456 | Yubico API ID - get one at: https://upgrade.yubico.com/getapikey/ |
| apiKey | *String* | abcdef | Yubico API Key - get one at: https://upgrade.yubico.com/getapikey/ |
| username | *String* | admin | The desired username needed to upload files |
| domainName | *String* | http://your.domain.name/ | Your TLD or subdomain (path relative to Dumpster's root) |
| uploadFolder | *String* | uploads/ | The folder where the uploaded files will be placed (relative to Dumpster's root) |
| maxFileSize | *Integer* | 52428800 | The maximum upload dimension in bytes (remember to adjust your web server accordingly!) |

## Usage
*Dumpster* is really easy to use, and mainly meant to be called from CLI. Here's a cURL usage example:

`curl --progress-bar -F "file=@/path/to/file" "http://dumpster.your.domain/api/upload?user=admin&token=yubikeyotp" | tee /dev/null`

+ The trailing `tee /dev/null` is needed to show the progress bar. You may as well replace it with `grep -v '^$'` or equivalent;

*Dumpster*'s answer will either be `AUTH ERROR` or `OK` - pretty self-explanatory, huh? - if the upload succeeded you'll receive the link to download the file in the body of the reply.

### Credits
Many thanks to [Adam Baldwin (evilpacket)][1], who wrote [an awesome library][2] to verify a YubiKey's OTP. It's quite old, but I've found it to be performing better than newer libraries.
[1]: https://github.com/evilpacket
[2]: https://github.com/evilpacket/node-yubikey
