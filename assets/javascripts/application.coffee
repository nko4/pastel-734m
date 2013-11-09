#= require vendor/jsnes.min
#= require vendor/dynamicaudio.min
#= require vendor/peer
#= require master-nes
#= require slave-nes
#= require socket

window.pair = (room) ->
  id = Math.ceil(Math.random() * 1000000).toString()
  peer = new Peer(id, { host: location.hostname, port: 8001})

  peer.on 'open', (id) ->
    console.log 'Peer ID: ' + id
    $.getJSON "/pair/#{room}/#{id}", (data) ->
      console.log("Got: " + data)
      console.log("Partner data: " + data['id'])
      window.conn = peer.connect data['id'], reliable: true, serialization: 'json'
      window.master = data['master']

  peer.on 'connection', (conn) ->
    console.log 'Peer connect'

  window.peer = peer
