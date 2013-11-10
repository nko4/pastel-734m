#= require vendor/jsnes.min
#= require vendor/peer

window.S = angular.module 'sweetnes', []

userAgentString = navigator.userAgent

S.browser =
  if userAgentString.indexOf("Firefox")> 0
    "firefox"
  else if userAgentString.indexOf("Chrome/30") > 0
    "chrome"
  else if userAgentString.indexOf("Chrome/31") > 0
    "chrome_beta"
  else
    "unknown"

class Game
  constructor: (@name) ->
    format = if S.browser is 'firefox' then ".ogg" else ".mp4"

    @url = "#{@urlSafeName()}-#{S.browser}"
    @video = "/videos/#{@urlSafeName()}#{format}"
    @rom = "/roms/#{@urlSafeName()}.nes"

  urlSafeName: ->
    @name.replace(/\./g, '').replace(/\s/g, '_').toLowerCase()

class JSNESUI
  constructor: (nes) ->
    @nes = nes
    @canvas = document.getElementById 'emulator'
    @canvasContext = @canvas.getContext '2d'
    @canvasContext.fillStyle = 'black'
    @canvasContext.fillRect(0, 0, 256, 240)
    @canvasImageData = @canvasContext.getImageData 0, 0, 256, 240

  writeFrame: (buffer, prevBuffer) ->
    imageData = @canvasImageData.data

    for i in [0..256*240]
      pixel = buffer[i]

      if pixel != prevBuffer[i]
        j = i*4
        imageData[j] = pixel & 0xFF
        imageData[j+1] = (pixel >> 8) & 0xFF
        imageData[j+2] = (pixel >> 16) & 0xFF
        prevBuffer[i] = pixel

    @canvasContext.putImageData @canvasImageData, 0, 0

  writeAudio: ->

  enable: ->

  updateStatus: (message) ->
    # console.log 'nes:', message

S.IndexController = ($scope, $http) ->
  $scope.S = S
  $scope.status = 'select'
  $scope.games = (new Game(name) for name in ["Bubble Bobble", "Tetris 2", "Super Mario Bros. 3", "Contra"])
  $scope.currentIndex = Math.floor(Math.random($scope.games.length) * 10 % $scope.games.length)

  pair = (room, cb) ->
    id = Math.ceil(Math.random() * 1000000).toString()
    $scope.peer = new Peer id, host: location.hostname, port: 8001

    $scope.pairRequest = $.getJSON "/pair/#{room}/#{id}", (data) ->
      if data.master
        S.conn = $scope.peer.connect data.id, reliable: true, serialization: 'json'
        S.conn.on 'open', ->
          cb new Socket(S.conn), data.master if cb
      else
        $scope.peer.on 'connection', (conn) ->
          S.conn = conn
          cb new Socket(S.conn), data.master if cb

  roomName = () ->
    $scope.currentGame.urlSafeName()

  filterNESKeypresses = (e, fn) ->
    switch e.keyCode
      when 88, 89, 90, 17, 13, 38, 40, 37, 39, 103, 105, 99, 97, 104, 98, 100, 102
        fn.bind($scope.nes.keyboard)(e)

  $scope.$watch 'currentIndex', ->
    $scope.currentGame = $scope.games[$scope.currentIndex]

  $scope.privateRoom = false

  $scope.$watch 'status', (status) ->
    mousetrap.reset()
    $(document).unbind()
    switch status
      when 'select'
        mousetrap.bind 'enter', -> $scope.$apply 'play()'
        mousetrap.bind 'left',  -> $scope.$apply 'left()'
        mousetrap.bind 'right', -> $scope.$apply 'right()'
        mousetrap.bind 'up',    -> $scope.$apply 'up()'
        mousetrap.bind 'down',  -> $scope.$apply 'down()'
      when 'waiting'
        mousetrap.bind 'esc',   -> $scope.$apply 'cancel()'
      when 'playing'
        S.talk(roomName())
        keyboard = $scope.nes.keyboard
        $(document)
          .bind('keyup',    (e) -> filterNESKeypresses(e, keyboard.keyUp))
          .bind('keydown',  (e) -> filterNESKeypresses(e, keyboard.keyDown))
          .bind('keypress', (e) -> filterNESKeypresses(e, keyboard.keyPress))

  $scope.left = ->
    $scope.direction = 'left'
    $scope.currentIndex = ($scope.currentIndex-1+$scope.games.length) % $scope.games.length
    setTimeout (-> $scope.$apply('direction=null')), 500

  $scope.right = ->
    $scope.direction = 'right'
    $scope.currentIndex = ($scope.currentIndex+1) % $scope.games.length
    setTimeout (-> $scope.$apply('direction=null')), 500

  $scope.cancel = ->
    $scope.status = 'select'
    $scope.peer.destroy()
    $scope.pairRequest.abort()

  $scope.up = ->
    $scope.privateRoom = false

  $scope.down = ->
    $scope.privateRoom = true

  $scope.play = (room) ->
    $scope.status = 'waiting'

    $scope.nes = nes = new JSNES swfPath: '/audio/', ui: JSNESUI

    getRoom = (cb) ->
      if room
        cb room
      else if $scope.privateRoom
        $http.get('/word').success cb
      else
        cb $scope.currentGame.url

    getRoom (room) ->
      $scope.share = "#{location.protocol}//#{location.host}/play/#{room}"
      pair room, (socket, master) ->
        if master
          m = new S.MasterNes(nes, socket)
          m.loadRom $scope.currentGame.rom, ->
            m.romInitialized()
            m.selectedRom = $scope.currentGame.rom
            m.partner "Rom:Changed", m.selectedRom
            m.onRomLoaded m.selectedRom
        else
          new S.SlaveNes(nes, socket)

        $scope.$apply 'status = "playing"'

  if room = location.pathname.match(/^\/play\/([^/]+)/)?[1]
    $scope.privateRoom = true
    $scope.play room

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

