import multiprocessing as mp
import pyglet
import numpy

# Only need these two items from ctypes, and they come with prefixes
from ctypes import c_byte, c_bool

from game_state import LoadingStatus

from . import tile_cam, world
from .world.assets.terrain_detail import DetailKey
import game_util

# Timed at 01:07 for a 512 x 512 (Dirty Start)
#MAX_SPRITES_MADE = 5000
# Timed at 01:07 for a 512 x 512 (Clean Start)
# Timed at 01:07 for a 512 x 512 (Dirty Start)
MAX_SPRITES_MADE = 1000

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
def load_textures(dt, city_state, world_maker):
    """
    Loads the various textures that city_state will need.
    """

    # Get the load methods for our tile sheets
    primary_load = world.assets.terrain_primary.load
    detail_load = world.assets.terrain_detail.load
    river_load = world.assets.river_dir.load

    # Create the TileSet objects
    city_state.terrain_primary = world.tile_set.TileSet(primary_load, river_load)
    city_state.terrain_detail = world.tile_set.TileSet(detail_load)

    pyglet.clock.schedule_once(start_build, 0, city_state, world_maker)

#
# Step Two: Start the worldbuilding processes
#
def start_build(dt, city_state, world_maker):
    """
    Divys up the world and starts the world painting process.
    """
    
    # Create the basic world items
    wd = world.data.WorldData(city_state.x_len, city_state.y_len)
    # Save them in city state
    city_state.world_data = wd

    # Has the world been made yet?
    complete = mp.Value(c_bool, False)

    # Get the primary tileset
    primary_ts = city_state.terrain_primary.get_picklable()

    # Get the secondary tileset
    detail_ts = city_state.terrain_detail.get_picklable()

    # The process that will manage the world building
    proc = mp.Process(
        target=world_maker, 
        args=(wd.get_picklable(), complete, primary_ts, detail_ts)
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

    # Create the empty average array
    city_state.average_sprites = [ [None for _ in range(city_state.y_len // world.data.AVERAGE_ZONE_LEN)] for _ in range(city_state.x_len // world.data.AVERAGE_ZONE_LEN)]
    # Create the empty tile array
    city_state.world_sprites = [ [None for _ in range(city_state.y_len)] for _ in range(city_state.x_len)]
    # Create the empty detail array
    city_state.detail_sprites = [ [None for _ in range(city_state.y_len * 2)] for _ in range(city_state.x_len * 2)]
    # Create our texture groups dict
    city_state.texture_groups = {}

    # Schedules the average sprite building
    pyglet.clock.schedule_once(average_sprite_build, 0, city_state)

#
# Step Five: Build the "average" wide-sprites
#
def average_sprite_build(dt, city_state):

    x_len, y_len = city_state.world_data.sizes
    avg_x_len = x_len // world.data.AVERAGE_ZONE_LEN
    avg_y_len = y_len // world.data.AVERAGE_ZONE_LEN

    avg_tile_size = 32 * world.data.AVERAGE_ZONE_LEN

    for avg_x in range(avg_x_len):
        for avg_y in range(avg_y_len):

            designate = city_state.world_data.base_average[avg_x, avg_y]
            choice_enum = city_state.terrain_primary.get_enum(designate)

            if choice_enum not in city_state.texture_groups:
                choice_image = city_state.terrain_primary.get_image(designate)
                city_state.texture_groups[choice_enum] = game_util.tiles.TileGroup(
                    texture=choice_image.get_texture()
                )

            texture_group = city_state.texture_groups[choice_enum]

            sprite_x = (avg_x * avg_tile_size) + city_state.view_offset_x
            sprite_y = (avg_y * avg_tile_size) + city_state.view_offset_y

            sprite = game_util.tiles.SizableTile(
                pos=(sprite_x, sprite_y),
                sizes=(avg_tile_size, avg_tile_size), 
                tex_group=texture_group, 
                batch=city_state.average_batch
            )

            city_state.average_sprites[avg_x][avg_y] = sprite            

    # Schedules check_build
    pyglet.clock.schedule_once(world_sprite_build, 0, city_state)

#
# Step Six: Build the sprites, per tile
#
def world_sprite_build(dt, city_state, current=0):
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
        
        designate = city_state.world_data.base[x, y]
        choice_enum = city_state.terrain_primary.get_enum(designate)

        avg_x = x // world.data.AVERAGE_ZONE_LEN
        avg_y = y // world.data.AVERAGE_ZONE_LEN

        avg_designate = city_state.world_data.base_average[avg_x, avg_y]

        if avg_designate != designate:
            if choice_enum not in city_state.texture_groups:
                choice_image = city_state.terrain_primary.get_image(designate)
                city_state.texture_groups[choice_enum] = game_util.tiles.TileGroup(
                    texture=choice_image.get_texture()
                )

            texture_group = city_state.texture_groups[choice_enum]

            sprite_x = (x * 32) + city_state.view_offset_x
            sprite_y = (y * 32) + city_state.view_offset_y

            sprite = game_util.tiles.SimpleTile(
                pos=(sprite_x, sprite_y), 
                tex_group=texture_group, 
                batch=city_state.world_batch
            )

            city_state.world_sprites[x][y] = sprite

        det_x = x * 2
        det_y = y * 2

        for i in range(4):
            x_adj = i % 2
            y_adj = i // 2

            designate = city_state.world_data.detail[x * 2 + x_adj, y * 2 + y_adj]

            choice_enum = city_state.terrain_detail.get_enum(designate)
            # If it's the blank option, skip!
            if choice_enum == DetailKey.NONE:
                continue

            if choice_enum not in city_state.texture_groups:
                choice_image = city_state.terrain_detail.get_image(designate)
                city_state.texture_groups[choice_enum] = game_util.tiles.TileGroup(
                    texture=choice_image.get_texture()
                )

            texture_group = city_state.texture_groups[choice_enum]

            sprite_x = int(((det_x + x_adj) * 16) + city_state.view_offset_x)
            sprite_y = int(((det_y + y_adj) * 16) + city_state.view_offset_y)

            sprite = game_util.tiles.SimpleTile(
                pos=(sprite_x, sprite_y), 
                tex_group=texture_group, 
                batch=city_state.detail_batch
            )

            city_state.detail_sprites[det_x + x_adj][det_y + y_adj] = sprite


    # If we still have more sprites to render...
    if current + MAX_SPRITES_MADE < maximum:
        # schedule ourselves again
        pyglet.clock.schedule_once(
            world_sprite_build, 0, 
            city_state, current=current+MAX_SPRITES_MADE
        )
    # Otherwise, we're done here.
    else:
        # Tell city state we're done loading.
        city_state.load_status = LoadingStatus.LOAD_COMPLETE
