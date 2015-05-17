###*
# @class ChainItem
# @module TweenCS
# @namespace TweenCS
# @constructor
###
class ChainItem

  constructor: ->

    ###*
    # Which property this chain modifies
    # @property {Object} property
    # @private
    ###
    @property = null

    ###*
    # The chain item duration
    # @property {Integer} duration
    # @private
    ###
    @duration = null

    ###*
    # The start timestamp of the chainItem
    # @property {Long} startTime
    # @private
    ###
    @startTime = null

    ###*
    # The end timestamp of the chainItem
    # @property {Long} endTime
    # @private
    ###
    @endTime = null

    ###*
    # If the chainItem has been initialized
    # @property {Boolean} inited
    # @private
    ###
    @inited = false

    ###*
    # Which type this chain item is, Delay, Translation etc.
    # @property {String} type
    # @private
    ###
    @type = null

    ###*
    # Next chainItem in the loop
    # @property {TweenCS.ChainItem} next
    # @private
    ###
    @next = null

    ###*
    # Previous chainItem in the loop
    # @property {TweenCS.ChainItem} previous
    # @private
    ###
    @previous = null

    ###*
    # The elapsed percentage of the chainItem (Between 0 and 1)
    # @property {Number} elapsed
    # @private
    ###
    @elapsed = 0



###*
﻿# The tween class of Gotham
# This class animates objects of any format
# It features to reach deep proprerties in an object
# @class Tween
# @module TweenCS
# @namespace TweenCS
# @constructor
# @param object {Object} The object to tween
#
# @example
#       # How to use:
#       # Start
#       tweenTo =
#         scale:
#           x: 2
#           y: 2
#       rotation: 0.1
#
#       # End
#       tweenBack =
#         scale:
#           x: 1
#           y: 1
#       rotation: -0.1
#
#       tween = new Tween object
#       tween.startDelay 500
#       tween.repeat(Infinity)
#       tween.easing Tween.Easing.Circular.InOut
#       tween.to tweenTo, 1500
#       tween.to tweenBack, 1500
#       tween.onStart ->
#         console.log @ + " started!"
#       tween.start()
###
class Tween

  ###*
  # Static list of all ongoing tweens
  # @property {Array[Tween]} _tweens
  # @static
  # @private
  ###
  @_tweens = []

  ###*
  # Clear all ongoing tweens in loop
  # @method clear
  # @static
  ####
  @clear = ->
    for tween in Tween._tweens
      tween._complete = true

  ###*
  # Current runtime time, Retreived from GameLoop's update()
  # @property _currentTime {Long}
  # @static
  ###
  @_currentTime = 0

  # Initializes the Tween object
  # Does however not start the tween
  # Adds "this" tween to the Static tween array
  constructor: (object) ->


    ###*
    # The object to do tweening on
    # @property {Object} _object
    # @private
    ###
    @_object = object


    ###*
    # Chain of tweens to be applied to object (ChainItems)
    # @property {Array} _chain
    # @private
    ###

    @_chain = []


    ###*
    # The properties to process while tweening
    # @property {Array} _properties
    # @private
    ###
    @_properties = []

    ###*
    # The easing to use, Default is Linear
    # @property {Tween.Easing} _easing
    # @private
    ###
    @_easing = Tween.Easing.Linear.None

    ###*
    # Which interpolation to use, default is Linear
    # @property {Tween.Interpolation} _interpolation
    # @private
    ###
    @_interpolation = Tween.Interpolation.Linear

    ###*
    # onUpdate callback
    # @method _onUpdate
    # @private
    ###
    @_onUpdate = ->

    ###*
    # onComplete callback
    # @method _onComplete
    # @private
    ###
    @_onComplete = ->

    ###*
    # onStart callback
    # @method  _onStart
    # @private
    ###
    @_onStart = ->

    ###*
    # If the tween collection has started or not
    # @property {Boolean} _started
    # @private
    ###
    @_started = false

    ###*
    # If the tween collection is complete or not
    # @property {Boolean} _complete
    # @private
    ###
    @_complete = false

    ###*
    # The tween start delay
    # @property {Number} _startDelay
    # @private
    ###
    @_startDelay = 0

    ###*
    # Number of runs done (Incremented per chainItem
    # @property {Number} _runCounter
    # @private
    ###
    @_runCounter = 0

    ###*
    # Number of remaining runs for this tween
    # @property {Number} _remainingRuns
    # @private
    ###
    @_remainingRuns = 1 # Remaining runs the tweet should do (default: 1 time) , Modified by .repeat(xx)

    # Adds this tween to the static tweens list
    Tween._tweens.push(@)

  ###*
  # Retrieve all chainItems of the Tween
  # @method getTweenChain
  # @returns {TweenCS.ChainItem} The tween Chain
  ###
  getTweenChain: ->
    return @_chain

  ###*
  # Adds a new TweenCS.ChainItem to the chain
  # @method addToChain
  # @param newPath {TweenCS.ChainItem} The chain item
  ###
  addToChain: (newPath)->

    if @_chain.length > 0
      # Retrieve last node in list
      last = @_chain[@_chain.length-1]
      last.next = newPath

      # Retrieve first node in list
      first = @_chain[0]
      first.previous = newPath

      newPath.previous = last
      newPath.next = first
    else
      newPath.previous = newPath # Self reference
      newPath.next = newPath

    # Add to the tweenChain
    @_chain.push(newPath)


