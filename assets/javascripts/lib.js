window.Ring = function() {
  var elements = [];
  var current = 0;
  var self = this;

  this.push = function(element) {
    elements.push(element);
  }

  this.next = function() {
    if (current + 1 < elements.length) {
      current++;
    } else {
      current = 0;
    }

    return self;
  }

  this.prev = function() {
     if (current > 0) {
      current--;
    } else {
      current = elements.length - 1;
    }

    return self;
  }

  this.get = function() {
    return elements[current];
  }

  this.map = function(fn) {
    Array.prototype.map.apply(self, fn);
  }

  this.forEach = function(fn) {
    Array.prototype.forEach.apply(self, fn);
  }
};

window.Speaker = function(stream) {
  var context;

  if (typeof(AudioContext) != 'undefined') {
    context = new AudioContext();
  }
  else if (typeof(webkitAudioContext) != 'undefined') {
    context = new webkitAudioContext();
  }
  else {
    console.log("Audio not supported");
    return;
  }

  // Gain filter controls volume
  var gain = context.createGain();
  gain.gain.value = 1;

  var analyser = context.createAnalyser();
  analyser.smoothingTimeConstant = 0.3;
  analyser.fftSize = 1024;

  var processor = context.createScriptProcessor(2048, 1, 1)

  // Filter connecting time
  analyser.connect(processor);
  processor.connect(context.destination);

  var muted = false;
  var self = this;

  this.mute = function() {
    muted = !muted;

    var audioTracks = self.stream.getAudioTracks();

    for (var i = 0, l = audioTracks.length; i < l; i++) {
      audioTracks[i].enabled = !muted;
    }
  }

  this.getVolume = function() {
    return gain.gain.value;
  }

  this.setVolume = function(volume) {
    gain.gain.value = volume;
  }

  this.setStream = function(stream) {
    if (self.source) {
      delete self.source;
    }

    if (stream) {
      self.stream = stream;
      self.source = context.createMediaStreamSource(stream);
      self.source.connect(gain);
      gain.connect(context.destination);

      self.source.connect(analyser);
    }
  }

  this.onNoise = function(fn) {
    processor.onaudioprocess = function() {
      array = new Uint8Array(analyser.frequencyBinCount);
      analyser.getByteFrequencyData(array)

      volume = 0

      for (var i = 0; i < array.length; i++) {
        volume += array[i];
      }

      volume /= array.length;
      fn(volume);
    }
  }

  this.setStream(stream);
}
