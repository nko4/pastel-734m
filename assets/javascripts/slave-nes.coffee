#= require 'base-nes'

class window.SlaveNes extends window.BaseNes
  constructor: (nes, socket) ->
    console.log("Starting slave")
    @nes = nes
    @socket = socket
    @current_instruction = 0
    @startRom = false
    @selectedRom = null
    @socket.on "connection", (evt) =>
      @socket.send JSON.stringify(ok: 1)

    console.log "listening to Rom:Changed message"
    @socket.on "Rom:Changed", (rom_location) =>
      console.log "Rom changed to " + rom_location
      @selectedRom = rom_location
      @nes.ppu.reset()
      @loadRom rom_location
      @partner "PPU:Sync"

    @socket.on "PPU:Initialize", (data) =>
      data = JSON.parse(@compressor.decompress(data))
      @nes.ppu.vramMem = data["vramMem"]
      @nes.ppu.spriteMem = data["spriteMem"]
      @nes.ppu.vramAddress = data["vramAddress"]
      @nes.ppu.vramTmpAddress = data["vramTmpAddress"]
      @nes.ppu.vramBufferedReadValue = data["vramBufferedReadValue"]
      @nes.ppu.firstWrite = data["firstWrite"]
      @nes.ppu.sramAddress = data["sramAddress"]
      @nes.ppu.mapperIrqCounter = data["mapperIrqCounter"]
      @nes.ppu.currentMirroring = data["currentMirroring"]
      @nes.ppu.requestEndFrame = data["requestEndFrame"]
      @nes.ppu.nmiOk = data["nmiOk"]
      @nes.ppu.dummyCycleToggle = data["dummyCycleToggle"]
      @nes.ppu.validTileData = data["validTileData"]
      @nes.ppu.nmiCounter = data["nmiCounter"]
      @nes.ppu.scanlineAlreadyRendered = data["scanlineAlreadyRendered"]
      @nes.ppu.f_nmiOnVblank = data["f_nmiOnVblank"]
      @nes.ppu.f_spriteSize = data["f_spriteSize"]
      @nes.ppu.f_bgPatternTable = data["f_bgPatternTable"]
      @nes.ppu.f_spPatternTable = data["f_spPatternTable"]
      @nes.ppu.f_addrInc = data["f_addrInc"]
      @nes.ppu.f_nTblAddress = data["f_nTblAddress"]
      @nes.ppu.f_color = data["f_color"]
      @nes.ppu.f_spVisibility = data["f_spVisibility"]
      @nes.ppu.f_bgVisibility = data["f_bgVisibility"]
      @nes.ppu.f_spClipping = data["f_spClipping"]
      @nes.ppu.f_bgClipping = data["f_bgClipping"]
      @nes.ppu.f_dispType = data["f_dispType"]
      @nes.ppu.cntFV = data["cntFV"]
      @nes.ppu.cntV = data["cntV"]
      @nes.ppu.cntH = data["cntH"]
      @nes.ppu.cntVT = data["cntVT"]
      @nes.ppu.cntHT = data["cntHT"]
      @nes.ppu.regFV = data["regFV"]
      @nes.ppu.regV = data["regV"]
      @nes.ppu.regH = data["regH"]
      @nes.ppu.regVT = data["regVT"]
      @nes.ppu.regHT = data["regHT"]
      @nes.ppu.regFH = data["regFH"]
      @nes.ppu.regS = data["regS"]
      @nes.ppu.curNt = data["curNt"]
      @nes.ppu.attrib = data["attrib"]
      @nes.ppu.buffer = data["buffer"]
      @nes.ppu.bgbuffer = data["bgbuffer"]
      @nes.ppu.pixrendered = data["pixrendered"]
      @nes.ppu.spr0dummybuffer = data["spr0dummybuffer"]
      @nes.ppu.dummyPixPriTable = data["dummyPixPriTable"]
      @nes.ppu.validTileData = data["validTileData"]
      @nes.ppu.scantile = data["scantile"]
      @nes.ppu.scanline = data["scanline"]
      @nes.ppu.lastRenderedScanline = data["lastRenderedScanline"]
      @nes.ppu.curX = data["curX"]
      @nes.ppu.sprX = data["sprX"]
      @nes.ppu.sprY = data["sprY"]
      @nes.ppu.sprTile = data["sprTile"]
      @nes.ppu.sprCol = data["sprCol"]
      @nes.ppu.vertFlip = data["vertFlip"]
      @nes.ppu.horiFlip = data["horiFlip"]
      @nes.ppu.bgPriority = data["bgPriority"]
      @nes.ppu.spr0HitX = data["spr0HitX"]
      @nes.ppu.spr0HitY = data["spr0HitY"]
      @nes.ppu.hitSpr0 = data["hitSpr0"]
      @nes.ppu.sprPalette = data["sprPalette"]
      @nes.ppu.imgPalette = data["imgPalette"]
      for i of data["ptTile"]
        $.extend @nes.ppu.ptTile[i], data["ptTile"][i]
      @nes.ppu.ntable1 = data["ntable1"]
      @nes.ppu.currentMirroring = data["currentMirroring"]
      for i of data["nameTable"]
        $.extend @nes.ppu.nameTable[i], data["nameTable"][i]
      @nes.ppu.vramMirrorTable = data["vramMirrorTable"]
      @nes.ppu.updateControlReg1 data["controlReg1Value"]
      @nes.ppu.updateControlReg2 data["controlReg2Value"]
      @nes.ppu.startVBlank()
      @current_instruction = data["instruction"]
      console.log "Waiting for instruction " + @current_instruction

    @socket.on "MMAP:Initialize", (data) =>
      #TODO: Respec mapperType
      @nes.mmap.regBuffer = data["regBuffer"]
      @nes.mmap.regBufferCounter = data["regBufferCounter"]
      @nes.mmap.mirroring = data["mirroring"]
      @nes.mmap.oneScreenMirroring = data["oneScreenMirroring"]
      @nes.mmap.prgSwitchingArea = data["prgSwitchingArea"]
      @nes.mmap.prgSwitchingSize = data["prgSwitchingSize"]
      @nes.mmap.vromSwitchingSize = data["vromSwitchingSize"]
      @nes.mmap.romSelectionReg0 = data["romSelectionReg0"]
      @nes.mmap.romSelectionReg1 = data["romSelectionReg1"]
      @nes.mmap.romBankSelect = data["romBankSelect"]
      @partner "state:partner_ready"
      @onRomLoaded @selectedRom

    @socket.on "PPU:Frame", (data) =>
      if @current_instruction is data["instruction"]
        @nes.ppu.startFrame()
        @renderFrame data["frame_instructions"]
        @nes.ppu.startVBlank()
      @current_instruction += 1


    # TODO: we should only preventDefault for non-controller keys. 
    document.addEventListener "keydown", ((evt) =>
      @sendKey evt.keyCode, 0x41
    ), true
    document.addEventListener "keyup", ((evt) =>
      @sendKey evt.keyCode, 0x40
    ), true


  #
  #    bind('keypress', function(evt) {
  #        evt.preventDefault()
  #    });
  #
  sendKey: (key, value) ->
    switch key
      when 88
        @socket.send JSON.stringify(
          key: 103
          value: value
        )
      when 90
        @socket.send JSON.stringify(
          key: 105
          value: value
        )
      when 17
        @socket.send JSON.stringify(
          key: 99
          value: value
        )
      when 13
        @socket.send JSON.stringify(
          key: 97
          value: value
        )
      when 38
        @socket.send JSON.stringify(
          key: 104
          value: value
        )
      when 40
        @socket.send JSON.stringify(
          key: 98
          value: value
        )
      when 37
        @socket.send JSON.stringify(
          key: 100
          value: value
        )
      when 39
        @socket.send JSON.stringify(
          key: 102
          value: value
        )
      else
        return true
    false # preventDefault

  renderFrame: (instructions) ->
    for i of instructions
      instruction = instructions[i][0]
      args = instructions[i].slice(1, instruction.length)
      #      @apply(FUNCTION_MAPPINGS[instruction[0]], instruction.slice(1, instruction.length)
      switch instruction
        when @INSTRUCTIONS.sramDMA
          @sramDMA.apply @, args
        when @INSTRUCTIONS.scrollWrite
          @scrollWrite.apply @, args
        when @INSTRUCTIONS.writeSRAMAddress
          @writeSRAMAddress.apply @, args
        when @INSTRUCTIONS.endScanLine
          j = 0

          while j < args[0]
            @endScanline.apply @
            j++
        when @INSTRUCTIONS.loadVromBank
          @loadVromBank.apply @, args
        when @INSTRUCTIONS.load1kVromBank
          @load1kVromBank.apply @, args
        when @INSTRUCTIONS.load2kVromBank
          @load2kVromBank.apply @, args
        when @INSTRUCTIONS.mmapWrite
          @mmapWrite.apply @, args
        when @INSTRUCTIONS.updateControlReg1
          @updateControlReg1.apply @, args
        when @INSTRUCTIONS.updateControlReg2
          @updateControlReg2.apply @, args
        when @INSTRUCTIONS.setSprite0HitFlag
          @setSprite0HitFlag.apply @, args
        when @INSTRUCTIONS.sramWrite
          @sramWrite.apply @, args
        when @INSTRUCTIONS.writeVRAMAddress
          @writeVRAMAddress.apply @, args
        when @INSTRUCTIONS.vramWrite
          @vramWrite.apply @, args
        when @INSTRUCTIONS.readStatusRegister
          @readStatusRegister.apply @, args

  scrollWrite: (value) ->
    @nes.ppu.scrollWrite value

  writeSRAMAddress: (value) ->
    @nes.ppu.writeSRAMAddress value

  endScanline: ->
    @nes.ppu.endScanline()

  loadVromBank: (bank, address) ->
    @nes.mmap.loadVromBank bank, address

  load1kVromBank: (bank, address) ->
    @nes.mmap.load1kVromBank bank, address

  load2kVromBank: (bank, address) ->
    @nes.mmap.load2kVromBank bank, address

  mmapWrite: (address, value) ->
    @nes.mmap.write address, value


  # CPU Register $4014:
  # Write 256 bytes of main memory
  # into Sprite RAM.
  sramDMA: (value, datum) ->
    data = undefined
    console.log "sramDMA" if @nes.ppu.debug
    i = @nes.ppu.sramAddress

    while i < 256
      data = datum[i]
      @nes.ppu.spriteMem[i] = data
      @nes.ppu.spriteRamWriteUpdate i, data
      i++

  setSprite0HitFlag: ->
    @nes.ppu.setSprite0HitFlag()

  sramWrite: (value) ->
    @nes.ppu.sramWrite value

  updateControlReg1: (value) ->
    @nes.ppu.updateControlReg1 value

  updateControlReg2: (value) ->
    @nes.ppu.updateControlReg2 value

  vramWrite: (value) ->
    @nes.ppu.vramWrite value

  writeVRAMAddress: (value) ->
    @nes.ppu.writeVRAMAddress value

  readStatusRegister: ->
    @nes.ppu.readStatusRegister()