############################################
##
## Events Like:
## * Start
## * Stop
## * Pause
##
############################################

  ###*
  # Sets Delay of the start
  # @method startDelay
  # @param time {Number} Delay in milliseconds
  ###
  startDelay: (time) ->
    @_startDelay = time

  ###*
  # Starts the tween. _onStart callback is called
  # @method start
  ###
  start: ->
    @_started = true
    @_onStart(@_object)

  ###*
  # Stops the tween
  # @method stop
  ###
  stop: ->
    @_started = false
    @_complete = true

  ###*
  # Pauses the tween.
  # @method pause
  ###
  pause: ->
    @_started = false

  ###*
  # Unpauses the tween.
  # @method unpause
  ###
  unpause: ->
    @_started = true

    # Update end time
    time = performance.now()
    chainItem = @_chain[@_runCounter %% @_chain.length]

    # Determine how far current chainItem has animated
    elapsedTime = (chainItem.endTime - chainItem.startTime) * chainItem.elapsed

    # Subtract duration with elapsed time to get remaining animation time
    timeLeft = chainItem.duration - elapsedTime

    # Update endtime with timeLeft
    chainItem.endTime = time + timeLeft
    chainItem.startTime = chainItem.endTime - chainItem.duration





############################################
##
## Function which manipulate tween behaviour
##
############################################

  ###*
  # Set the easing algorithm for the tween
  # The easing algorithms are found in the Tween.Easing object.
  # @method easing
  # @param easing {Tween.Easing} The easing algorithm
  # @example
  #         obj.easing(Tween.Easing.Linear.None)
  #
  # @chainable
  ###
  easing: (easing) ->
    @_easing = easing
    return @


  ###*
  # Adds a function to the tween chain. Neat for when you want logic to run between two tweens
  # @method func
  # @chainable
  ###
  func: (_c)->
    newPath = new ChainItem()
    newPath.callback = _c
    newPath.property = null
    newPath.properties = []
    newPath.shallow = true
    newPath.duration = 0
    newPath.startTime = null
    newPath.endTime = null
    newPath.inited = true
    newPath.next = null
    newPath.previous = null
    newPath.type = "func"
    newPath.elapsed = 0
    @addToChain newPath
    return @

  ###*
  # Add tween action to the tween chain
  # @method to
  # @param property {Object} The "goal" property of the tween (Where you want the target object to end up)
  # @param duration {Long} Duration of the tween from start --> end (In milliseconds)
  # @chainable
  ###
  to: (property, duration) ->

    properties = []
    shallow = false
    # Add properties to the property list
    for prop in Tween.flattenKeys property

      if prop.split(".").length <= 1
        shallow = true

      properties.push prop
      @_properties.push(prop)

    newPath = new ChainItem()
    newPath.property = property # The Property to translate to
    newPath.properties = properties
    newPath.shallow = shallow
    newPath.duration = duration # Duration of the tween event
    newPath.startTime = null # Set when starting tween .start()
    newPath.endTime = null # Set when starting tween .start()
    newPath.inited = false
    newPath.type = "translate" # The type of the tweenEvent
    newPath.next = null
    newPath.previous = null
    newPath.elapsed = 0

    @addToChain newPath

    return @




  ###*
  # Add a delay between two tween goto's
  # @method delay
  # @param time {Long} Delay in Milliseconds
  # @chainable
  ###
  delay: (time) ->

    if typeof time isnt 'number'
      throw new Error "Time was not a number!"

    delayItem =
      "properties": []
      "duration" : time
      "startTime" : null # Set when starting tween .start()
      "endTime" : null # Set when starting tween .start()
      "type" : "delay"
      "previous": null
      "next": null

    @addToChain delayItem
    return @

  ###*
  # How many times you want to repeat the Tween
  # To repeat "forever", use Infinity
  # @method repeat
  # @param num {Integer} Number of times to repeat
  # @chainable
  ###
  repeat: (num) ->
    @_remainingRuns = num
    return @

