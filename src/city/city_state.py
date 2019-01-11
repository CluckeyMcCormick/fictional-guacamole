
import pyglet
import random
import numpy
from ctypes import c_byte

import game_state

from .world_maker import WorldMaker


choice_index = [
    (1,  1), (5,  1), (9,  1), (13, 1),
    (17, 1), (21, 1), (25, 1), (29, 1)
]

WORKERS = 8

class CityState(game_state.GameState):

    def __init__(self, window, x_len, y_len):
        super(CityState, self).__init__(window)
        self.batch = pyglet.graphics.Batch()

        self.x_len = x_len
        self.y_len = y_len

        self.load_state = 0

    def load(self):
        if self.load_state == 0:
            #pyglet.resource.reindex()
            self.terrain_image = pyglet.image.load('terrain.png')
            self.terrain_grid = pyglet.image.ImageGrid(
                self.terrain_image, rows=32, columns=12
            )
            self.x_val = 0
            self.y_val = 0
            self.load_state += 1

        elif self.load_state == 1:
            self.wm = WorldMaker(self.x_len, self.y_len, WORKERS)
            self.wm.build()
            self.load_state += 1

        elif self.load_state == 2:
            raw = self.wm.is_done()
            if raw:
                self.raw_world = raw
                print( len(raw), self.x_len, self.y_len, self.x_len * self.y_len )
                a = numpy.frombuffer( raw.get_obj(), dtype=c_byte )
                self.shaped_world = a.reshape( (self.x_len, self.y_len) )
                self.load_state += 1

        elif self.load_state == 3:
            self.city_grid = [[None for _ in range(self.y_len)] for _ in range(self.x_len)]
            for x in range(self.x_len):
                for y in range(self.y_len):
                    world_val = self.shaped_world[x, y]
                    choice_tuple = choice_index[ world_val ]
                    choice = self.terrain_grid[ choice_tuple ]
                    self.city_grid[x][y] = pyglet.sprite.Sprite(choice, x=x * 16, y=y * 16, batch=self.batch)
            self.load_state += 1

        else:
            return True

    def on_draw(self):
        self.window.clear()
        self.batch.draw()