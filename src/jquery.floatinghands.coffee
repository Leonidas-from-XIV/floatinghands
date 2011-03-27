# *jQuery Floating Hands Plugin*
#
# Written in 2011 by Marek Kubica <marek@xivilization.net>.

# define the wrapper function for jQuery
(($) ->
  # function that gets called to update the bitmap every n milliseconds
  onUpdate = (bitmap) -> () ->
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
  now = () ->
    new Date

  layerLoaded = (stage, layer) -> (event) ->
    image = event.target
    bitmap = new Bitmap(image)
    delete layer.image

    if !layer.z?
      # Z is default to 10, so it stays in the back
      layer.z = 10

    if layer.fn?
      bitmap.updateFn = layer.fn
      # hardcoded
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

  pusherLoaded = (stage, pusher) -> (event) ->
    image = event.target
    bitmap = new Bitmap(image)

    if !pusher.z?
      # Z is default to 10, so it stays in the back
      pusher.z = 10

    bitmap[key] = value for own key, value of pusher
    stage.addChild bitmap
    stage.sortChildren sortByZ

  initialize = (stage, onLoad) -> (element) ->
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

    e.onload = onLoad(stage, element) for e in images

  # define the plugin callback for jQuery
  jQuery.fn.floatinghands = (layers, pusher) ->
    # this is aliased to the DOM element that we hopefully got called upon
    widget = this[0]
    stage = new Stage(widget)

    $(widget).click (event) ->
      mouseX = event.clientX
      mouseY = event.clientY
      # beware, this only works non-locally
      item = stage.getObjectUnderPoint(mouseX, mouseY)
      console.log mouseX, mouseY
      if item?
        console.log item

    # add all images to the stage
    initLayer = initialize stage, layerLoaded
    initLayer element for element in layers
    initPusher = initialize stage, pusherLoaded
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
