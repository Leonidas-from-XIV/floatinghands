# *jQuery Floating Hands Plugin*
#
# Written in 2011 by Marek Kubica <marek@xivilization.net>.

# define the wrapper function for jQuery
(($) ->
  image_loaded = (event) ->
	  image = event.target
	  background = new Bitmap(image)
	  background.x = 0
	  background.y = 0
	  background.rotation = 360
	  background.regX = 100
	  background.regY = 50
	  background.scaleX = background.scaleY = background.scale = 1

	  container = new Container()
	  stage = $("canvas").data("stage")
	  console.log stage
	  console.log background
	  stage.addChild container
	  container.addChild background

  # define the plugin callback for jQuery
  jQuery.fn.floatinghands = () ->
    # this is aliased to the DOM element that we hopefully got called upon
    widget = this[0]
    stage = new Stage(widget)
    stage.autoClear = false
    $(widget).data('stage', stage)

    background_image = new Image()
    background_image.src = "case.png"
    #background_image.onload = image_loaded

    text = new Text("bla", "serif", "black")
    text.x = 100
    text.y = 50
    stage.addChild text

    listener =
	    tick: stage.update

    Ticker.addListener listener

    return undefined
)(jQuery)
