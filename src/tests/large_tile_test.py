import pyglet
from pyglet.window import key

import random
import numpy as np
import city

import game_util

# Just pre-initialize a couple of things
grid = None
tex_group = None

def run():
    global grid
    global tex_group

    window = pyglet.window.Window(width=1000, height=600)

    # Set where we'll be loading assets from
    pyglet.resource.path.append('@city.world.assets')
    pyglet.resource.path.append('@load_screens.assets')
    pyglet.resource.reindex()

    _, grid, _, _ = city.world.assets.terrain_detail.load()

    image = grid[(4, 3)]
    batch = pyglet.graphics.Batch()
    tex_group = pyglet.graphics.TextureGroup(image.get_texture())

    tile = game_util.tiles.SizableTile( (128, 128), (128, 128), tex_group, batch )

    @window.event
    def on_draw():
        window.clear()
        batch.draw()

    @window.event
    def on_key_press(symbol, modifiers):
        global tex_group
        global grid

        if symbol == key._1:
            tex_group.texture = grid[(7, 0)].get_texture()

        elif symbol == key._2:
            tex_group.texture = grid[(7, 1)].get_texture()

        elif symbol == key._3:
            tex_group.texture = grid[(7, 2)].get_texture()
        
        elif symbol == key._4:
            tex_group.texture = grid[(7, 3)].get_texture()
        
        elif symbol == key._5:
            tex_group.texture = grid[(4, 3)].get_texture()

    pyglet.app.run()