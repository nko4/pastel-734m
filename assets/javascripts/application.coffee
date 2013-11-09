#= require vendor/jsnes.min
#= require vendor/dynamicaudio.min
#= require vendor/peer

peer1 = new Peer { key:'lwjd5qra8257b9' }
peer2 = new Peer { key:'lwjd5qra8257b9' }

peer1.on 'open', (id) ->
  console.log 'Peer 1 ' + id

peer2.on 'open', (id) ->
  console.log 'Peer 2 ' + id

peer1.on 'connection', (conn) ->
  conn.on 'data', (data) ->
    console.log(data)
  console.log 'Peer1 connect'

# onn = peer1.connect peer2.id

# conn.on 'open', ->
#   conn.on 'data', (data) ->
#     console.log 'Received', data

#   conn.send 'Hello'

window.peer1 = peer1
window.peer2 = peer2
