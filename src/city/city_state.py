
import pyglet
import random

import game_state

class CityState(game_state.GameState):

    def __init__(self, window, x_len, y_len):
        super(CityState, self).__init__(window)
        self.batch = pyglet.graphics.Batch()

        self.initial = False
        self.x_len = x_len
        self.y_len = y_len
        self.valid_values = [
            (4,4), (4,5), (4,6), (4,7),
            (5,4), (5,5), (5,6), (5,7),
            (6,4), (6,5), (6,6), (6,7),
            (7,4), (7,5), (7,6), (7,7),
        ]

    def load(self):
        if not self.initial:
            self.city_grid = [ [None] * self.y_len for _ in range(self.x_len) ] 
            self.terrain_image = pyglet.image.load('terrain.png')
            self.terrain_grid = pyglet.image.ImageGrid(
                self.terrain_image, 32, 12
            )
            self.x_val = 0
            self.y_val = 0
            self.initial = True

        choice = self.terrain_grid[ random.choice(self.valid_values) ]
        self.city_grid[self.x_val][self.y_val] = pyglet.sprite.Sprite(choice, x=self.x_val * 16, y=self.y_val * 16, batch=self.batch)

        self.x_val += 1

        if self.x_val == self.x_len:
            self.x_val = 0
            self.y_val += 1

        if self.y_val == self.y_len:
            return True

    def on_draw(self):
        self.window.clear()
        self.batch.draw()