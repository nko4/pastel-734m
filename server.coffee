require('nko')('WP4Tfg3Wdz0fNnzA')
fs = require 'fs'
PeerServer = require('peer').PeerServer

peerServer = new PeerServer({ port: 8001 })

express = require 'express'
app = express()

process.chdir __dirname

app.configure ->
  app.set 'port', if app.get('env') is 'production' then 80 else 8000

  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'

  app.use express.logger('dev')

  app.use express.compress()

  app.use require('connect-assets')
    helperContext: app.locals
    minifyBuilds: no  # minification freaks out angular
  app.locals.js.root = 'javascripts'
  app.locals.css.root = 'stylesheets'

  app.use express.static __dirname + '/public'

  app.use (req, res, next) -> res.locals.req = req; next()
  app.use app.router

# Configuration (development)
# ---------------------------
app.configure 'development', ->
  app.use express.errorHandler()

# State
# -----
games = {}
waiting = {}
words = ['yay']

fs.readFile '/usr/share/dict/words', (err, data) ->
  return console.log(err) if err
  words = data.toString().split("\n")

# Routes
# ------
app.get '/', (req, res) ->
  if app.get('env') is 'production' and req.host.toLowerCase() isnt 'sweetn.es'
    res.redirect 'http://sweetn.es'
  else
    res.render 'index'

app.get '/test', (req, res) ->
  res.render 'test'

app.get /^\/angular/, (req, res) ->
  res.render 'angular', layout: false

app.get '/play/:game', (req, res) ->
  game = req.param 'game'
  if room = games[game] and waiting[room]
    console.log "paired #{room} for #{game}"
    delete games[game]
  else
    room = games[game] =
      words[Math.floor(Math.random() * words.length)].toLowerCase()
    console.log "creating #{room} for #{game}"

  res.format
    'application/json': -> res.json game: game, room: room
    'text/html':        -> res.redirect "/play/#{game}/#{room}"

app.get '/play/:game/:room', (req, res) ->
  res.render 'index', game: req.param('game'), room: req.param('room')

app.get '/pair/:room/:id', (req, res) ->
  id = req.param('id')
  room = req.param('room')

  if waiting[room]
    partner = waiting[room]

    res.json id: partner.id, master: false
    partner.res.json id: id, master: true

    delete waiting[room]
  else
    waiting[room] = { id: id, res: res }
    res.on 'close', ->
      console.log "removing #{room}"
      delete waiting[room]

# View Helpers
# ------------
app.locals._ = require 'underscore'

# Listen
http = require 'http'
http.createServer(app).listen app.get('port'), (err) ->
  if err
    console.error(err)
    process.exit(-1)

  require('util').log "Listening on http://0.0.0.0:#{app.get('port')}/"

  # if run as root, downgrade to the owner of this file
  if process.getuid() == 0
    fs.stat __filename, (err, stats) ->
      return console.error(err) if err
      process.setuid stats.uid
