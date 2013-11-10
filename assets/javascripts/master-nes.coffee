#= require 'base-nes'

class S.MasterNes extends S.BaseNes
  constructor: (nes, socket) ->
    @socket = socket
    @nes = nes
    @instruction_id = 0
    @frame_instructions = []
    @startRom = true
    @sramBuffer = new Array(256)
    @syncFrame = false
    @debug = false
    @selectedRom = null
    @lastSendTime = null
    # @setupRomListener()

    @socket.on "PPU:Sync", =>
      @nes.stop()
      @syncPPU()

    @socket.on "message", (evt) =>
      data = JSON.parse(evt)
      if data.close
        @setFrameRate 60
        return
      @nes.keyboard.setKey data.key, data.value  if data.key

    @socket.on "state:partner_joined", (partner_id) =>
      if @selectedRom
        @nes.stop()
        @partner "Rom:Changed", @selectedRom

    @socket.on "state:partner_ready", =>
      @syncFrame = true
      @nes.start()

    @ppuEndFrame = @nes.ppu.endFrame
    @nes.ppu.endFrame = =>
      @endFrame()

    @ppuScrollWrite = @nes.ppu.scrollWrite
    @nes.ppu.scrollWrite = (value) =>
      @scrollWrite value

    @ppuWriteSRAMAddress = @nes.ppu.writeSRAMAddress
    @nes.ppu.writeSRAMAddress = (value) =>
      @writeSRAMAddress value

    @ppuSramDMA = @nes.ppu.sramDMA
    @nes.ppu.sramDMA = (value) =>
      @sramDMA value

    @ppuEndScanline = @nes.ppu.endScanline
    @nes.ppu.endScanline = =>
      @endScanline()

    @ppuSetSprite0HitFlag = @nes.ppu.setSprite0HitFlag
    @nes.ppu.setSprite0HitFlag = =>
      @setSprite0HitFlag()

    @ppuSramWrite = @nes.ppu.sramWrite
    @nes.ppu.sramWrite = =>
      @sramWrite()

    @ppuVramWrite = @nes.ppu.vramWrite
    @nes.ppu.vramWrite = (value) =>
      @vramWrite value

    @ppuWriteVRAMAddress = @nes.ppu.writeVRAMAddress
    @nes.ppu.writeVRAMAddress = (value) =>
      @writeVRAMAddress value

    @ppuUpdateControlReg1 = @nes.ppu.updateControlReg1
    @nes.ppu.updateControlReg1 = (value) =>
      @updateControlReg1 value

    @ppuUpdateControlReg2 = @nes.ppu.updateControlReg2
    @nes.ppu.updateControlReg2 = (value) =>
      @updateControlReg2 value

    @ppuReadStatusRegister = @nes.ppu.readStatusRegister
    @nes.ppu.readStatusRegister = =>
      @readStatusRegister()

  romInitialized: ->
    self = this
    self.mmapLoadVromBank = self.nes.mmap.loadVromBank
    self.nes.mmap.loadVromBank = (bank, address) ->
      self.loadVromBank bank, address

    self.mmapLoad1kVromBank = self.nes.mmap.load1kVromBank
    self.nes.mmap.load1kVromBank = (bank, address) ->
      self.load1kVromBank bank, address

    self.mmapLoad2kVromBank = self.nes.mmap.load2kVromBank
    self.nes.mmap.load2kVromBank = (bank, address) ->
      self.load2kVromBank bank, address

    self.mmapWrite = self.nes.mmap.write
    self.nes.mmap.write = (address, value) ->
      self.f_mmapWrite address, value

  syncPPU: ->
    @nes.ppu.ptTile[1].initialized = true
    self = this
    payload =
      instruction: self.instruction_id
      vramMem: @nes.ppu.vramMem
      spriteMem: @nes.ppu.spriteMem
      vramAddress: @nes.ppu.vramAddress
      vramTmpAddress: @nes.ppu.vramTmpAddress
      vramBufferedReadValue: @nes.ppu.vramBufferedReadValue
      firstWrite: @nes.ppu.firstWrite
      sramAddress: @nes.ppu.sramAddress
      mapperIrqCounter: @nes.ppu.mapperIrqCounter
      currentMirroring: @nes.ppu.currentMirroring
      requestEndFrame: @nes.ppu.requestEndFrame
      nmiOk: @nes.ppu.nmiOk
      dummyCycleToggle: @nes.ppu.dummyCycleToggle
      validTileData: @nes.ppu.validTileData
      nmiCounter: @nes.ppu.nmiCounter
      scanlineAlreadyRendered: @nes.ppu.scanlineAlreadyRendered
      f_nmiOnVblank: @nes.ppu.f_nmiOnVblank
      f_spriteSize: @nes.ppu.f_spriteSize
      f_bgPatternTable: @nes.ppu.f_bgPatternTable
      f_spPatternTable: @nes.ppu.f_spPatternTable
      f_addrInc: @nes.ppu.f_addrInc
      f_nTblAddress: @nes.ppu.f_nTblAddress
      f_color: @nes.ppu.f_color
      f_spVisibility: @nes.ppu.f_spVisibility
      f_bgVisibility: @nes.ppu.f_bgVisibility
      f_spClipping: @nes.ppu.f_spClipping
      f_bgClipping: @nes.ppu.f_bgClipping
      f_dispType: @nes.ppu.f_dispType
      cntFV: @nes.ppu.cntFV
      cntV: @nes.ppu.cntV
      cntH: @nes.ppu.cntH
      cntVT: @nes.ppu.cntVT
      cntHT: @nes.ppu.cntHT
      regFV: @nes.ppu.regFV
      regV: @nes.ppu.regV
      regH: @nes.ppu.regH
      regVT: @nes.ppu.regVT
      regHT: @nes.ppu.regHT
      regFH: @nes.ppu.regFH
      regS: @nes.ppu.regS
      curNt: @nes.ppu.curNt
      attrib: @nes.ppu.attrib
      buffer: @nes.ppu.buffer
      bgbuffer: @nes.ppu.bgbuffer
      pixrendered: @nes.ppu.pixrendered
      spr0dummybuffer: @nes.ppu.spr0dummybuffer
      dummyPixPriTable: @nes.ppu.dummyPixPriTable
      validTileData: @nes.ppu.validTileData
      scantile: @nes.ppu.scantile
      scanline: @nes.ppu.scanline
      lastRenderedScanline: @nes.ppu.lastRenderedScanline
      curX: @nes.ppu.curX
      sprX: @nes.ppu.sprX
      sprY: @nes.ppu.sprY
      sprTile: @nes.ppu.sprTile
      sprCol: @nes.ppu.sprCol
      vertFlip: @nes.ppu.vertFlip
      horiFlip: @nes.ppu.horiFlip
      bgPriority: @nes.ppu.bgPriority
      spr0HitX: @nes.ppu.spr0HitX
      spr0HitY: @nes.ppu.spr0HitY
      hitSpr0: @nes.ppu.hitSpr0
      sprPalette: @nes.ppu.sprPalette
      imgPalette: @nes.ppu.imgPalette
      ptTile: @nes.ppu.ptTile
      ntable1: @nes.ppu.ntable1
      currentMirroring: @nes.ppu.currentMirroring
      nameTable: @nes.ppu.nameTable
      vramMirrorTable: @nes.ppu.vramMirrorTable
      palTable: @nes.ppu.palTable
      controlReg1Value: @nes.ppu.controlReg1Value
      controlReg2Value: @nes.ppu.controlReg2Value

    self.partner "PPU:Initialize", self.compressor.compress(JSON.stringify(payload))
    self.partner "MMAP:Initialize",
      mapperType: self.nes.rom.mapperType
      regBuffer: self.nes.mmap.regBuffer
      regBufferCounter: self.nes.mmap.regBufferCounter
      mirroring: self.nes.mmap.mirroring
      oneScreenMirroring: self.nes.mmap.oneScreenMirroring
      prgSwitchingArea: self.nes.mmap.prgSwitchingArea
      prgSwitchingSize: self.nes.mmap.prgSwitchingSize
      vromSwitchingSize: self.nes.mmap.vromSwitchingSize
      romSelectionReg0: self.nes.mmap.romSelectionReg0
      romSelectionReg1: self.nes.mmap.romSelectionReg1
      romBankSelect: self.nes.mmap.romBankSelect


  endFrame: ->
    self = this
    self.ppuEndFrame.call self.nes.ppu
    if self.syncFrame
      @partner "PPU:Frame",
        instruction: self.instruction_id
        frame_instructions: self.frame_instructions

    @socket.onHeartbeat()
    @frame_instructions = []
    self.instruction_id += 1

  scrollWrite: (value) ->
    self = this
    self.ppuScrollWrite.call self.nes.ppu, value
    instruction = [self.INSTRUCTIONS.scrollWrite, value]
    self.frame_instructions.push instruction

  writeSRAMAddress: (value) ->
    self = this
    self.ppuWriteSRAMAddress.call self.nes.ppu, value
    instruction = [self.INSTRUCTIONS.writeSRAMAddress, value]
    self.frame_instructions.push instruction

  sramDMA: (value) ->
    self = this
    baseAddress = value * 0x100
    data = undefined
    i = self.nes.ppu.sramAddress

    while i < 256
      data = @nes.cpu.mem[baseAddress + i]
      self.sramBuffer[i] = self.nes.ppu.spriteMem[i] = data
      self.nes.ppu.spriteRamWriteUpdate i, data
      i++
    
    # Assuming we only receive 1 sramDMA per screen cycle, need to verify this
    instruction = [self.INSTRUCTIONS.sramDMA, value, self.sramBuffer]
    self.frame_instructions.push instruction
    self.nes.cpu.haltCycles 513

  sramWrite: (value) ->
    self = this
    @ppuSramWrite.call @nes.ppu, value
    instruction = [self.INSTRUCTIONS.sramWrite, value]
    self.frame_instructions.push instruction

  vramWrite: (value) ->
    self = this
    @ppuVramWrite.call @nes.ppu, value
    instruction = [self.INSTRUCTIONS.vramWrite, value]
    self.frame_instructions.push instruction

  writeVRAMAddress: (value) ->
    self = this
    @ppuWriteVRAMAddress.call @nes.ppu, value
    instruction = [@INSTRUCTIONS.writeVRAMAddress, value]
    self.frame_instructions.push instruction

  endScanline: ->
    self = this
    @ppuEndScanline.call @nes.ppu
    instruction = [self.INSTRUCTIONS.endScanLine, 1]
    last_instruction = self.frame_instructions[self.frame_instructions.length - 1]
    if last_instruction and last_instruction[0] is self.INSTRUCTIONS.endScanLine
      self.frame_instructions[self.frame_instructions.length - 1][1]++
    else
      self.frame_instructions.push instruction

  loadVromBank: (bank, address) ->
    self = this
    @mmapLoadVromBank.call @nes.mmap, bank, address
    instruction = [self.INSTRUCTIONS.loadVromBank, bank, address]
    @frame_instructions.push instruction

  load1kVromBank: (bank, address) ->
    self = this
    @mmapLoad1kVromBank.call @nes.mmap, bank, address
    instruction = [self.INSTRUCTIONS.load1kVromBank, bank, address]
    @frame_instructions.push instruction

  load2kVromBank: (bank, address) ->
    self = this
    @mmapLoad2kVromBank.call @nes.mmap, bank, address
    instruction = [self.INSTRUCTIONS.load2kVromBank, bank, address]
    @frame_instructions.push instruction

  f_mmapWrite: (address, value) ->
    self = this
    self.mmapWrite.call @nes.mmap, address, value
    unless address < 0x8000
      instruction = [self.INSTRUCTIONS.mmapWrite, address, value]
      @frame_instructions.push instruction

  setSprite0HitFlag: ->
    @ppuSetSprite0HitFlag.call @nes.ppu
    instruction = [@INSTRUCTIONS.setSprite0HitFlag]
    @frame_instructions.push instruction

  updateControlReg1: (value) ->
    @ppuUpdateControlReg1.call @nes.ppu, value
    instruction = [@INSTRUCTIONS.updateControlReg1, value]
    @frame_instructions.push instruction

  updateControlReg2: (value) ->
    @ppuUpdateControlReg2.call @nes.ppu, value
    instruction = [@INSTRUCTIONS.updateControlReg2, value]
    @frame_instructions.push instruction

  readStatusRegister: ->
    res = @ppuReadStatusRegister.call(@nes.ppu)
    instruction = [@INSTRUCTIONS.readStatusRegister]
    @frame_instructions.push instruction
    res

  setFrameRate: (rate) ->
    @nes.setFramerate rate

  calculateFrameRate: ->
    now = Date.now()
    self = this
    unless self.lastSendTime
      self.lastSendTime = now
    else
      frameRate = 1 / (now - self.lastSendTime) * 1000

      if frameRate < 15
        frameRate = 15
      else frameRate = 60  if frameRate > 60

      # Set to frameRate + 1 so we can increase until reaching limit.
      self.setFrameRate frameRate + 1
    self.lastSendTime = now

  setupRomListener: ->
    self = this
    @nes.ui.romSelect.unbind "change"
    @nes.ui.romSelect.bind "change", ->
      self.loadRom self.nes.ui.romSelect.val(), ->
        self.romInitialized()
        self.selectedRom = self.nes.ui.romSelect.val()
        self.partner "Rom:Changed", self.selectedRom
        self.onRomLoaded self.selectedRom
