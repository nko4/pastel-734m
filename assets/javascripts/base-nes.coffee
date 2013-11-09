#= require 'sweetnes'
#= require 'lzma'
#= require vendor/jsnes.min
#= require vendor/dynamicaudio.min

class S.BaseNes
  INSTRUCTIONS:
    sramDMA: 0
    scrollWrite: 1
    writeSRAMAddress: 2
    sramDMA: 3
    scrollWrite: 4
    writeSRAMAddress: 5
    endScanLine: 6
    loadVromBank: 7
    load1kVromBank: 8
    load2kVromBank: 9
    mmapWrite: 10
    updateControlReg1: 11
    updateControlReg2: 12
    setSprite0HitFlag: 13
    sramWrite: 14
    writeVRAMAddress: 15
    vramWrite: 16
    readStatusRegister: 17

  compressor: LZMA
  partner: (command, data) ->
    @socket.emit command, data


  loadRom: (url, callback) ->
    self = this
    $.ajax
      url: escape(url)
      xhr: ->
        xhr = $.ajaxSettings.xhr()

        # Download as binary
        xhr.overrideMimeType "text/plain; charset=x-user-defined"
        xhr

      success: (data) ->
        self.loadRomData data
        callback()  if callback


  loadRomData: (data) ->
    @nes.loadRom data
    @nes.start()  if @startRom
    @nes.ui.enable()

  onRomLoaded: ->
