#= require vendor/jsnes.min
#= require vendor/dynamicaudio.min
#= require vendor/peer
#= require master-nes
#= require slave-nes

window.pair = (room) ->
  peer = new Peer { key:'lwjd5qra8257b9' }

  peer.on 'open', (id) ->
    console.log 'Peer ID: ' + id
    $.getJSON "/pair/#{room}/#{id}", (data) ->
      console.log("Got: " + data)
      console.log("Partner data: " + data['id'])
      window.conn = peer.connect data['id']

  peer.on 'connection', (conn) ->
    conn.on 'data', (data) ->
      console.log(data)
      console.log("Got data, boyee!")

  peer.on 'connection', (conn) ->
    console.log 'Peer connect'

  window.peer = peer
