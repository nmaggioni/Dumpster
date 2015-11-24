# Dumpster [![Codacy Badge](https://api.codacy.com/project/badge/grade/29b49730fea944feb66f85f73f4c858f)](https://www.codacy.com/app/nmaggioni/Dumpster) [![Dependency Status](https://david-dm.org/nmaggioni/dumpster.svg)](https://david-dm.org/nmaggioni/dumpster)
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
| apiId | *Integer array*| [123456, 654321] | Yubico API IDs - get one at: https://upgrade.yubico.com/getapikey/ |
| apiKey | *String array* | [abcdef, fedcba] | Yubico API Keys - get one at: https://upgrade.yubico.com/getapikey/ |
| uploadFolder | *String* | uploads/ | The folder where the uploaded files will be placed (relative to Dumpster's root) |
| maxFileSize | *Integer* | 52428800 | The maximum upload dimension in bytes (remember to adjust your web server accordingly!) |

## Usage
*Dumpster* is really easy to use, and mainly meant to be called from CLI. Here's a cURL usage example:

`curl --progress-bar -F "file=@/path/to/my_file.pdf" "http://localhost:9980/api/upload?token=YUBIKEYOTP" | tee /dev/null`

+ The trailing `tee /dev/null` is needed to show the progress bar. You may as well replace it with `grep -v '^$'` or equivalent;

Here's another example, this time using [HTTPie][3]:
`http -f POST "http://localhost:9980/api/upload?token=YUBIKEYOTP" file@~/path/to/my_file.pdf`

*Dumpster*'s answer will either be `AUTH ERROR` or `OK` - pretty self-explanatory, huh? - if the upload succeeded you'll receive the link to download the file in the body of the reply.

### Credits
The included YubiKey library is a modified version of [the one][1] in [Adam Baldwin (evilpacket)'s'][2] repo. It's quite old, but I've found it to better suit my needs than newer or more complex libraries.

[1]: https://github.com/evilpacket/node-yubikey
[2]: https://github.com/evilpacket
[3]: https://github.com/jkbrzt/httpie
