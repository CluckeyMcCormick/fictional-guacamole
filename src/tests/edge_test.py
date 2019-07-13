
import random

import pyglet
from pyglet import gl

import load_screens 
import city

from city.world.assets.terrain_primary import PrimaryKey

def random_checkerboard(world_data, orders, tile_set):

    _, y_size = world_data.sizes
    first, limit = orders

    choice_list = [
        PrimaryKey.SNOW,
        PrimaryKey.GRASS,
        PrimaryKey.DIRT,
        PrimaryKey.SAND,
        PrimaryKey.STONE,
        PrimaryKey.ICE,
        PrimaryKey.WATER,
    ]

    for x in range(first, limit):
        for y in range(y_size):

            # Create a string to seed from
            seed_string =  "{0},{1}".format( x//5, y//5 )
            random.seed(seed_string)

            choice = random.choice( choice_list )
            designate = tile_set.get_designate(choice)

            # Set the current tile to the closest point type
            world_data.base[x, y] = designate

def limited_stochastic(world_data, orders, tile_set):
    _, y_size = world_data.sizes
    first, limit = orders

    choice_list = [
        PrimaryKey.SNOW,
        PrimaryKey.GRASS,
        PrimaryKey.DIRT,
        PrimaryKey.SAND,
        PrimaryKey.STONE,
        PrimaryKey.ICE,
        PrimaryKey.WATER,
    ]

    for x in range(first, limit):
        for y in range(y_size):
            choice = random.choice( choice_list )
            designate = tile_set.get_designate(choice)

            # Set the current tile to the closest point type
            world_data.base[x, y] = designate

def make_checkerboard_world(world_data, complete_val, primary_ts, detail_ts):
    """
    The build_world function is our main building algorithm. It's main role is
    in deciding what arguments to pass to our world painting methods and what
    order to call them in.
    """
    print("\n\tPainting the checkerboard world..\n\n")
    kw_args = {
        "tile_set" : primary_ts
    }
    city.world.maker.perform_spatial_work(
        random_checkerboard, world_data, 
        kw_args=kw_args
    )

    print("\n\tAssigning averages...\n\n")
    city.world.paint.average.assign_averages(world_data)

    print("\n\tPerforming the ever important edge pass...\n\n")

    kw_args = {
        "world_ts" : primary_ts, "detail_ts" : detail_ts, 
    }
    city.world.maker.perform_spatial_work(
        city.world.paint.edge.edge_pass, world_data, 
        kw_args=kw_args
    )

    # Since this a mp.Value object, we have to manually change 
    # the Value.value's value. Ooof.
    complete_val.value = True

current_state = None

def run():
    
    global current_state

    window = pyglet.window.Window(width=1000, height=600)

    # Set where we'll be loading assets from
    pyglet.resource.path.append('@city.world.assets')
    pyglet.resource.path.append('@load_screens.assets')
    pyglet.resource.reindex()

    # Make sure the window is ready to handle switch state events
    window.register_event_type('switch_state')

    current_state = load_screens.CircleLoadScreen(
        window, city.city_state.CityState(
            window, 40, 40, world_maker=make_checkerboard_world
        )
    )

    @window.event
    def switch_state(new_state):

        # Ensure we are changing the correct state
        global current_state

        # Stop the current state
        current_state.stop()
        current_state._stop()
        # Switch to a new state
        current_state = new_state
        # Start the new state
        current_state._start()
        current_state.start()

    current_state._start()
    current_state.start()
    pyglet.app.run()