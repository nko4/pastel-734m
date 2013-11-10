#= require vendor/peer

window.S = angular.module 'sweetnes', []

class Game
  constructor: (name) ->
    @name = name
    @rom = name # lowercase, replace space with underscore, append .rom
    @url = @videoSrc()

  urlSafeName: ->
    @name.replace(/\./g, '').replace(/\s/g, '_').toLowerCase()

  videoSrc: ->
    UA = navigator.userAgent
    isFirefox = UA.indexOf("Firefox") > -1
    format = if window.isFirefox then ".ogg" else ".mp4"
    "/videos/#{@urlSafeName()}#{format}"

S.IndexController = ($scope) ->
  $scope.games = (new Game(name) for name in ["Bubble Bobble", "Dr. Mario", "Super Mario Bros. 3", "Contra"])
  $scope.currentIndex = 1

  $scope.$watch 'currentIndex', ->
    $scope.currentGame = $scope.games[$scope.currentIndex]

  $scope.left = ->
    $scope.direction = 'left'
    $scope.currentIndex = ($scope.currentIndex-1+$scope.games.length) % $scope.games.length
    setTimeout (-> $scope.$apply('direction=null')), 500

  $scope.right = ->
    $scope.direction = 'right'
    $scope.currentIndex = ($scope.currentIndex+1) % $scope.games.length
    setTimeout (-> $scope.$apply('direction=null')), 500

  $scope.play = ->
    $scope.currentGame.active = true
    # window.location = "/play/#{$scope.currentGame.urlSafeName()}"

  mousetrap.bind "enter", -> $scope.$apply('play()')
  mousetrap.bind "left", -> $scope.$apply('left()')
  mousetrap.bind "right", -> $scope.$apply('right()')

class Socket
  constructor: (conn) ->
    @conn = conn
    @callbacks = {}
    @conn.on 'data', (data) =>
      @callbacks[data.key]?(data.data)

  emit: (key, data) ->
    @conn.send key: key, data: data
  send: (data) ->
    @emit 'message', data
  on: (key, callback) ->
    @callbacks[key] = callback

S.pair = (room, cb) ->
  id = Math.ceil(Math.random() * 1000000).toString()
  peer = new Peer id, host: location.hostname, port: 8001

  $.getJSON "/pair/#{room}/#{id}", (data) ->
    if data.master
      S.conn = peer.connect data.id, reliable: true, serialization: 'json'
      S.conn.on 'open', ->
        cb new Socket(S.conn), data.master if cb
    else
      peer.on 'connection', (conn) ->
        S.conn = conn
        cb new Socket(S.conn), data.master if cb
