class window.Socket
  constructor: (conn) ->
    @conn = conn
    @callbacks = {}
    @conn.on 'data', (data) =>
      @callbacks[data['key']](data['data'])

  emit: (key, data) ->
    conn.send(key: key, data: data)

  on: (key, callback) ->
    @callbacks[key] = callback

  send: (data) ->
    @emit('message', data)

