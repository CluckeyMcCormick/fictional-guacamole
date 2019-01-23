
import pyglet
import random
import numpy
from ctypes import c_byte

import game_state

from .world_maker import WorldMaker
from . import tile_cam

WORKERS = 8

X_DEBUG = False #True
Y_DEBUG = True

class CityState(game_state.GameState):

    def __init__(self, window, x_len, y_len, use16=False):
        super(CityState, self).__init__(window)
        self.batch = pyglet.graphics.Batch()
        self.labels = pyglet.graphics.Batch()

        self.x_len = x_len
        self.y_len = y_len

        self.load_state = 0
        self.use16 = use16

    def load(self):
        if self.load_state == 0:
            #pyglet.resource.reindex()
            if self.use16:
                self.terrain_image = pyglet.image.load('terrain_sampler16.png')
            else:
                self.terrain_image = pyglet.image.load('terrain_sampler32.png')
            #self.terrain_image = pyglet.image.load('terrain.png')
            self.terrain_grid = pyglet.image.ImageGrid(
                self.terrain_image, rows=8, columns=1
                #self.terrain_image, rows=32, columns=12
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

        else:
            return True

    def start(self):
        mins = (0,0)
        if self.use16:
            tile_size = 16
        else:
            tile_size = 32
        maxs = (self.x_len, self.y_len)
        margin = 4
        self.view_offset_x = 96
        self.view_offset_y = 96
        #self.view_offset_x = -32
        #self.view_offset_y = -32
        view_x, view_y = self.window.get_size()
        print("view", view_x, view_y)
        view_area = (view_x + ( abs(self.view_offset_x) * 2), view_y + ( abs(self.view_offset_y) * 2))
        view_area = (473, 337) 
        view_start = (0, 0)#(50, 50)

        self.camera = tile_cam.DiffCamera(mins, maxs, view_area, margin, tile_size)

        self.window.push_handlers(
            self.camera.on_key_press, self.camera.on_key_release
        )

        pyglet.clock.schedule_interval(self.process_and_cull, 1/60.0)

        self.active_tiles = set()
        self.tile_sprites = {}

        visible = self.camera.get_visible_tiles()

        for spot in visible:

            # Otherwise, make the sprite for it
            x, y = spot

            # If we're outta bounds, then don't make this sprite
            if not ( 0 <= x < self.x_len and 0 <= y < self.y_len):
                continue

            choice = self.terrain_grid[ (self.shaped_world[x, y], 0) ]

            # Save the information
            if self.use16:
                if X_DEBUG:
                    self.tile_sprites[spot] = pyglet.text.Label(
                        str(x), x=(x * 16) + self.view_offset_x, y=(y * 16) + self.view_offset_y, 
                        font_size=4, batch=self.batch
                    )
                elif Y_DEBUG:
                    self.tile_sprites[spot] = pyglet.text.Label(
                        str(y), x=(x * 16) + self.view_offset_x, y=(y * 16) + self.view_offset_y,
                        font_size=4, batch=self.batch
                    )
                else:
                    self.tile_sprites[spot] = pyglet.sprite.Sprite(
                        choice, x=(x * 16) + self.view_offset_x, y=(y * 16) + self.view_offset_y,
                        batch=self.batch
                    )
            else:
                
                if X_DEBUG:
                    self.tile_sprites[spot] = pyglet.text.Label(
                        str(x), x=(x * 32) + self.view_offset_x, y=(y * 32) + self.view_offset_y, 
                        font_size=8, batch=self.batch
                    )
                elif Y_DEBUG:
                    self.tile_sprites[spot] = pyglet.text.Label(
                        str(y), x=(x * 32) + self.view_offset_x, y=(y * 32) + self.view_offset_y, 
                        font_size=8, batch=self.batch
                    )
                else:
                    self.tile_sprites[spot] = pyglet.sprite.Sprite(
                        choice, x=(x * 32) + self.view_offset_x, y=(y * 32) + self.view_offset_y, 
                        batch=self.batch
                    )

            self.active_tiles.add( spot )

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

        make_set, cull_set = self.camera.get_tile_diff()

        if make_set and cull_set:
            print("\tDT:", dt)

        doubled = False

        for spot in make_set:

            # Otherwise, make the sprite for it
            x, y = spot

            # If we're outta bounds, then don't make this sprite
            if not ( 0 <= x < self.x_len and 0 <= y < self.y_len):
                continue

            # If this tile is already visible, skip it
            if spot in self.active_tiles:
                print( "\t\tDoubled:", spot )
                doubled = True
                continue

            choice = self.terrain_grid[ (self.shaped_world[x, y], 0) ]


            # Save the information
            if self.use16:
                if X_DEBUG:
                    self.tile_sprites[spot] = pyglet.text.Label(
                        str(x), x=(x * 16) + self.view_offset_x, y=(y * 16) + self.view_offset_y, 
                        font_size=4, batch=self.batch
                    )
                elif Y_DEBUG:
                    self.tile_sprites[spot] = pyglet.text.Label(
                        str(y), x=(x * 16) + self.view_offset_x, y=(y * 16) + self.view_offset_y,
                        font_size=4, batch=self.batch
                    )
                else:
                    self.tile_sprites[spot] = pyglet.sprite.Sprite(
                        choice, x=(x * 16) + self.view_offset_x, y=(y * 16) + self.view_offset_y,
                        batch=self.batch
                    )
            else:
                
                if X_DEBUG:
                    self.tile_sprites[spot] = pyglet.text.Label(
                        str(x), x=(x * 32) + self.view_offset_x, y=(y * 32) + self.view_offset_y, 
                        font_size=8, batch=self.batch
                    )
                elif Y_DEBUG:
                    self.tile_sprites[spot] = pyglet.text.Label(
                        str(y), x=(x * 32) + self.view_offset_x, y=(y * 32) + self.view_offset_y, 
                        font_size=8, batch=self.batch
                    )
                else:
                    self.tile_sprites[spot] = pyglet.sprite.Sprite(
                        choice, x=(x * 32) + self.view_offset_x, y=(y * 32) + self.view_offset_y, 
                        batch=self.batch
                    )

            self.active_tiles.add( spot )
        
        # For those tiles not in the current draw list
        for spot in cull_set:
            if spot in self.active_tiles:
                # Remove
                self.active_tiles.remove(spot)
                self.tile_sprites[spot].delete()
                self.tile_sprites.pop(spot)
        
        # End cocos licensed section

        if doubled:
            print("@" * 5)

    def stop(self):
        pyglet.clock.unschedule(self.camera.move_camera)
        self.window.pop_handlers()

    def on_draw(self):
        self.window.clear()
        self.batch.draw()
        self.labels.draw()