S.talk = (room, cb) ->
  if typeof(AudioContext) == "undefined"
    return

  id = Math.ceil(Math.random() * 1000000).toString()
  peer = new Peer id, host: location.hostname, port: 8001

  $.getJSON "/pair/#{room}/#{id}", (data) ->
    getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia
    getUserMedia = getUserMedia.bind(navigator)

    if data.master
     getUserMedia {video: false, audio: true}, (stream) ->
        S.mic = new Speaker(stream)

        micIcon = document.getElementById "mic"
        events.bind micIcon, "click", () ->
          classes(micIcon).toggle("mute")
          S.mic.mute()

        S.mic.onNoise (volume) ->
          mic = document.getElementById("mic")
          mic.style.opacity = 0.1 + (volume / 100 * 3)

        call = peer.call data.id, stream
        call.on 'stream', (stream) ->
          S.speaker = new Speaker(stream)

          speakerIcon = document.getElementById "speaker"
          events.bind speakerIcon, "click", () ->
            classes(speakerIcon).toggle("mute")
            S.speaker.mute()

          S.speaker.onNoise (volume) ->
            speaker = document.getElementById("speaker")
            speaker.style.opacity = 0.1 + (volume / 100 * 3)

      , (err) ->
        console.log 'Failed to get local stream', err
    else
      peer.on 'call', (call) ->
        getUserMedia {video: false, audio: true}, (stream) ->
          S.mic = new Speaker(stream)

          micIcon = document.getElementById "mic"
          events.bind micIcon, "click", () ->
            classes(micIcon).toggle("mute")
            S.mic.mute()

          S.mic.onNoise (volume) ->
            mic = document.getElementById("mic")
            mic.style.opacity = 0.1 + (volume / 100 * 3)

          call.answer stream
          call.on 'stream', (stream) ->
            S.speaker = new Speaker(stream)

            speakerIcon = document.getElementById "speaker"
            events.bind speakerIcon, "click", () ->
              classes(speakerIcon).toggle("mute")
              S.speaker.mute()

            S.speaker.onNoise (volume) ->
              speaker = document.getElementById("speaker")
              speaker.style.opacity = 0.1 + (volume / 100 * 3)
        , (err) ->
          console.log 'Failed to get local stream', err
