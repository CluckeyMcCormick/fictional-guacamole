import multiprocessing as mp
import pyglet
import numpy

# Only need these two items from ctypes, and they come with prefixes
from ctypes import c_byte, c_bool

from game_state import LoadingStatus

from . import tile_cam, world

# Timed at 01:07 for a 512 x 512 (Dirty Start)
#MAX_SPRITES_MADE = 5000
# Timed at 01:07 for a 512 x 512 (Clean Start)
# Timed at 01:07 for a 512 x 512 (Dirty Start)
MAX_SPRITES_MADE = 1000

X_DEBUG = False
Y_DEBUG = False

"""
This is the load_chain, which is my backwards idea of a factory class/method.

Basically, the CityState schedules the first function in the chain. That
function then schedules the next function in the chain, and so on and so forth.

The advantage (that I currently percieve), is threefold:

1. Don't overload CityState
        With the loading chain, we don't have to put all of our loading code
        into the load function of CityState. Makes everything easier to
        maintain.

2. Separate functions are easier to understand & maintain
        The loading chain is (I desperately hope) fairly easy to follow. Each
        function handles a fairly simple process and SPECIFICALLY invokes the
        function that follows it.

3. Easier and repeatable scheduling 
        Separate functions allows us to reschedule whatever function as many
        times as we want. It allows us to track the current "stage" of the
        loading process without needing to defer to something like a STAGE
        variable.
"""

#
# Step One: Load the textures
#
def load_textures(dt, city_state):
    """
    Loads the various textures that city_state will need.
    """
    #
    if city_state.use16:
        file = pyglet.resource.file("terrain_sampler16.png")
    else:
        file = pyglet.resource.file("terrain_primary.png")

    # Load the image using the specified file.
    # For some reason, loading using pyglet.resource.image creates a pixel
    # bleed when we break up the image into an ImageGrid - even if atlas=False
    # So we grab the file first
    city_state.terrain_image = pyglet.image.load("terrain_primary.png", file=file)

    city_state.terrain_grid = pyglet.image.ImageGrid(
        city_state.terrain_image, rows=8, columns=1
    )

    pyglet.clock.schedule_once(start_build, 0, city_state)

#
# Step Two: Start the worldbuilding processes
#
def start_build(dt, city_state):
    """
    Divys up the world and starts the world painting process.
    """
    
    # Create the basic world items
    wd = world.data.WorldData(city_state.x_len, city_state.y_len)
    # Save them in city state
    city_state.world_data = wd

    # The sizes of each side of the CityState world
    sizes = (city_state.x_len, city_state.y_len)

    # Has the world been made yet?
    complete = mp.Value(c_bool, False)

    # The build process will need all of our raw arrays
    raw_arr = [
        wd.terrain_raw, 
        wd.detail_raw,
        wd.struct_raw, 
        wd.average_raw
    ]

    # The process that will manage the world building
    proc = mp.Process(
        target=world.maker.build_world, 
        args=(raw_arr, complete, sizes)
    )

    proc.start()

    # Schedules check_build
    pyglet.clock.schedule_once(check_build, 0, city_state, complete, proc)

#
# Step Three: Check whether the worldbuilding is done
#
def check_build(dt, city_state, complete, proc):
    """
    Checks the values in the [complete] array to see if our processes in the 
    [procs] array have finished. 
    """
    # Since complete is a multiprocessing Value object, we have to get the
    # value manually.
    if not complete.value:
        # If we aren't finished yet, reschedules itself
        pyglet.clock.schedule_once(
            check_build, 0, 
            city_state, complete, proc
        )
        return
    
    # Otherwise, joins the processes
    print("Joining!")
    proc.join()

    pyglet.clock.schedule_once(make_camera, 0, city_state)

#
# Step Four: Create the camera for the city_state
#
def make_camera(dt, city_state):
    """
    Create our camera and a sprite array to hold any sprites we'll be
    rendering.
    """
    mins = (0,0)
    if city_state.use16:
        tile_size = 16
    else:
        tile_size = 32
    maxs = (city_state.x_len, city_state.y_len)
    margin = 4
    city_state.view_offset_x = -32
    city_state.view_offset_y = -32
    view_x, view_y = city_state.window.get_size()
    print("view", view_x, view_y)
    view_area = (view_x + ( abs(city_state.view_offset_x) * 2), view_y + ( abs(city_state.view_offset_y) * 2))

    #view_start = (0, 0)

    city_state.camera = tile_cam.TileCamera(mins, maxs, view_area, margin, tile_size)

    # Create the empty tile array
    city_state.tile_sprites = [ [None for _ in range(city_state.y_len)] for _ in range(city_state.x_len)]

    # Schedules check_build
    pyglet.clock.schedule_once(sprite_build, 0, city_state)

#
# Step Five: Build the sprites
#
def sprite_build(dt, city_state, current=0):
    """
    Create our camera and a sprite array to hold any sprites we'll be
    rendering.

    "Current" is the current tile we're on. We convert this number into an x 
    and y value, which is the coordinates of the sprite we'll make.
    """
    maximum = city_state.x_len * city_state.y_len

    print(current)

    # For every tile number between the current tile and either
    # (current_tile + MAX_SPRITES) or maximum...
    for t_num in range( current, min( current + MAX_SPRITES_MADE,  maximum ) ):
        # Determine our x and y from the current tile
        x = t_num % city_state.x_len
        y = t_num // city_state.x_len
        
        choice_index = (city_state.world_data.terrain_shaped[x, y], 0)
        choice = city_state.terrain_grid[ choice_index ]

        sprite = None

        #if current < MAX_SPRITES_MADE:
            #print(x, y)

        if city_state.use16:
            sprite = pyglet.sprite.Sprite( choice,
                x=(x * 16) + city_state.view_offset_x,
                y=(y * 16) + city_state.view_offset_y,
                batch=city_state.batch
            )
        elif X_DEBUG:
            sprite = pyglet.text.Label( str(x), 
                x=(x * 32) + city_state.view_offset_x,
                y=(y * 32) + city_state.view_offset_y, 
                font_size=8, batch=city_state.batch
            )
        elif Y_DEBUG:
            sprite = pyglet.text.Label( str(y), 
                x=(x * 32) + city_state.view_offset_x,
                y=(y * 32) + city_state.view_offset_y, 
                font_size=8, batch=city_state.batch
            )
        else:
            sprite = pyglet.sprite.Sprite( choice, 
                x=(x * 32) + city_state.view_offset_x,
                y=(y * 32) + city_state.view_offset_y, 
                batch=city_state.batch
            )
            #print( "[%d, %d]" % (sprite.x, sprite.y) )

        city_state.tile_sprites[x][y] = sprite

    # If we still have more sprites to render...
    if current + MAX_SPRITES_MADE < maximum:
        # schedule ourselves again
        pyglet.clock.schedule_once(
            sprite_build, 0, 
            city_state, current=current+MAX_SPRITES_MADE
        )
    # Otherwise, we're done here.
    else:
        # Tell city state we're done loading.
        city_state.load_status = LoadingStatus.LOAD_COMPLETE
