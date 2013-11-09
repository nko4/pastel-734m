# https://github.com/nko4/website/blob/master/module/README.md#nodejs-knockout-deploy-check-ins
#require('nko')('WP4Tfg3Wdz0fNnzA')
fs = require 'fs'

express = require 'express'
app = express()

isProduction = process.env.NODE_ENV == 'production'
http = require('http')
port = if isProduction then 80 else 8000

app.set 'view engine', 'jade'

app.get '/', (req, res) ->
  res.render 'index'

app.get '/jsnes.js', (req, res) ->
  fs.readFile './jsnes.min.js', 'utf8', (err,data) ->
    res.send data

app.listen port, (err) ->
  if err
    console.error(err)
    process.exit(-1)

  # if run as root, downgrade to the owner of this file
  if process.getuid() == 0
    require('fs').stat __filename, (err, stats) ->
      return console.error(err) if err
      process.setuid stats.uid

console.log "Server running at http://0.0.0.0:#{port}/"
