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

  layerLoaded = (stage, layer) -> (event) ->
    image = event.target
    bitmap = new Bitmap(image)
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
      updaterFn = onUpdate(bitmap)
      # call it once, so we start with the newest coordinates
      updaterFn()
      # add the bitmap to the Ticker so it recalculates every tick
      recalculateRotation =
        tick: updaterFn
      Ticker.addListener recalculateRotation

    # deactivate mouse events on layers, because they are not clickable
    bitmap.mouseEnabled = false
    # put the object on the stage, thus making it visible
    stage.addChild bitmap
    # sort the list of children by the Z index, otherwise the order
    # will be determined by the time the image is loaded
    stage.sortChildren sortByZ

  pusherLoaded = (stage, pusher) -> (event) ->
    image = event.target
    bitmap = new Bitmap image
    delete pusher.image

    if !pusher.z?
      # Z is default to 10, so it stays in the back
      pusher.z = 10

    bitmap[key] = value for own key, value of pusher
    stage.addChild bitmap
    stage.sortChildren sortByZ

  initialize = (stage, onLoad) -> (element) ->
    if element.image?
      image = new Image
      image.src = element.image
      image.onload = onLoad stage, element
    if element.normal?
      image = new Image
      image.src = element.normal.image
      image.onload = onLoad stage, element.normal
    if element.pressed?
      image = new Image
      image.src = element.pressed.image
      image.onload = onLoad stage, element.pressed

  initButton = (stage) -> (element) ->
    callback = element.pushed
    button = $ '<button>'
    button.click callback
    $(stage.canvas).before button


  objectOnPoint = (hotspots, x, y) ->
    for key, obj of hotspots
      # need to convert these out of a string, because JS dictionaries are a joke
      [x1, y1, x2, y2] = (parseInt(n, 10) for n in key.split(','))

      if x1 <= x <= x2 and y1 <= y <= y2
        return obj

  updateElements = ->
    stage = this
    for element in stage.children
      if element.updateFn?
        onUpdate(element)()

  class Stopwatch
    constructor: ->
      @running = false
      @frozen = false
      @frozenAt = 0
      @zero = new Date()
      @difference = 0
      @offset = 0

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
    attach: => attach.apply(this, arguments)
    Stopwatch: Stopwatch

  attach = (layers, pusher) ->
    # bail out early if the browser does not support canvas
    if !Modernizr.canvas
      return this

    # get the <img> and harvest it for width and height and replace by canvas
    candidate = $(this[0])
    width = candidate.width()
    height = candidate.height()
    # we set the attribute on the element and not using jquery, because
    # it needs to be an attribute and not CSS
    canvas = $('<canvas>').width('width', width).attr('height', height)
    canvas.attr('id', candidate.attr('id')) if candidate.attr('id')
    candidate.replaceWith canvas
    widget = canvas[0]

    # if Explorer Canvas was loaded, run it on our newly created element
    G_vmlCanvasManager?.initElement widget

    # we got a canvas, start initialization
    stage = new Stage(widget)
    # extend the stage with helpers
    stage.updateElements = updateElements

    hotspots = {}
    # list of items that were punched in in the mouse handlers
    pressedItems = []

    $(widget).mousedown (event) ->
      mouseX = event.pageX - $(widget).offset().left
      mouseY = event.pageY - $(widget).offset().top

      item = objectOnPoint(hotspots, mouseX, mouseY)
      if item?
        # call callback if defined
        if item.pushed?
          item.pushed()
          # update all elements of the canvas, so the update is visible immediately
          stage.updateElements()

        # mark the item as pressed
        pressedItems.push item
        # make the upper layer invisible
        item.visible = false
        stage.update()

    $(widget).mouseup (event) ->
      # 'pop out' all hidden items
      if pressedItems.length != 0
        while pressed = pressedItems.pop()
          pressed.visible = true
        stage.update()

      mouseX = event.pageX - $(widget).offset().left
      mouseY = event.pageY - $(widget).offset().top

      item = objectOnPoint(hotspots, mouseX, mouseY)
      if item?
        # re-display stage immediately
        stage.update()

    $(widget).mousemove (event) ->
      mouseX = event.pageX - $(widget).offset().left
      mouseY = event.pageY - $(widget).offset().top
      #console.log mouseX, mouseY

      item = objectOnPoint(hotspots, mouseX, mouseY)
      style = 'auto'
      if item?
        style = 'pointer'
      $(this).css('cursor', style)

    # add all images to the stage
    initButton(stage) element for element in pusher
    initLayer = initialize stage, layerLoaded
    initLayer element for element in layers
    initPusher = initialize stage, pusherLoaded
    initPusher element for element in pusher

    # create an object so addListener has something to call on.
    listener =
      tick: () ->
        stage.update()

    # adjust ticks / FPS at will
    Ticker.setInterval 125
    Ticker.addListener listener

    # return 'this' so the plugin call can be chained
    this
)(jQuery)
