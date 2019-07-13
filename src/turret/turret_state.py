
import pyglet

from pyglet import gl

import random
import numpy
from ctypes import c_byte

import game_state
import game_util

from . import turret

class TurretState(game_state.GameState):

    def __init__(self, window):
        super(TurretState, self).__init__(window)
        self.labels = pyglet.graphics.Batch()
        self.prime_batch = pyglet.graphics.Batch()

    def load(self):
        self.bg_image = pyglet.resource.image('background.png')
        self.bg_sprite = pyglet.sprite.Sprite(
            self.bg_image, batch=self.prime_batch,
        )
        self.bg_sprite.color = (35, 35, 35)

        self.turret = turret.TurretEntity(x=550/2, y=25, batch=self.prime_batch)

        return True

    def start(self):
        self.window.push_handlers(
            self.turret.on_key_press,
            self.turret.on_key_release
        )

        pyglet.clock.schedule_interval(self.state_loop, 1/60.0)

        self.fps_display = pyglet.window.FPSDisplay(self.window)
        self.delta_time_display = pyglet.text.Label(
            batch=self.labels, x=10, y=40, font_size=10, color=(255, 0, 25, 255)
        )

    def state_loop(self, dt):
        self.delta_time_display.text = "Rotation Value: " + str(self.turret.rot_velo)
        self.turret.update(dt)

    def stop(self):
        pyglet.clock.unschedule(self.camera.move_camera)
        self.window.pop_handlers()

    def on_draw(self):
        self.window.clear()
        self.prime_batch.draw()

        # Get the model view matrix, put it on the "pile"
        gl.glMatrixMode(gl.GL_MODELVIEW)
        gl.glPushMatrix()
        gl.glLoadIdentity()

        # Get the projection view matrix, push it on the pile
        gl.glMatrixMode(gl.GL_PROJECTION)
        gl.glPushMatrix()
        gl.glLoadIdentity()

        # Do... something???
        gl.glOrtho(0, self.window.width, 0, self.window.height, -1, 1)

        self.labels.draw()

        # Put everything back to the way it was
        gl.glPopMatrix()
        gl.glMatrixMode(gl.GL_MODELVIEW)
        gl.glPopMatrix()

        self.fps_display.draw()