############################################
##
## Callbacks
##
############################################

  ###*
  # The onUpdate callback
  # Is called when the tween is updated
  # @method onUpdate
  # @param callback {Callback} The onUpdate callback
  ###
  onUpdate: (callback) ->
    @_onUpdate = callback
    @onUpdate = true

  ###*
  # The onComplete callback
  # Is called when the tween is completed
  # @method onComplete
  # @param callback {Callback} The onComplete callback
  ###
  onComplete: (callback) ->
    @_onComplete = callback

  ###*
  # The onStart callback
  # Is called when the tween is started
  # @method onStart
  # @param callback {Callback} The onStart callback
  ###
  onStart: (callback) ->
    @_onStart = callback

  ###*
  # Update loop of the tween engine ensures that tweening actually happens
  # IT is called from GameLoop.update()
  # @method update
  # @param time {Long} Render runtime in milliseconds
  # @static
  ###
  @update: (time) ->
    Tween._currentTime = time

    # Return if no tweens
    if Tween._tweens.length <= 0
      return

    # Iterate through each of the tweens
    for tween in Tween._tweens

      # Because we delete directly from _tweens array, it may iterate over a undefined node (if previous was deleted. This causes undefined tween. But IGNORE it)
      if not tween
        continue

      # Continue and remove if tween is complete
      if tween._complete
        tween._onComplete(tween)
        # Remove element
        Tween._tweens.splice(Tween._tweens.indexOf(tween), 1);
        continue


      # Continue if tween is paused
      if not tween._started
        continue

      # Continue if tween is not yet started
      if time < tween._startTime + tween._startDelay
        continue

      # Set Tween to done if no items in chain
      if tween._chain.length <= 0 or tween._remainingRuns <= 0
        tween._complete = true
        continue

      # Fetch chainItem
      chainItem = tween._chain[tween._runCounter %% tween._chain.length]


      # Initialize Chain Item
      if !chainItem.inited
        chainItem.startTime =  performance.now()
        chainItem.endTime = chainItem.startTime + chainItem.duration
        chainItem.inited = true

        if chainItem.type == "delay" or chainItem.type == "func"
          break

        chainItem.startPos = {}

        for property in tween._properties
          key = property.split('.')[0]
          value = tween._object[key]

          chainItem.startPos[key] = if typeof value == 'object' then Tween.clone(value) else value


      if time > chainItem.endTime && chainItem.elapsed >= 0.99

        # Increment run counter
        tween._runCounter++

        # Reset chainItem data
        chainItem.startTime = null
        chainItem.endTime = null
        chainItem.inited = false
        chainItem.elapsed = 0 #TODO, be careful, Not fully tested


        # Decrement remaining runs by 1
        if tween._runCounter %% tween._chain.length == 0
          tween._remainingRuns -= 1
        continue


      # Execute the callback function
      if chainItem.type == "func"
        chainItem.callback()


      # Elapsed Time of the tween
      startTime = chainItem.startTime
      #endTime = startTime + chainItem.duration

      # Start and end of the tween
      start = chainItem.startPos
      end = chainItem.property

      # The elapsed time of the tween
      elapsed = (performance.now() - startTime) / chainItem.duration
      elapsed = if elapsed > 1 then  1 else elapsed
      chainItem.elapsed = elapsed


      # Calculate the new multiplication value
      value = tween._easing elapsed

      if(tween.onUpdate)
        tween._onUpdate(chainItem)


      for prop in chainItem.properties
        if chainItem.shallow
          tween._object[prop] = start[prop] + (end[prop] - start[prop]) * value
        else
          nextPos = (Tween.resolve(start, prop) + (Tween.resolve(end, prop) - Tween.resolve(start, prop)) * value)
          Tween.resolve(tween._object, prop, null, nextPos)

      continue


  #eval("tween._object.#{prop} = start.#{prop} +  ( end.#{prop} - start.#{prop} ) * #{value}")

  ###*
  # Clones a object
  # @method clone
  # @param obj {Object} the object to clone
  # @static
  ###
  Tween.clone = (obj) ->
    target = {}
    for i of obj
      if obj.hasOwnProperty(i)
        target[i] = obj[i]
    target

  ###*
  # Resolves a string property. Ex: "a.b". which is obj["a"]["b"]
  # @method resolve
  # @param obj {Object} the object to resolve
  # @param path {String} the object path
  # @param def {Object} default if not found
  # @param setValue {Object} Value to set on the path
  # @static
  ###
  Tween.resolve = (obj, path, def, setValue) ->
    i = undefined
    len = undefined
    previous = obj
    i = 0
    path = path.split('.')
    len = path.length

    while i < len
      if !obj or typeof obj != 'object'
        return def

      previous = obj
      obj = obj[path[i]]
      i++

    if obj == undefined
      return def

    # If setValue is set, set the returning value to something
    if setValue
      previous[path[len-1]] = setValue

    return obj

  ###*
  # Function for finding properties recursively in an Object
  # @method flattenKeys
  # @param obj {Object} Start/Parent Node
  # @param delimiter {String} The Delimeter of the result. Default: "."
  # @param max_depth {Integer} Max Depth of the recursion
  # @return {Array} Array with the resulting properties
  # @static
  ###
  @flattenKeys = (obj, delimiter, max_depth) ->
    delimiter = delimiter or '.'
    max_depth = max_depth or 2

    # Recurse function
    recurse = (obj, path, result, level) ->

      if level > max_depth
        return

      level++
      if typeof obj == 'object' and obj
        Object.keys(obj).forEach (key) ->
          path.push key
          recurse obj[key], path, result, level
          path.pop()
      else
        result.push path.join(delimiter)
      return result

    recurse obj, [], [], 0

  ###*
  # @property {Object} Easing
  # @property {Object} Easing.Linear
  # @property {Function} Easing.Linear.None
  # @property {Object} Easing.Quadratic
  # @property {Function} Easing.Quadratic.In
  # @property {Function} Easing.Quadratic.Out
  # @property {Function} Easing.Quadratic.InOut
  # @property {Object} Easing.Cubic
  # @property {Function} Easing.Cubic.In
  # @property {Function} Easing.Cubic.Out
  # @property {Function} Easing.Cubic.InOut
  # @property {Object} Easing.Quartic
  # @property {Function} Easing.Quartic.In
  # @property {Function} Easing.Quartic.Out
  # @property {Function} Easing.Quartic.InOut
  # @property {Object} Easing.Quintic
  # @property {Function} Easing.Quintic.In
  # @property {Function} Easing.Quintic.Out
  # @property {Function} Easing.Quintic.InOut
  # @property {Object} Easing.Sinusoidal
  # @property {Function} Easing.Sinusoidal.In
  # @property {Function} Easing.Sinusoidal.Out
  # @property {Function} Easing.Sinusoidal.InOut
  # @property {Object} Easing.Exponential
  # @property {Function} Easing.Exponential.In
  # @property {Function} Easing.Exponential.Out
  # @property {Function} Easing.Exponential.InOut
  # @property {Object} Easing.Circular
  # @property {Function} Easing.Circular.In
  # @property {Function} Easing.Circular.Out
  # @property {Function} Easing.Circular.InOut
  # @property {Object} Easing.Elastic
  # @property {Function} Easing.Elastic.In
  # @property {Function} Easing.Elastic.Out
  # @property {Function} Easing.Elastic.InOut
  # @property {Object} Easing.Back
  # @property {Function} Easing.Back.In
  # @property {Function} Easing.Back.Out
  # @property {Function} Easing.Back.InOut
  # @property {Object} Easing.Bounce
  # @property {Function} Easing.Bounce.In
  # @property {Function} Easing.Bounce.Out
  # @property {Function} Easing.Bounce.InOut
  # @static
  ###
  @Easing =
    Linear: None: (k) ->
      k
    Quadratic:
      In: (k) ->
        k * k
      Out: (k) ->
        k * (2 - k)
      InOut: (k) ->
        if (k *= 2) < 1
          return 0.5 * k * k
        -0.5 * (--k * (k - 2) - 1)
    Cubic:
      In: (k) ->
        k * k * k
      Out: (k) ->
        --k * k * k + 1
      InOut: (k) ->
        if (k *= 2) < 1
          return 0.5 * k * k * k
        0.5 * ((k -= 2) * k * k + 2)
    Quartic:
      In: (k) ->
        k * k * k * k
      Out: (k) ->
        1 - --k * k * k * k
      InOut: (k) ->
        if (k *= 2) < 1
          return 0.5 * k * k * k * k
        -0.5 * ((k -= 2) * k * k * k - 2)
    Quintic:
      In: (k) ->
        k * k * k * k * k
      Out: (k) ->
        --k * k * k * k * k + 1
      InOut: (k) ->
        if (k *= 2) < 1
          return 0.5 * k * k * k * k * k
        0.5 * ((k -= 2) * k * k * k * k + 2)
    Sinusoidal:
      In: (k) ->
        1 - Math.cos(k * Math.PI / 2)
      Out: (k) ->
        Math.sin k * Math.PI / 2
      InOut: (k) ->
        0.5 * (1 - Math.cos(Math.PI * k))
    Exponential:
      In: (k) ->
        if k == 0 then 0 else 1024 ** (k - 1)
      Out: (k) ->
        if k == 1 then 1 else 1 - 2 ** (-10 * k)
      InOut: (k) ->
        if k == 0
          return 0
        if k == 1
          return 1
        if (k *= 2) < 1
          return 0.5 * 1024 ** (k - 1)
        0.5 * (-2 ** (-10 * (k - 1)) + 2)
    Circular:
      In: (k) ->
        1 - Math.sqrt(1 - k * k)
      Out: (k) ->
        Math.sqrt 1 - --k * k
      InOut: (k) ->
        if (k *= 2) < 1
          return -0.5 * (Math.sqrt(1 - k * k) - 1)
        0.5 * (Math.sqrt(1 - (k -= 2) * k) + 1)
    Elastic:
      In: (k) ->
        s = undefined
        a = 0.1
        p = 0.4
        if k == 0
          return 0
        if k == 1
          return 1
        if !a or a < 1
          a = 1
          s = p / 4
        else
          s = p * Math.asin(1 / a) / 2 * Math.PI
        -(a * 2 ** (10 * (k -= 1)) * Math.sin((k - s) * 2 * Math.PI / p))
      Out: (k) ->
        s = undefined
        a = 0.1
        p = 0.4
        if k == 0
          return 0
        if k == 1
          return 1
        if !a or a < 1
          a = 1
          s = p / 4
        else
          s = p * Math.asin(1 / a) / 2 * Math.PI
        a * 2 ** (-10 * k) * Math.sin((k - s) * 2 * Math.PI / p) + 1
      InOut: (k) ->
        s = undefined
        a = 0.1
        p = 0.4
        if k == 0
          return 0
        if k == 1
          return 1
        if !a or a < 1
          a = 1
          s = p / 4
        else
          s = p * Math.asin(1 / a) / 2 * Math.PI
        if (k *= 2) < 1
          return -0.5 * a * 2 ** (10 * (k -= 1)) * Math.sin((k - s) * 2 * Math.PI / p)
        a * 2 ** (-10 * (k -= 1)) * Math.sin((k - s) * 2 * Math.PI / p) * 0.5 + 1
    Back:
      In: (k) ->
        s = 1.70158
        k * k * ((s + 1) * k - s)
      Out: (k) ->
        s = 1.70158
        --k * k * ((s + 1) * k + s) + 1
      InOut: (k) ->
        s = 1.70158 * 1.525
        if (k *= 2) < 1
          return 0.5 * k * k * ((s + 1) * k - s)
        0.5 * ((k -= 2) * k * ((s + 1) * k + s) + 2)
    Bounce:
      In: (k) ->
        1 - Tween.Easing.Bounce.Out(1 - k)
      Out: (k) ->
        if k < 1 / 2.75
          7.5625 * k * k
        else if k < 2 / 2.75
          7.5625 * (k -= 1.5 / 2.75) * k + 0.75
        else if k < 2.5 / 2.75
          7.5625 * (k -= 2.25 / 2.75) * k + 0.9375
        else
          7.5625 * (k -= 2.625 / 2.75) * k + 0.984375
      InOut: (k) ->
        if k < 0.5
          return Tween.Easing.Bounce.In(k * 2) * 0.5
        Tween.Easing.Bounce.Out(k * 2 - 1) * 0.5 + 0.5

  ###*
  # @property {Object} Interpolation
  # @property {Function} Interpolation.Linear
  # @property {Function} Interpolation.Bezier
  # @property {Function} Interpolation.CatmullRom
  # @property {Object} Interpolation.Utils
  # @property {Function} Interpolation.Utils.Linear
  # @property {Function} Interpolation.Utils.Bernstein
  # @property {Function} Interpolation.Utils.Factorial
  # @property {Function} Interpolation.Utils.CatmullRom
  # @static
  ###
  @Interpolation =
    Linear: (v, k) ->
      m = v.length - 1
      f = m * k
      i = Math.floor(f)
      fn = Tween.Interpolation.Utils.Linear
      if k < 0
        return fn(v[0], v[1], f)
      if k > 1
        return fn(v[m], v[m - 1], m - f)
      fn v[i], v[if i + 1 > m then m else i + 1], f - i
    Bezier: (v, k) ->
      b = 0
      n = v.length - 1
      pw = Math.pow
      bn = Tween.Interpolation.Utils.Bernstein
      i = undefined
      i = 0
      while i <= n
        b += pw(1 - k, n - i) * pw(k, i) * v[i] * bn(n, i)
        i++
      b
    CatmullRom: (v, k) ->
      m = v.length - 1
      f = m * k
      i = Math.floor(f)
      fn = Tween.Interpolation.Utils.CatmullRom
      if v[0] == v[m]
        if k < 0
          i = Math.floor(f = m * (1 + k))
        fn v[(i - 1 + m) % m], v[i], v[(i + 1) % m], v[(i + 2) % m], f - i
      else
        if k < 0
          return v[0] - (fn(v[0], v[0], v[1], v[1], -f) - v[0])
        if k > 1
          return v[m] - (fn(v[m], v[m], v[m - 1], v[m - 1], f - m) - v[m])
        fn v[if i then i - 1 else 0], v[i], v[if m < i + 1 then m else i + 1], v[if m < i + 2 then m else i + 2], f - i
    Utils:
      Linear: (p0, p1, t) ->
        (p1 - p0) * t + p0
      Bernstein: (n, i) ->
        fc = Tween.Interpolation.Utils.Factorial
        fc(n) / fc(i) / fc(n - i)
      Factorial: do ->
        a = [ 1 ]
        (n) ->
          s = 1
          i = undefined
          if a[n]
            return a[n]
          i = n
          while i > 1
            s *= i
            i--
          a[n] = s
      CatmullRom: (p0, p1, p2, p3, t) ->
        v0 = (p2 - p0) * 0.5
        v1 = (p3 - p1) * 0.5
        t2 = t * t
        t3 = t * t2
        (2 * p1 - 2 * p2 + v0 + v1) * t3 + (-3 * p1 + 3 * p2 - 2 * v0 - v1) * t2 + v0 * t + p1



# UMD (Universal Module Definition)
module.exports = Tween
window.Tween = Tween