import multiprocessing as mp
import pyglet
import numpy

# Only need these two items from ctypes, and they come with prefixes
from ctypes import c_byte, c_bool

from game_state import LoadingStatus
from . import tile_cam, world_maker, world_data

DEFAULT_WORKERS = 8
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
    if city_state.use16:
        city_state.terrain_image = pyglet.image.load('terrain_sampler16.png')
    else:
        city_state.terrain_image = pyglet.image.load('terrain_sampler32.png')

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
    workers = DEFAULT_WORKERS
    
    city_state.world_data = world_data.WorldData(city_state.x_len, city_state.y_len)

    # Starts the worker processes for building the world
    complete = [ mp.Value(c_bool, False) for _ in range(workers) ]
    procs = [None for _ in range(workers)]

    # How many x-columns will each process be responsible for?
    x_step = city_state.x_len // workers
    # What's the size of the world?
    sizes = (city_state.x_len, city_state.y_len)

    # For each worker process
    for i in range(workers):
        # If we're on the last iteration, do last
        if i == workers - 1:
            orders = (x_step * i, city_state.x_len)
        # Otherwise, divy up the world
        else:
            orders = (x_step * i, x_step * (i + 1))

        p = mp.Process(
            target=world_maker.build_world, 
            args=(city_state.world_data.terrain_raw, complete[i], orders, sizes)
        )
        # Store the process
        procs[i] = p

        p.start()

    # Schedules check_build
    pyglet.clock.schedule_once(check_build, 0, city_state, complete, procs)

#
# Step Three: Check whether the worldbuilding is done
#
def check_build(dt, city_state, complete, procs):
    """
    Checks the values in the [complete] array to see if our processes in the 
    [procs] array have finished. 
    """
    # Checks each worker process to see if we're finished
    for val in complete:
        if not val:
            # If we aren't, reschedules itself
            pyglet.clock.schedule_once(
                check_build, 0, 
                city_state, complete, procs
            )
            return
    # Otherwise, joins the processes
    for p in procs:
        p.join()

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
