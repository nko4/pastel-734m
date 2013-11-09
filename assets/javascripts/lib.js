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
}
