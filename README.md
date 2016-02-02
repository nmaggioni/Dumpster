# Dumpster [![Codacy Badge](https://api.codacy.com/project/badge/grade/29b49730fea944feb66f85f73f4c858f)](https://www.codacy.com/app/nmaggioni/Dumpster) [![Dependency Status](https://david-dm.org/nmaggioni/dumpster.svg)](https://david-dm.org/nmaggioni/dumpster) [![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/nmaggioni/dumpster/trend.png)](https://bitdeli.com/free "Bitdeli Badge") [![stable](http://badges.github.io/stability-badges/dist/stable.svg)](http://github.com/badges/stability-badges)
A lightweight, self-hosted and API-based file upload server supporting YubiKey OTP authentication. Written in [*NodeJS*][5] and [*CoffeeScript*][6]. Persistence layer implemented with [LevelDB][10].

## Installation
+ Ensure that [CoffeeScript is installed][7].
+ Clone the repo or download the compiled release.
+ Navigate to the cloned/decompressed directory and issue `cake build` if you cloned the repo, `npm install` if you downloaded the compiled archive.
+ Edit the configuration file (see the [Configuration](#configuration) section).
+ Enjoy *Dumpster* with `npm start` or `node ./server.js`!

## Configuration
Edit the `config.json` file in the `lib` directory according to the following table.

| Key | Type | Example / Default | Description |
| --- | --- | --- | --- |
| apiId | *Integer* array| [123456, 654321] | Yubico API IDs - get one at: https://upgrade.yubico.com/getapikey/ |
| apiKey | *String* array | ["abcdef", "fedcba"] | Yubico API Keys - get one at: https://upgrade.yubico.com/getapikey/ |
| uploadFolder | *String* | "uploads/" | The folder where the uploaded files will be placed (relative to Dumpster's root) |
| maxFileSize | *Integer* | 52428800 | The maximum upload dimension in **bytes** (remember to [adjust your web server accordingly][4]!) |
| maxFileExpiration | *Integer* | 30 | The maximum time in **days** after which the files will be deleted from the server. |
| maxFileExpirationEnabled | *Boolean* | true | Toggles if files will be forced to be deleted from the server after `maxFileExpiration` time or not. If disabled, files will remain stored until you (or another program) manually remove them from the uploads directory. |
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

*Dumpster*'s answer will span across headers and body: if the upload succeeded you'll receive the link to download the file in the body of the reply, if something went wrong the reason will be printed in it instead. The headers description follows:

###### Dumpster-Checksum

| Value | Meaning |
| --- | --- |
| `OK` | The checksum has been verified correctly. |
| `BAD` | The checksum verification failed; the uploaded file is probably corrupted. |
| `NONE` | No checksum has been given. |

###### Dumpster-Deletion-Date

| Value | Meaning |
| --- | --- |
| `OK` | The given deletion date for the file was valid and has been accepted. |
| `MAX` | The given deletion date for the file was too large; it has been cut down to the [maximum allowed value](#configuration). |
| `NONE` | No file deletion date has been given. The [default one](#configuration) has been applied. |

### Note on persistence
Since version *v3.0.0*, *Dumpster* will register and manage deletion dates in a local [LevelDB][10] instance (to be found in the `database` folder created upon starting the server). That way, if you stop the server and restart it at a later time, it will purge files with older deletion date than the current one and re-schedule future deletions.

### Credits
The included YubiKey library is a modified version of [the one][1] in [Adam Baldwin (evilpacket)'s][2] repo.

Thanks to [Ricardo Tomasi][8] for the [cake-async][9] library used in the build script.

[1]: https://github.com/evilpacket/node-yubikey
[2]: https://github.com/evilpacket
[3]: https://github.com/jkbrzt/httpie
[4]: http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size
[5]: https://nodejs.org/en/
[6]: http://coffeescript.org/
[7]: http://coffeescript.org/#installation
[8]: https://github.com/ricardobeat
[9]: https://github.com/ricardobeat/cake-async
[10]: http://leveldb.org/
