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

  # TODO find a better way to solve this
  now = () ->
	  new Date

  imageLoaded = (stage, element) -> (event) ->
	  image = event.target
	  bitmap = new Bitmap(image)
	  delete element.image

	  if element.fn?
	    bitmap.updateFn = element.fn
	    # hardcoded
	    bitmap.timeFn = now
	    delete element.fn
	    # hardcoded
	    setInterval(onUpdate(bitmap), 1000)

	  # apply all options that were passed
	  bitmap[key] = value for own key, value of element
	  # put the object on the stage, thus making it visible
	  stage.addChild bitmap

  initialize = (stage) -> (element) ->
	  image = new Image()
	  image.src = element.image
	  image.onload = imageLoaded(stage, element)

  # define the plugin callback for jQuery
  jQuery.fn.floatinghands = (elements) ->
    # this is aliased to the DOM element that we hopefully got called upon
    widget = this[0]
    stage = new Stage(widget)

    # add all images to the stage
    init = initialize stage
    init element for element in elements

    # create an object so addListener has something to call on.
    listener =
	    tick: () ->
		    stage.update()

    Ticker.addListener listener

    # return 'this' so the plugin call can be chained
    this
)(jQuery)
