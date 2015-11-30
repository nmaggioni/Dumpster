{exec} = require 'child_process'
async = require './src/tools/cake-async.coffee'

# Install Node.JS dependencies using NPM
async task 'installDependencies', (o, done) ->
  console.log "Installing dependencies..."
  exec 'npm install', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
    done()

# Compile the main script
async task 'compileMain', (o, done) ->
  console.log "Compiling the main script..."
  exec 'coffee --compile --output ./ src/server.coffee', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
    done()

# Compile the libraries
async task 'compileLibs', (o, done) ->
  console.log "Compiling the libraries..."
  exec 'coffee --compile --output ./lib/ src/lib/*.coffee', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
    done()

task 'build', 'Build project from ./src/*.coffee to ./*.js', ->
  invoke async 'installDependencies'
  invoke async 'compileMain'
  invoke async 'compileLibs'
  async.end => console.log "All done! Run Dumpster with: 'node ./server.js'"
