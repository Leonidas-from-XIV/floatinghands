# *jQuery Floating Hands Plugin*
#
# Written in 2011 by Marek Kubica <marek@xivilization.net>.

# define the wrapper function for jQuery
(($) ->
  # function that gets called to update the bitmap every n milliseconds
  # yes, this is a curried function returning a unary function
  onUpdate = (bitmap) -> ->
    # calculate the degree by passing the function to the degree calculator
    # function and set this degree
    bitmap.rotation = bitmap.updateFn(bitmap.timeFn)
    # return `true` so it will be called again
    true

  # comparison function that sorts elements based on their z attribute in
  # descending order
  sortByZ = (first, second) ->
    second.z - first.z

  # TODO find a better way to solve this
  now = ->
    new Date

  layerLoaded = (stage, layer, hotspots) -> (event) ->
    image = event.target
    bitmap = new Bitmap(image)
    delete layer.image

    if !layer.z?
      # Z is default to 10, so it stays in the back
      layer.z = 10

    if layer.fn?
      bitmap.updateFn = layer.fn
      # if not specified differently, use `now` as time source
      bitmap.timeFn = now
      delete layer.fn
      # add the bitmap to the Ticker so it recalculates every tick
      recalculateRotation =
        tick: onUpdate(bitmap)
      Ticker.addListener recalculateRotation

    # apply all options that were passed
    bitmap[key] = value for own key, value of layer
    # deactivate mouse events on layers, because they are not clickable
    bitmap.mouseEnabled = false
    # put the object on the stage, thus making it visible
    stage.addChild bitmap
    # sort the list of children by the Z index, otherwise the order
    # will be determined by the time the image is loaded
    stage.sortChildren sortByZ

  pusherLoaded = (stage, pusher, hotspots) -> (event) ->
    image = event.target
    bitmap = new Bitmap(image)

    if !pusher.z?
      # Z is default to 10, so it stays in the back
      pusher.z = 10

    if pusher.hotspot?
      hotspots[pusher.hotspot] = bitmap
      delete pusher.hotspot

    bitmap[key] = value for own key, value of pusher
    stage.addChild bitmap
    stage.sortChildren sortByZ

  initialize = (stage, onLoad, hotspots) -> (element) ->
    images = []
    if element.image?
      image = new Image
      image.src = element.image
      images.push image
    if element.normal?
      image = new Image
      image.src = element.normal
      images.push image
    if element.pushed?
      image = new Image
      image.src = element.pushed
      images.push image

    e.onload = onLoad(stage, element, hotspots) for e in images

  objectOnPoint = (hotspots, x, y) ->
    for key, obj of hotspots
      # need to convert these out of a string, because JS dictionaries are a joke
      [x1, y1, x2, y2] = (parseInt(n, 10) for n in key.split(','))

      if x1 <= x <= x2 and y1 <= y <= y2
        return obj

  class Stopwatch
    constructor: ->
      @running = false
      @zero = new Date()
    toggleFreeze: =>
      console.log "toggling freeze"
    toggleRun: =>
      if !@running
        console.log "starting counter"
    timeFn: =>
      # TODO logic
      current = new Date()
      current.getTime() - @zero.getTime()

  # define the plugin callback for jQuery
  jQuery.fn.floatinghands = ->
    attach: => attach.apply(this, arguments)
    Stopwatch: Stopwatch

  attach = (layers, pusher) ->
    # bail out early if the browser does not support canvas
    if !Modernizr.canvas
      return this

    # get the <img> and harvest it for width and height and replace by canvas
    candidate = $(this[0])
    width = candidate.attr 'width'
    height = candidate.attr 'height'
    canvas = $('<canvas>').attr('width', width).attr('height', height)
    candidate.replaceWith canvas
    widget = canvas[0]

    # we got a canvas, start initialization
    stage = new Stage(widget)

    hotspots = {}

    $(widget).click (event) ->
      mouseX = event.clientX
      mouseY = event.clientY

      item = objectOnPoint(hotspots, mouseX, mouseY)
      if item?
        # make the upper layer invisible
        item.visible = false
        # call callback if defined
        item.pushed?()
        # re-display stage immediately
        stage.update()

        # schedule the visible-making
        setTimeout(() ->
          item.visible = true
          stage.update()
        50)

    $(widget).mousemove (event) ->
      mouseX = event.clientX
      mouseY = event.clientY
      #console.log mouseX, mouseY

      item = objectOnPoint(hotspots, mouseX, mouseY)
      style = 'auto'
      if item?
        style = 'pointer'
      $(this).css('cursor', style)

    # add all images to the stage
    initLayer = initialize stage, layerLoaded, hotspots
    initLayer element for element in layers
    initPusher = initialize stage, pusherLoaded, hotspots
    initPusher element for element in pusher

    # create an object so addListener has something to call on.
    listener =
      tick: () ->
        stage.update()

    # adjust ticks / FPS at will
    Ticker.setInterval 1000
    Ticker.addListener listener

    # return 'this' so the plugin call can be chained
    this
)(jQuery)
