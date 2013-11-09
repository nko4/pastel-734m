#= require vendor/peer

window.S = {}

class S.Socket
  constructor: (conn) ->
    @conn = conn
    @callbacks = {}
    console.log 'new socket', conn
    @conn.on 'data', (data) =>
      @callbacks[data.key](data.data)

  emit: (key, data) ->
    @conn.send key: key, data: data
  send: (data) ->
    @emit 'message', data
  on: (key, callback) ->
    console.log 'register', key
    @callbacks[key] = callback

S.pair = (room, cb) ->
  id = Math.ceil(Math.random() * 1000000).toString()
  peer = new Peer id, host: location.hostname, port: 8001, debug: 2

  $.getJSON "/pair/#{room}/#{id}", (data) ->
    console.log 'paired', data
    if data.master
      S.conn = peer.connect data.id, reliable: true, serialization: 'json'
      peer.on 'connection', (conn) -> console.log 'wth'
      cb new S.Socket(S.conn), data.master if cb
    else
      peer.on 'connection', (conn) ->
        S.conn = conn
        cb new S.Socket(S.conn), data.master if cb
