# Dumpster [![Codacy Badge](https://api.codacy.com/project/badge/grade/29b49730fea944feb66f85f73f4c858f)](https://www.codacy.com/app/nmaggioni/Dumpster) [![Dependency Status](https://david-dm.org/nmaggioni/dumpster.svg)](https://david-dm.org/nmaggioni/dumpster)
A lightweight, self-hosted and API-based file upload server supporting YubiKey OTP authentication. Written in *NodeJS*.

## Installation
+ Clone the repo.
+ Navigate to the cloned directory and issue `npm install`.
+ Edit the configuration file (see the [Configuration](#configuration) section).
+ Enjoy *Dumpster* with `npm start`!

## Configuration
Edit the `config.js` file in the `lib` directory according to the following table.

| Key | Type | Example / Default | Description |
| --- | --- | --- | --- |
| apiId | *Integer* array| [123456, 654321] | Yubico API IDs - get one at: https://upgrade.yubico.com/getapikey/ |
| apiKey | *String* array | ["abcdef", "fedcba"] | Yubico API Keys - get one at: https://upgrade.yubico.com/getapikey/ |
| uploadFolder | *String* | "uploads/" | The folder where the uploaded files will be placed (relative to Dumpster's root) |
| maxFileSize | *Integer* | 52428800 | The maximum upload dimension in bytes (remember to [adjust your web server accordingly][4]!) |
| maxFileExpiration | *Integer* | 30 | The maximum time after which the files will be deleted from the server. **If *Dumpster* is stopped, currently uploaded files will not be deleted.** |
| debug | *Boolean* | false | Enables debug mode (YubiKey OTPs will **not** be verified!) |

## Usage
*Dumpster* is really easy to use, and mainly meant to be called from CLI. Refer to the following table for API parameters:

| Parameter name | Required | Description |
| --- | --- | --- |
| **Base URL** | - | *Dumpster*'s root plus `/api/upload`. For example: `http://localhost:9980/api/upload` |
| token | yes | Your YubiKey's OTP. |
| md5 | no | MD5 checksum of the file that you're uploading; if given, *Dumpster* will check its copy of the file against it. Direct pipe from `md5sum` is supported. |
| del | no | Time to file deletion; if given, the uploaded file will be deleted at the specified time/date. The allowed formats are (where `?` is a number): `??s` for seconds from now, `??m` for minutes from now, `??h` for hours from now, `??d` for days from now, `??D??M????Y` for a specified date (at midnight), and `??D??M????Y??h??m` for specified date and time. If the specified time exceeds the maximum setting, the maximum value will be used. |

> The order of the parameters is irrelevant. Placing the token as the last one may however be advisable: that way the YubiKey itself will send the command by issuing the newline.

Here's a cURL usage example:
```bash
curl --progress-bar -F "file=@/path/to/my_file.pdf" "http://localhost:9980/api/upload?token=YUBIKEYOTP" | tee /dev/null
```

> The trailing `tee /dev/null` is needed to show the progress bar. You may as well replace it with `grep -v '^$'` or any other output redirection.

Here's another example, this time using [HTTPie][3] and giving the MD5 sum of the file as well as an expiration date of 3 days:
```bash
http -f POST "http://localhost:9980/api/upload?md5=CHECKSUM&del=3d&token=YUBIKEYOTP" file@~/path/to/my_file.pdf
```

*Dumpster*'s answer will either be `AUTH ERROR` or `OK` - pretty self-explanatory, huh? - if the upload succeeded you'll receive the link to download the file in the body of the reply, if something went wrong the reason will be printed next to the error code. If you gave the file's MD5, `GOOD CHECKSUM` or `BAD CHECKSUM` will appear next to the status code.

### Credits
The included YubiKey library is a modified version of [the one][1] in [Adam Baldwin (evilpacket)'s][2] repo.

[1]: https://github.com/evilpacket/node-yubikey
[2]: https://github.com/evilpacket
[3]: https://github.com/jkbrzt/httpie
[4]: http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size
