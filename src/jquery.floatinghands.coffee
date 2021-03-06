###
*jQuery Floating Hands Plugin*

Written in 2011 by Marek Kubica <marek@xivilization.net>.

See https://github.com/Leonidas-from-XIV/floatinghands for details.
###

# define the wrapper function for jQuery
(($) ->
  # function that gets called to update the bitmap every n milliseconds
  # yes, this is a curried function returning a unary function
  onUpdate = (bitmap) -> ->
    # calculate the degree by passing the function to the degree calculator
    # function and set this degree
    bitmap.rotation = bitmap.updateFn bitmap.timeFn
    # return `true` so it will be called again
    true

  # comparison function that sorts elements based on their z attribute in
  # descending order
  sortByZ = (first, second) ->
    second.z - first.z

  ###
  a function that provides the number of milliseconds passed since
  midnight today (rather than 1970/01/01 midnight). For that, we subtract
  create a date that is today 0:00 and subtract it from the current date.
  ###
  now = ->
    atm = new Date()
    atm.getTime() - new Date(atm.getFullYear(), atm.getMonth(), atm.getDay()).getTime()

  layerLoaded = (stage, layer) -> (event) ->
    image = event.target
    bitmap = new Bitmap image
    delete layer.image

    if !layer.z?
      # Z is default to 10, so it stays in the back
      layer.z = 10

    # apply all options that were passed
    bitmap[key] = value for own key, value of layer

    if bitmap.updateFn?
      # if not specified differently, use `now` as time source
      if !bitmap.timeFn?
        bitmap.timeFn = now
      # get the specialized updater function
      updaterFn = onUpdate bitmap
      # call it once, so we start with the newest coordinates
      updaterFn()
      # add the bitmap to the Ticker so it recalculates every tick
      Ticker.addListener tick: updaterFn

    # deactivate mouse events on layers, because they are not clickable
    bitmap.mouseEnabled = false
    # put the object on the stage, thus making it visible
    stage.addChild bitmap
    # sort the list of children by the Z index, otherwise the order
    # will be determined by the time the image is loaded
    stage.sortChildren sortByZ

  pusherLoaded = (stage, layer, extra) -> (event) ->
    image = event.target
    bitmap = new Bitmap image
    delete layer.image

    if !layer.z?
      # Z is default to 10, so it stays in the back
      layer.z = 10

    bitmap[key] = value for own key, value of layer

    if extra.button?
      extra.button.data(extra.type, bitmap)

    stage.addChild bitmap
    stage.sortChildren sortByZ

  initialize = (stage, onLoad) -> (element) ->
    image = new Image
    image.src = element.image
    image.onload = onLoad stage, element

  initButton = (stage) -> (element) ->
    callback = element.pushed
    [x1, y1, x2, y2] = element.hotspot
    button = $ '<button>'
    button.mousedown (event) ->
      button.data('normal').visible = false
      stage.update()
      callback event
    button.mouseup (event) ->
      button.data('normal').visible = true
      stage.update()

    button.css
      display: 'block'
      position: 'absolute'
      left: x1
      top: y1
      width: x2 - x1
      height: y2 - y1
      border: 'none'
      outline: 'none'
      cursor: 'pointer'
      background: 'rgba(0, 0, 0, 0)'
    $(stage.canvas).after button

    if element.normal?
      image = new Image
      image.src = element.normal.image
      image.onload = pusherLoaded stage, element.normal, button: button, type: 'normal'
    if element.pressed?
      image = new Image
      image.src = element.pressed.image
      image.onload = pusherLoaded stage, element.pressed, button: button, type: 'pressed'

  updateElements = ->
    stage = this
    for element in stage.children
      if element.updateFn?
        onUpdate(element)()

  class LocalStorage
    getLS: (key) =>
      localStorage.getItem key

    getCookie: (key) =>
      document.cookie

    get: =>
      if Modernizr.localstorage
        @getLS this, arguments
      else
        @getCookie this, arguments

    setLS: (key, value) =>
      localStorage.setItem key, value

    setCookie: (key, value) =>
      date = new Date();
      date.setTime date.getTime() + 356 * 24 * 60 * 60 * 1000
      expires = "; expires=" + date.toGMTString()
      document.cookie = key + "=" + value + expires + "; path=/"

    set: =>
      if Modernizr.localStorage
        @setLS this, arguments
      else
        @setCookie this, arguments

  class Stopwatch
    constructor: (slot) ->
      @slot = slot
      @running = false
      @frozen = false
      @frozenAt = 0
      @zero = new Date()
      @difference = 0
      @offset = 0
      @storage = new LocalStorage()
      @loadState()

    loadState: =>
      # TODO local storage
      val = @storage.get @slot
      console.log val
      @saveState()

    saveState: =>
      # TODO convert to JSON and save
      val = JSON.stringify
        running: @running
        frozen: @frozen
        frozenAt: @frozenAt
        zero: @zero
        difference: @difference
        offset: @offset

      console.log val
      console.log @storage.set
      @storage.set @slot, val
      console.log jQuery.parseJSON val

    toggleFreeze: =>
      if @running
        # save the current value as snapshot for later use
        @frozenAt = @offset + @difference
        @frozen = !@frozen
      else
        # reset all counters
        @frozenAt = @difference = @offset = 0
        @frozen = false

    toggleRun: =>
      if !@running
        #console.log "stopwatch got started"
        # started = new zero point
        @zero = new Date()
      else
        #console.log "stopwatch got halted"
        # add the difference from zero to now to the offset and reset
        # the difference
        @offset = @offset + @difference
        @difference = 0

      @running = !@running

    timeFn: =>
      #console.log "difference", @difference, "offset", @offset
      # if we are not running, we don't need to calculate differences
      if !@running
        return @offset + @difference

      # calculate the new difference
      current = new Date()
      @difference = current.getTime() - @zero.getTime()

      # if we're frozen, return the old value
      if @frozen
        return @frozenAt

      # otherwise we return the new value
      @offset + @difference

  # define the plugin callback for jQuery
  jQuery.fn.floatinghands = ->
    attach: => attach.apply this, arguments
    Stopwatch: Stopwatch
    makeTimeFn: => makeTimeFn.apply this, arguments

  makeTimeFn = (args) ->
    ###
    this is a function that can return a timeFunction based on certain
    arguments passed.
    'total' means the number of milliseconds that is represented by a full
      rotation of a hand.
    'step' means how often a hand is supposed to be updated.
    ###
    (timeFn) ->
      Math.floor(timeFn() / args.step) * args.step % args.total / args.total * 360

  attach = (layers, pusher) ->
    # bail out early if the browser does not support canvas
    if !Modernizr.canvas
      return this

    # get the <img> and harvest it for width and height and replace by canvas
    candidate = $ this[0]
    # we set the attribute on the element and not using jquery, because
    # it needs to be an attribute and not CSS
    canvas = $('<canvas>').attr width: candidate.width(), height: candidate.height()
    div = $ '<div>'
    (div.attr id: originalId) if originalId = candidate.attr 'id'
    div.append canvas
    candidate.replaceWith div
    widget = canvas[0]

    # if Explorer Canvas was loaded, run it on our newly created element
    G_vmlCanvasManager?.initElement widget

    # we got a canvas, start initialization
    stage = new Stage widget
    # extend the stage with helpers
    stage.updateElements = updateElements

    # add all images to the stage
    initButton(stage) element for element in pusher
    initLayer = initialize stage, layerLoaded
    initLayer element for element in layers

    # adjust ticks / FPS at will
    Ticker.setInterval 125
    Ticker.addListener tick: -> stage.update()

    # return 'this' so the plugin call can be chained
    this
)(jQuery)
