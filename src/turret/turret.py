import pyglet

from pyglet.window import key

pyglet.resource.path.append('@turret')
pyglet.resource.reindex()

MAX_TURRET_ANGLE = 90
TURRET_VELOCITY = 45

class TurretEntity(pyglet.sprite.Sprite):
    """docstring for TankTurret"""

    turret_image = pyglet.resource.image('tank_turret.png')
    turret_image.anchor_x = 15
    turret_image.anchor_y = 15

    def __init__(self, *args, **kwargs):
        super(TurretEntity, self).__init__(self.turret_image, *args, **kwargs)
        self.rot_velo = 0 
    
    def update(self, dt):
        new_rot = self.rotation + (self.rot_velo * dt)

        if new_rot < -MAX_TURRET_ANGLE:
            new_rot = -MAX_TURRET_ANGLE
        elif new_rot > MAX_TURRET_ANGLE:
            new_rot = MAX_TURRET_ANGLE

        self.rotation = new_rot

    def on_key_press(self, symbol, modifiers):
        if symbol == key.Q:
            self.rot_velo -= TURRET_VELOCITY
        elif symbol == key.E:
            self.rot_velo += TURRET_VELOCITY

    def on_key_release(self, symbol, modifiers):
        if symbol == key.Q:
            self.rot_velo += TURRET_VELOCITY
        elif symbol == key.E:
            self.rot_velo -= TURRET_VELOCITY