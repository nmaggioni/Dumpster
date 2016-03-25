<p align="center">
  <img src="https://nmaggioni.github.io/dumpster/dumpster_logo_small.png" alt="Dumpster"/>
</p>

[![Codacy Badge](https://api.codacy.com/project/badge/grade/29b49730fea944feb66f85f73f4c858f)](https://www.codacy.com/app/nmaggioni/Dumpster) [![Dependency Status](https://david-dm.org/nmaggioni/dumpster.svg)](https://david-dm.org/nmaggioni/dumpster) [![stable](http://badges.github.io/stability-badges/dist/stable.svg)](http://github.com/badges/stability-badges)
> A lightweight, self-hosted and API-based file upload server supporting YubiKey OTP authentication.<br> Written in [*NodeJS*][5] and [*CoffeeScript*][6], persistence layer implemented with [LevelDB][7] and page rendering done with [Jade][8].

# Table of contents
+ [Installation](#installation)
  - [Docker image](#docker-image)
+ [Configuration](#configuration)
+ [Usage](#usage)
  - [CLI](#cli)
  - [WebUI](#webui)
+ [Notes & Credits](#note-on-persistence)

## Installation
+ Clone the repo.
+ Navigate to the cloned directory and issue:
  - `npm install`
  - `npm run-script bower`
+ Edit the configuration file (see the [Configuration](#configuration) section).
+ Enjoy *Dumpster* with `npm start`!

### Docker image
If you prefer running Dumpster in a container, a [Dockerfile](Dockerfile) is available to build an image.
An automated build can also be found [in the Docker Hub][9]: you can pull it with `docker pull nmaggioni/dumpster`.

## Configuration
Edit the `config.json` file in the `config` directory to configure Dumpster. Be sure to check [the related Wiki page][3] for a thoroughly explanation of all the options!

## Usage
### CLI
*Dumpster* is easy to use, and mainly meant to be called from CLI or API. Refer to [the related Wiki page][4] for API parameters and their explanation.

### WebUI
If enabled in the [configuration](#configuration) with the `enableWebUI` option, a simple graphical web interface will be available on the root path. It will follow the `skipAuth` setting, requesting an OTP token only if needed. A drag-and-drop upload widget is available, and uploads are performed via AJAX requests.

![WebUI demo](https://nmaggioni.github.io/dumpster/dumpster.png)

###### A live demo is also [available on GitHub pages][10].

## Note on persistence
Since version *v3.0.0*, *Dumpster* will register and manage deletion dates in a local [LevelDB][7] instance (to be found in the `database` folder created upon starting the server). That way, if you stop the server and restart it at a later time, it will purge files with older deletion date than the current one and re-schedule future deletions.

## Credits
The included YubiKey library is a modified version of [the one][1] in [Adam Baldwin (evilpacket)'s][2] repo.

[1]: https://github.com/evilpacket/node-yubikey
[2]: https://github.com/evilpacket
[3]: https://github.com/nmaggioni/Dumpster/wiki/Configuration
[4]: https://github.com/nmaggioni/Dumpster/wiki/API-or-CLI-usage
[5]: https://nodejs.org/en/
[6]: http://coffeescript.org/
[7]: http://leveldb.org/
[8]: http://jade-lang.com/
[9]: https://hub.docker.com/r/nmaggioni/dumpster/
[10]: https://nmaggioni.github.io/dumpster/
