'use strict'

﻿# The tween class of Gotham
# This class animates objects of any format
# It features to reach deep proprerties in an object
# @example How to use
#    # Start
#    tweenTo =
#      scale:
#        x: 2
#        y: 2
#      rotation: 0.1
#
#    # End
#    tweenBack =
#      scale:
#        x: 1
#        y: 1
#      rotation: -0.1
#
#    tween = new Tween object
#    tween.startDelay 500
#    tween.repeat(Infinity)
#    tween.easing Tween.Easing.Circular.InOut
#    tween.to tweenTo, 1500
#    tween.to tweenBack, 1500
#    tween.onStart ->
#      console.log @ + " started!"
#    tween.start()
class Tween

  class ChainItem

    constructor: ->
      @property = null
      @duration = null
      @startTime = null
      @endTime = null
      @inited = false
      @type = null
      @next = null
      @previous = null
      @elapsed = 0




  # @property [Array[Tween]] List of current/ ongoing Tweens
  @_tweens = []

  # @property [Long] Current runtime time, Retreived from GameLoop's update()
  @_currentTime = 0


  # Initializes the Tween object
  # Does however not start the tween
  # Adds "this" tween to the Static tween array
  constructor: (object) ->

    # Object which are to be tweened
    @_object = object

    # Chain of tweens to be applied to object
    @_chain = []

    # Properties to tween
    @_properties = []




    @_easing = Tween.Easing.Linear.None
    @_interpolation = Tween.Interpolation.Linear

    # Callbacks
    @_onUpdate = null
    @_onComplete = null
    @_onStart = null

    # Options
    @_started = false
    @_complete = false
    @_lastTime = 0

    @_runCounter = 0
    @_remainingRuns = 1 # Remaining runs the tweet should do (default: 1 time) , Modified by .repeat(xx)



    Tween._tweens.push(@)

  # Retrieve "this" tween's TweenChain
  # @return [Array[Object]] The tween Chain
  getTweenChain: ->
    return @_chain


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

  # Starts the tween calling the _onStart callback
  start: ->
    @_started = true
    @_onStart(@_object)

  # Stops the tween calling the _onStop callback
  # TODO - Implement
  stop: ->
    @_started = false
    @_complete = true

  # Pauses the tween calling the _onPause callback
  # TODO - Implement
  pause: ->
    @_started = false

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

  # Set the easing algorithm for the tween
  # @param [Tween.Easing] easing The easing algorithm
  # @example How to use
  #   obj.easing(Tween.Easing.Linear.None)
  #
  # The easing algorithms are found in the Tween.Easing object.
  easing: (easing) ->
    @_easing = easing

  # Add tween action to the tween chain
  # @param [Object] property The "goal" property of the tween (Where you want the target object to end up)
  # @param [Long] duration Duration of the tween from start --> end (In milliseconds)
  to: (property, duration) ->

    # Add properties to the property list
    for prop in Tween.flattenKeys property
      @_properties.push(prop)

    newPath = new ChainItem()
    newPath.property = property # The Property to translate to
    newPath.duration = duration # Duration of the tween event
    newPath.startTime = null # Set when starting tween .start()
    newPath.endTime = null # Set when starting tween .start()
    newPath.inited = false
    newPath.type = "translate" # The type of the tweenEvent
    newPath.next = null
    newPath.previous = null
    newPath.elapsed = 0

    @addToChain newPath





  # Add a delay between two tween goto's
  # @param [Long] time Delay in Milliseconds
  delay: (time) ->

    if typeof time isnt 'number'
      throw new Error "Time was not a number!"

    delayItem =
      "duration" : time
      "startTime" : null # Set when starting tween .start()
      "endTime" : null # Set when starting tween .start()
      "type" : "delay"
      "previous": null
      "next": null

    @addToChain delayItem


  # How many times you want to repeat the Tween
  # To repeat "forever", use Infinity
  # @param [Integer] num Number of times to repeat
  repeat: (num) ->
    @_remainingRuns = num


  # TODO - Needs Documentation ??!?
  # @param [Object] property The property
  addCutsomProperty: (property) ->
    @_properties.push(property)

  # TODO - Needs Documentation ??!?
  # @param [Array[Object]] property The properties
  addCutsomProperties: (properties) ->
    for property in properties
      @addProperty(property)



############################################
##
## Callbacks
##
############################################

  # The onUpdate callback
  # Is called when the tween is updated
  # @param [Callback] callback The onUpdate callback
  onUpdate: (callback) ->
    @_onUpdate = callback

  # The onComplete callback
  # Is called when the tween is completed
  # @param [Callback] callback The onComplete callback
  onComplete: (callback) ->
    @_onComplete = callback

  # The onStart callback
  # Is called when the tween is started
  # @param [Callback] callback The onStart callback
  onStart: (callback) ->
    @_onStart = callback

  # Update loop of the tween engine ensures that tweening actually happens
  # IT is called from GameLoop.update()
  # @param [Long] Render runtime in milliseconds
  @update: (time) ->
    Gotham.Tween._currentTime = time

    # Return if no tweens
    if Tween._tweens.length <= 0
      return

    # Iterate through each of the tweens
    for tween in Tween._tweens

      # Because we delete directly from _tweens array, it may iterate over a undefined node (if previous was deleted. This causes undefined tween. But IGNORE it)
      if not tween
        continue

      # Continue if tween is paused
      if not tween._started
        continue

      # Continue if tween is not yet started
      if time < tween._startTime
        continue

      # Continue and remove if tween is complete
      if tween._complete
        tween._onComplete(tween._object)
        Tween._tweens.remove(tween)
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

        if chainItem.type == "delay"
          break

        chainItem.startPos = {}

        for property in tween._properties
          key = property.split('.')[0]
          value = tween._object[key]

          chainItem.startPos[key] = if typeof value == 'object' then $.extend(false, {}, value) else value

      if time > chainItem.endTime

        # Increment run counter
        tween._runCounter++

        # Reset chainItem data
        chainItem.startTime = null
        chainItem.endTime = null
        chainItem.inited = false


        # Decrement remaining runs by 1
        if tween._runCounter %% tween._chain.length == 0
          tween._remainingRuns -= 1

        continue


      # If chainItem type is a delay
        if chainItem.type == "delay"
          continue


      # Elapsed Time of the tween
      startTime = chainItem.startTime
      endTime = startTime + chainItem.duration

      # Start and end of the tween
      start = chainItem.startPos
      end = chainItem.property

      # The elapsed time of the tween
      elapsed = (performance.now() - startTime) / chainItem.duration
      chainItem.elapsed = elapsed
      elapsed = if elapsed > 1 then  1 else elapsed

      # Calculate the new multiplication value
      value = tween._easing elapsed

      for prop in tween._properties
        nextPos = (Tween.resolve(start, prop) + (Tween.resolve(end, prop) - Tween.resolve(start, prop)) * value)
        Tween.resolve(tween._object, prop, null, nextPos)

        #eval("tween._object.#{prop} = start.#{prop} +  ( end.#{prop} - start.#{prop} ) * #{value}")


  Tween.translate: (tween, chainItem) ->


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


  # Function for finding properties recursively in an Object
  # @param [Object] obj Start/Parent Node
  # @param [String] delimiter The Delimeter of the result. Default: "."
  # @param [Integer] max_depth Max Depth of the recursion
  # @return [Array] Array with the resulting properties
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

  # Easing Algorithms
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





















module.exports = Tween