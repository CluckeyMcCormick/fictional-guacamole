import pyglet

from pyglet.window import key

pyglet.resource.path.append('@turret')
pyglet.resource.reindex()

MAX_TURRET_ANGLE = 90
TURRET_ACCEL = 25
TURRET_DECCEL = 180

MAX_TURRET_VELOCITY = 20

class TurretEntity(pyglet.sprite.Sprite):
    """docstring for TankTurret"""

    turret_image = pyglet.resource.image('tank_turret.png')
    turret_image.anchor_x = 15
    turret_image.anchor_y = 15

    def __init__(self, *args, **kwargs):
        super(TurretEntity, self).__init__(self.turret_image, *args, **kwargs)
        self.rot_velo = 0
        self.rot_accel = [0, 0]
    
    def update(self, dt):

        accel = sum(self.rot_accel)

        # If we're accelerating, then ACCELERATE!
        if accel:
            self.rot_velo += accel * dt
        # If we're not accelerating, then start decelerating
        elif self.rot_velo != 0:
            # Get the OPPOSITE sign so we know which way to deccelerate
            sign = -(self.rot_velo / abs(self.rot_velo))
            # So first, calculate our deceleration using the sign, decceleration
            # constant, and time difference. Then, multiply it by our velocity;
            # this will slow the slowing as we approach 0. Finally, tenth it so
            # the result isn't so large that we explode.
            self.rot_velo += (sign * TURRET_DECCEL * dt) * abs(self.rot_velo) * .1

        # Cap ourselves - we don't want to speed into infinity
        self.rot_velo = max( 
            -MAX_TURRET_VELOCITY,
            min(self.rot_velo, MAX_TURRET_VELOCITY)
        )

        new_rot = self.rotation + self.rot_velo 

        if new_rot < -MAX_TURRET_ANGLE:
            new_rot = -MAX_TURRET_ANGLE
        elif new_rot > MAX_TURRET_ANGLE:
            new_rot = MAX_TURRET_ANGLE

        self.rotation = new_rot

    def on_key_press(self, symbol, modifiers):
        if symbol == key.Q:
            self.rot_accel[0] -= TURRET_ACCEL
        elif symbol == key.E:
            self.rot_accel[1] += TURRET_ACCEL

    def on_key_release(self, symbol, modifiers):
        if symbol == key.Q:
            self.rot_accel[0] += TURRET_ACCEL
        elif symbol == key.E:
            self.rot_accel[1] -= TURRET_ACCEL