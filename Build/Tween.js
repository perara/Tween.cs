(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
'use strict';
var Tween,
  __modulo = function(a, b) { return (a % b + +b) % b; };

Tween = (function() {
  var ChainItem;

  ChainItem = (function() {
    function ChainItem() {
      this.property = null;
      this.duration = null;
      this.startTime = null;
      this.endTime = null;
      this.inited = false;
      this.type = null;
      this.next = null;
      this.previous = null;
      this.elapsed = 0;
    }

    return ChainItem;

  })();

  Tween._tweens = [];

  Tween.clear = function() {
    var tween, _i, _len, _ref, _results;
    _ref = Tween._tweens;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      tween = _ref[_i];
      _results.push(tween._complete = true);
    }
    return _results;
  };

  Tween._currentTime = 0;

  function Tween(object) {
    this._object = object;
    this._chain = [];
    this._properties = [];
    this._easing = Tween.Easing.Linear.None;
    this._interpolation = Tween.Interpolation.Linear;
    this._onUpdate = function() {};
    this._onComplete = function() {};
    this._onStart = function() {};
    this._started = false;
    this._complete = false;
    this._startDelay = 0;
    this._lastTime = 0;
    this._runCounter = 0;
    this._remainingRuns = 1;
    Tween._tweens.push(this);
  }

  Tween.prototype.getTweenChain = function() {
    return this._chain;
  };

  Tween.prototype.addToChain = function(newPath) {
    var first, last;
    if (this._chain.length > 0) {
      last = this._chain[this._chain.length - 1];
      last.next = newPath;
      first = this._chain[0];
      first.previous = newPath;
      newPath.previous = last;
      newPath.next = first;
    } else {
      newPath.previous = newPath;
      newPath.next = newPath;
    }
    return this._chain.push(newPath);
  };

  Tween.prototype.startDelay = function(time) {
    return this._startDelay = time;
  };

  Tween.prototype.start = function() {
    this._started = true;
    return this._onStart(this._object);
  };

  Tween.prototype.stop = function() {
    this._started = false;
    return this._complete = true;
  };

  Tween.prototype.pause = function() {
    return this._started = false;
  };

  Tween.prototype.unpause = function() {
    var chainItem, elapsedTime, time, timeLeft;
    this._started = true;
    time = performance.now();
    chainItem = this._chain[__modulo(this._runCounter, this._chain.length)];
    elapsedTime = (chainItem.endTime - chainItem.startTime) * chainItem.elapsed;
    timeLeft = chainItem.duration - elapsedTime;
    chainItem.endTime = time + timeLeft;
    return chainItem.startTime = chainItem.endTime - chainItem.duration;
  };

  Tween.prototype.easing = function(easing) {
    return this._easing = easing;
  };

  Tween.prototype.to = function(property, duration) {
    var newPath, prop, _i, _len, _ref;
    _ref = Tween.flattenKeys(property);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      prop = _ref[_i];
      if (prop.split(".").length <= 1) {
        this.shallow = true;
      }
      this._properties.push(prop);
    }
    newPath = new ChainItem();
    newPath.property = property;
    newPath.duration = duration;
    newPath.startTime = null;
    newPath.endTime = null;
    newPath.inited = false;
    newPath.type = "translate";
    newPath.next = null;
    newPath.previous = null;
    newPath.elapsed = 0;
    return this.addToChain(newPath);
  };

  Tween.prototype.delay = function(time) {
    var delayItem;
    if (typeof time !== 'number') {
      throw new Error("Time was not a number!");
    }
    delayItem = {
      "duration": time,
      "startTime": null,
      "endTime": null,
      "type": "delay",
      "previous": null,
      "next": null
    };
    return this.addToChain(delayItem);
  };

  Tween.prototype.repeat = function(num) {
    return this._remainingRuns = num;
  };

  Tween.prototype.addCutsomProperty = function(property) {
    return this._properties.push(property);
  };

  Tween.prototype.addCutsomProperties = function(properties) {
    var property, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = properties.length; _i < _len; _i++) {
      property = properties[_i];
      _results.push(this.addProperty(property));
    }
    return _results;
  };

  Tween.prototype.onUpdate = function(callback) {
    this._onUpdate = callback;
    return this.onUpdate = true;
  };

  Tween.prototype.onComplete = function(callback) {
    return this._onComplete = callback;
  };

  Tween.prototype.onStart = function(callback) {
    return this._onStart = callback;
  };

  Tween.update = function(time) {
    var chainItem, elapsed, end, key, nextPos, prop, property, start, startTime, tween, value, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2, _results;
    Tween._currentTime = time;
    if (Tween._tweens.length <= 0) {
      return;
    }
    _ref = Tween._tweens;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      tween = _ref[_i];
      if (!tween) {
        continue;
      }
      if (tween._complete) {
        tween._onComplete(tween._object);
        Tween._tweens.splice(Tween._tweens.indexOf(tween), 1);
        continue;
      }
      if (!tween._started) {
        continue;
      }
      if (time < tween._startTime + tween._startDelay) {
        continue;
      }
      if (tween._chain.length <= 0 || tween._remainingRuns <= 0) {
        tween._complete = true;
        continue;
      }
      chainItem = tween._chain[__modulo(tween._runCounter, tween._chain.length)];
      if (!chainItem.inited) {
        chainItem.startTime = performance.now();
        chainItem.endTime = chainItem.startTime + chainItem.duration;
        chainItem.inited = true;
        if (chainItem.type === "delay") {
          break;
        }
        chainItem.startPos = {};
        _ref1 = tween._properties;
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          property = _ref1[_j];
          key = property.split('.')[0];
          value = tween._object[key];
          chainItem.startPos[key] = typeof value === 'object' ? Tween.clone(value) : value;
        }
      }
      if (time > chainItem.endTime) {
        tween._runCounter++;
        chainItem.startTime = null;
        chainItem.endTime = null;
        chainItem.inited = false;
        if (__modulo(tween._runCounter, tween._chain.length) === 0) {
          tween._remainingRuns -= 1;
        }
        continue;
      }
      if (chainItem.type === "delay") {
        continue;
      }
      startTime = chainItem.startTime;
      start = chainItem.startPos;
      end = chainItem.property;
      elapsed = (performance.now() - startTime) / chainItem.duration;
      chainItem.elapsed = elapsed;
      elapsed = elapsed > 1 ? 1 : elapsed;
      value = tween._easing(elapsed);
      if (tween.onUpdate) {
        tween._onUpdate(chainItem);
      }
      _ref2 = tween._properties;
      for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
        prop = _ref2[_k];
        if (tween.shallow) {
          tween._object[prop] = start[prop] + (end[prop] - start[prop]) * value;
        } else {
          nextPos = Tween.resolve(start, prop) + (Tween.resolve(end, prop) - Tween.resolve(start, prop)) * value;
          Tween.resolve(tween._object, prop, null, nextPos);
        }
      }
      continue;
    }
    return _results;
  };

  Tween.clone = function(obj) {
    var i, target;
    target = {};
    for (i in obj) {
      if (obj.hasOwnProperty(i)) {
        target[i] = obj[i];
      }
    }
    return target;
  };

  Tween.resolve = function(obj, path, def, setValue) {
    var i, len, previous;
    i = void 0;
    len = void 0;
    previous = obj;
    i = 0;
    path = path.split('.');
    len = path.length;
    while (i < len) {
      if (!obj || typeof obj !== 'object') {
        return def;
      }
      previous = obj;
      obj = obj[path[i]];
      i++;
    }
    if (obj === void 0) {
      return def;
    }
    if (setValue) {
      previous[path[len - 1]] = setValue;
    }
    return obj;
  };

  Tween.flattenKeys = function(obj, delimiter, max_depth) {
    var recurse;
    delimiter = delimiter || '.';
    max_depth = max_depth || 2;
    recurse = function(obj, path, result, level) {
      if (level > max_depth) {
        return;
      }
      level++;
      if (typeof obj === 'object' && obj) {
        Object.keys(obj).forEach(function(key) {
          path.push(key);
          recurse(obj[key], path, result, level);
          return path.pop();
        });
      } else {
        result.push(path.join(delimiter));
      }
      return result;
    };
    return recurse(obj, [], [], 0);
  };

  Tween.Easing = {
    Linear: {
      None: function(k) {
        return k;
      }
    },
    Quadratic: {
      In: function(k) {
        return k * k;
      },
      Out: function(k) {
        return k * (2 - k);
      },
      InOut: function(k) {
        if ((k *= 2) < 1) {
          return 0.5 * k * k;
        }
        return -0.5 * (--k * (k - 2) - 1);
      }
    },
    Cubic: {
      In: function(k) {
        return k * k * k;
      },
      Out: function(k) {
        return --k * k * k + 1;
      },
      InOut: function(k) {
        if ((k *= 2) < 1) {
          return 0.5 * k * k * k;
        }
        return 0.5 * ((k -= 2) * k * k + 2);
      }
    },
    Quartic: {
      In: function(k) {
        return k * k * k * k;
      },
      Out: function(k) {
        return 1 - --k * k * k * k;
      },
      InOut: function(k) {
        if ((k *= 2) < 1) {
          return 0.5 * k * k * k * k;
        }
        return -0.5 * ((k -= 2) * k * k * k - 2);
      }
    },
    Quintic: {
      In: function(k) {
        return k * k * k * k * k;
      },
      Out: function(k) {
        return --k * k * k * k * k + 1;
      },
      InOut: function(k) {
        if ((k *= 2) < 1) {
          return 0.5 * k * k * k * k * k;
        }
        return 0.5 * ((k -= 2) * k * k * k * k + 2);
      }
    },
    Sinusoidal: {
      In: function(k) {
        return 1 - Math.cos(k * Math.PI / 2);
      },
      Out: function(k) {
        return Math.sin(k * Math.PI / 2);
      },
      InOut: function(k) {
        return 0.5 * (1 - Math.cos(Math.PI * k));
      }
    },
    Exponential: {
      In: function(k) {
        if (k === 0) {
          return 0;
        } else {
          return Math.pow(1024, k - 1);
        }
      },
      Out: function(k) {
        if (k === 1) {
          return 1;
        } else {
          return 1 - Math.pow(2, -10 * k);
        }
      },
      InOut: function(k) {
        if (k === 0) {
          return 0;
        }
        if (k === 1) {
          return 1;
        }
        if ((k *= 2) < 1) {
          return 0.5 * Math.pow(1024, k - 1);
        }
        return 0.5 * (-(Math.pow(2, -10 * (k - 1))) + 2);
      }
    },
    Circular: {
      In: function(k) {
        return 1 - Math.sqrt(1 - k * k);
      },
      Out: function(k) {
        return Math.sqrt(1 - --k * k);
      },
      InOut: function(k) {
        if ((k *= 2) < 1) {
          return -0.5 * (Math.sqrt(1 - k * k) - 1);
        }
        return 0.5 * (Math.sqrt(1 - (k -= 2) * k) + 1);
      }
    },
    Elastic: {
      In: function(k) {
        var a, p, s;
        s = void 0;
        a = 0.1;
        p = 0.4;
        if (k === 0) {
          return 0;
        }
        if (k === 1) {
          return 1;
        }
        if (!a || a < 1) {
          a = 1;
          s = p / 4;
        } else {
          s = p * Math.asin(1 / a) / 2 * Math.PI;
        }
        return -(a * Math.pow(2, 10 * (k -= 1)) * Math.sin((k - s) * 2 * Math.PI / p));
      },
      Out: function(k) {
        var a, p, s;
        s = void 0;
        a = 0.1;
        p = 0.4;
        if (k === 0) {
          return 0;
        }
        if (k === 1) {
          return 1;
        }
        if (!a || a < 1) {
          a = 1;
          s = p / 4;
        } else {
          s = p * Math.asin(1 / a) / 2 * Math.PI;
        }
        return a * Math.pow(2, -10 * k) * Math.sin((k - s) * 2 * Math.PI / p) + 1;
      },
      InOut: function(k) {
        var a, p, s;
        s = void 0;
        a = 0.1;
        p = 0.4;
        if (k === 0) {
          return 0;
        }
        if (k === 1) {
          return 1;
        }
        if (!a || a < 1) {
          a = 1;
          s = p / 4;
        } else {
          s = p * Math.asin(1 / a) / 2 * Math.PI;
        }
        if ((k *= 2) < 1) {
          return -0.5 * a * Math.pow(2, 10 * (k -= 1)) * Math.sin((k - s) * 2 * Math.PI / p);
        }
        return a * Math.pow(2, -10 * (k -= 1)) * Math.sin((k - s) * 2 * Math.PI / p) * 0.5 + 1;
      }
    },
    Back: {
      In: function(k) {
        var s;
        s = 1.70158;
        return k * k * ((s + 1) * k - s);
      },
      Out: function(k) {
        var s;
        s = 1.70158;
        return --k * k * ((s + 1) * k + s) + 1;
      },
      InOut: function(k) {
        var s;
        s = 1.70158 * 1.525;
        if ((k *= 2) < 1) {
          return 0.5 * k * k * ((s + 1) * k - s);
        }
        return 0.5 * ((k -= 2) * k * ((s + 1) * k + s) + 2);
      }
    },
    Bounce: {
      In: function(k) {
        return 1 - Tween.Easing.Bounce.Out(1 - k);
      },
      Out: function(k) {
        if (k < 1 / 2.75) {
          return 7.5625 * k * k;
        } else if (k < 2 / 2.75) {
          return 7.5625 * (k -= 1.5 / 2.75) * k + 0.75;
        } else if (k < 2.5 / 2.75) {
          return 7.5625 * (k -= 2.25 / 2.75) * k + 0.9375;
        } else {
          return 7.5625 * (k -= 2.625 / 2.75) * k + 0.984375;
        }
      },
      InOut: function(k) {
        if (k < 0.5) {
          return Tween.Easing.Bounce.In(k * 2) * 0.5;
        }
        return Tween.Easing.Bounce.Out(k * 2 - 1) * 0.5 + 0.5;
      }
    }
  };

  Tween.Interpolation = {
    Linear: function(v, k) {
      var f, fn, i, m;
      m = v.length - 1;
      f = m * k;
      i = Math.floor(f);
      fn = Tween.Interpolation.Utils.Linear;
      if (k < 0) {
        return fn(v[0], v[1], f);
      }
      if (k > 1) {
        return fn(v[m], v[m - 1], m - f);
      }
      return fn(v[i], v[i + 1 > m ? m : i + 1], f - i);
    },
    Bezier: function(v, k) {
      var b, bn, i, n, pw;
      b = 0;
      n = v.length - 1;
      pw = Math.pow;
      bn = Tween.Interpolation.Utils.Bernstein;
      i = void 0;
      i = 0;
      while (i <= n) {
        b += pw(1 - k, n - i) * pw(k, i) * v[i] * bn(n, i);
        i++;
      }
      return b;
    },
    CatmullRom: function(v, k) {
      var f, fn, i, m;
      m = v.length - 1;
      f = m * k;
      i = Math.floor(f);
      fn = Tween.Interpolation.Utils.CatmullRom;
      if (v[0] === v[m]) {
        if (k < 0) {
          i = Math.floor(f = m * (1 + k));
        }
        return fn(v[(i - 1 + m) % m], v[i], v[(i + 1) % m], v[(i + 2) % m], f - i);
      } else {
        if (k < 0) {
          return v[0] - (fn(v[0], v[0], v[1], v[1], -f) - v[0]);
        }
        if (k > 1) {
          return v[m] - (fn(v[m], v[m], v[m - 1], v[m - 1], f - m) - v[m]);
        }
        return fn(v[i ? i - 1 : 0], v[i], v[m < i + 1 ? m : i + 1], v[m < i + 2 ? m : i + 2], f - i);
      }
    },
    Utils: {
      Linear: function(p0, p1, t) {
        return (p1 - p0) * t + p0;
      },
      Bernstein: function(n, i) {
        var fc;
        fc = Tween.Interpolation.Utils.Factorial;
        return fc(n) / fc(i) / fc(n - i);
      },
      Factorial: (function() {
        var a;
        a = [1];
        return function(n) {
          var i, s;
          s = 1;
          i = void 0;
          if (a[n]) {
            return a[n];
          }
          i = n;
          while (i > 1) {
            s *= i;
            i--;
          }
          return a[n] = s;
        };
      })(),
      CatmullRom: function(p0, p1, p2, p3, t) {
        var t2, t3, v0, v1;
        v0 = (p2 - p0) * 0.5;
        v1 = (p3 - p1) * 0.5;
        t2 = t * t;
        t3 = t * t2;
        return (2 * p1 - 2 * p2 + v0 + v1) * t3 + (-3 * p1 + 3 * p2 - 2 * v0 - v1) * t2 + v0 * t + p1;
      }
    }
  };

  return Tween;

})();

module.exports = Tween;

window.Tween = Tween;


},{}]},{},[1]);