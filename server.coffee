require('nko')('WP4Tfg3Wdz0fNnzA')
fs = require 'fs'

express = require 'express'
app = express()

app.configure ->
  app.set 'port', if process.env.NODE_ENV is 'production' then 80 else 8000

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
conns = {}
words = ['yay']

fs.readFile '/usr/share/dict/words', (err, data) ->
  return console.log(err) if err
  words = data.toString().split("\n")

# Routes
# ------
app.get '/', (req, res) ->
  res.render 'index'

app.get '/play-test', (req, res) ->
  res.render 'play_test'

app.get /^\/play\/([^\/]+)(?:\/([^\/]+))?$/, (req, res) ->
  game = req.params[0]
  if room = req.params[1]
    res.render 'play', game: game, room: room
  else
    if games[game]
      room = games[game]
      delete games[game]
    else
      room = games[game] = words[Math.floor(Math.random() * words.length)]
    res.redirect "/play/#{game}/#{room}"

app.get '/pair/:room/:id', (req, res) ->
  id = req.param('id')
  room = req.param('room')

  if waiting[room]
    partnerId = waiting[room]

    res.json(id: partnerId, master: false)

    partnerConn = conns[partnerId]
    partnerConn.json(id: id, master: true)

    delete conns[partnerId]
  else
    waiting[room] = id
    conns[id] = res

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
