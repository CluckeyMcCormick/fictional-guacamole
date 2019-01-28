
import pyglet
import random
import numpy
from ctypes import c_byte

import game_state

from . import tile_cam, load_chain

WORKERS = 8

X_DEBUG = False #True
Y_DEBUG = False #True

class CityState(game_state.GameState):

    def __init__(self, window, x_len, y_len, use16=False):
        super(CityState, self).__init__(window)
        self.batch = pyglet.graphics.Batch()
        self.labels = pyglet.graphics.Batch()

        self.x_len = x_len
        self.y_len = y_len

        self.use16 = use16

        # These will be set by the load chain
        self.terrain_image = None
        self.terrain_grid = None
        self.world_data = None
        self.tile_sprites = None
        self.camera = None

        self.view_offset_x = 0
        self.view_offset_y = 0

        self.load_status = game_state.LoadingStatus.PRE_LOAD

    def load(self):
        if self.load_status == game_state.LoadingStatus.PRE_LOAD:
            self.load_status = game_state.LoadingStatus.LOADING
            pyglet.clock.schedule_once(load_chain.load_textures, 0, self)

        elif self.load_status == game_state.LoadingStatus.LOAD_COMPLETE:
            return True

    def start(self):
        self.window.push_handlers(
            self.camera.on_key_press, self.camera.on_key_release
        )

        pyglet.clock.schedule_interval(self.process_and_cull, 1/60.0)

    def process_and_cull(self, dt):

        self.camera.move_camera(dt)

        #
        # The following code segment, which concerns culling and creating tile
        # sprites is a direct borrow of code from the _update_sprite_set
        # function in tile.py from the cocos2d Python package. 
        #
        # See LICENSE.cocos for the complete license.
        #

        # Get the visible tiles
        
        # End cocos licensed section


    def stop(self):
        pyglet.clock.unschedule(self.camera.move_camera)
        self.window.pop_handlers()

    def on_draw(self):
        self.window.clear()
        self.batch.draw()
        self.labels.draw()