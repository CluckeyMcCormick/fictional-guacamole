extends Control

# This our background loader. This is the thing we'll be using and referring to
# for loading purposes
var _bg_loader
# The current path we're trying to load. Mostly used when things go wrong.
var _current_load_path

# Signal issued when loading is complete. Provides the resource loaded (should
# be a scene if you're using this right) and the path originally provided for
# loading.
signal loading_complete(resource, path)
# Signal issued when loading fails due to an error. Provides the resource path
# we were TRYING to load.
signal loading_failed(path)

func _ready():
    # Set-up our tween to spin the circle. We ain't tweening yet, but we'll be
    # ready whenever we do
    $Tween.interpolate_property($VBoxContainer/Circle, "rect_rotation",
        0, 360, 1,
        Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
    )
    # We currently don't have a _bg_loader. Set it to null so our processing
    # doesn't go awry.
    _bg_loader = null
    _current_load_path = null

func _process(delta):
    # If we don't have a background loader, back out!
    if _bg_loader == null:
        return
    
    # Otherwise, poll the loader.
    var err = _bg_loader.poll()

    # If we finished loading...
    if err == ERR_FILE_EOF:
        # Stop the tween
        $Tween.stop_all()
        # Get our resource
        var new_res = _bg_loader.get_resource()
        # Invalidate our loader - we're done with it.
        _bg_loader = null
        # Tell everyone who's listening that we did it!
        emit_signal("loading_complete", new_res, _current_load_path)
        # And that's it! Whatever comes next is up to whoever is
        # listening...
        
    # Otherwise, if we're still loading...
    elif err == OK:
        # Then we need to update our progress bar! First, calculate the
        # percent complete.
        var progress = float(_bg_loader.get_stage()) / _bg_loader.get_stage_count()
        # Now set the completion
        $VBoxContainer/ProgressBar.value = progress * 100
        
    # Otherwise, an error must have occurred. That's bad... cancel the loading
    # and send the signal to whoever is listening.
    else:
        # Stop the tween
        $Tween.stop_all()
        # Invalidate the loader
        _bg_loader = null
        # Tell whoever is out there
        emit_signal("loading_failed", _current_load_path)

func initiate_scene_load(scene_path_load):    
    # Load the provided path
    _bg_loader = ResourceLoader.load_interactive(scene_path_load)
    
    # If we got an error, _bg_loader will be null. Let's send a signal out, so
    # whoever is out there knows
    if _bg_loader == null: # Check for errors.
        emit_signal("loading_failed", scene_path_load)
        return
    
    # This new path is now our current load path!
    _current_load_path = scene_path_load
    
    # Start the tween!
    $Tween.start()
