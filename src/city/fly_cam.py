
from pyglet import gl
from pyglet.window import key

import math

CAMERA_VELOCITY = 500

class FlyCamera(object):
    """
        Operates our "camera" by tracking relevant variables and calling 
        glTranslatef

        glTranslatef works kind of strangely, you have to think in terms of the
        direction you want to "drag" the screen. 

        For example, you would normally think of moving up on the y_axis as
        "up". Let's say you want to move "up" by 5. glTranslateF looks at this
        as moving everything down 5 - i.e. such that a pixel that was at 12 is
        now at 7. So to move the screen "up" by 5, we'd have to drag it "down"
        by 5. 

        That would look like:

            glTranslatef(0, -5, 0)

        As a result of all this, you may see that some of the polarities in the
        following functions are a bit counterintuitive. Just keep the 
        "dragging" metaphor in mind.
    """
    def __init__(self, min_vals, max_vals, view_area, margin_size, tile_size,
                view_offset=(0,0), view_start=(0,0)
    ):
        """
        Initializes the camera.

        Inputs:

        min_vals: tuple containing the map's minimum x and y values, in pixels
        max_vals: tuple containing the map's max x and y values, in pixels
        view_area: tuple expressing the length (x size) and height (y size) of
                        the camera's viewing area.
        margin_size: the size of the blank space we'll allow at the min or the
                        max - just so that it doesn't dead stop before the edge of
                        a tile
        view_offset tuple expressing the x and y offset of the view_area from
                        the origin. Measured in pixels.
        view_start: tuple expressing the camera's start location, in pixels
        """
        super(FlyCamera, self).__init__()
        # Map's minimum pixel x, y
        self.min_x, self.min_y = min_vals
        # Map's maximum pixel x, y
        self.max_x, self.max_y = max_vals
        # The view's x size (horizontal length) and y size (vertical height)
        self.v_len, self.v_height = view_area

        self.tile_size = tile_size

        # The blank space margins we'll allow on either side
        self.margin = margin_size

        self._x_velo = 0
        self._y_velo = 0

        # The position of the viewspace, in pixels. This is the lower left
        # point of the view window.

        # The viewscreen naturally starts at 0
        self._vx, self._vy = (0, 0)
        self._vx_off, self._vy_off = (0, 0)

        # Adjust the offset
        if view_offset != (0, 0):
            self.set_camera_offset(view_offset)

        # Adjust the starting position
        if view_start != (0, 0):
            self.set_camera_position(view_start)

    def set_camera_offset(self, new_offset):
        """
        Sets the camera's offset.

        While setting the camera's position translates the world, setting the
        offset changes the camera's position but does NOT translate the world.

        The overall effect is that our perspective of the world shifts, but
        what we are viewing remains the same.
        """

        new_x_off, new_y_off = new_offset 
        
        # Calculate the difference
        off_dx = new_x_off - self._vx_off
        off_dy = new_y_off - self._vy_off

        x_lower_lim = self.min_x - self.margin
        x_upper_lim = (self.max_x - self.v_len) + self.margin

        y_lower_lim = self.min_y - self.margin
        y_upper_lim = (self.max_y - self.v_height) + self.margin

        # Do error checking - set to min and max as necessary
        # Minimum X
        if self._vx + off_dx < x_lower_lim:
            off_dx += (self._vx + off_dx) - x_lower_lim 
        # Maximum X
        elif self._vx + off_dx > x_upper_lim:
            off_dx += x_upper_lim - (self._vx + off_dx)

        # Minimum Y
        if self._vy + off_dy < y_lower_lim:
            off_dy += (self._vy + off_dy) - y_lower_lim
        # Maximum Y
        elif self._vy + off_dy > y_upper_lim:
            off_dy +=  y_upper_lim - (self._vy + off_dy)

        self._vx += off_dx
        self._vy += off_dy

        self._vx_off += off_dx
        self._vy_off += off_dy

    def set_camera_position(self, new_pos):
        """
        Sets the camera's position.

        The camera's position is it's lower-left location. We use the location
        information in discerning what tiles are visible to the player.

        This method moves the camera by translating the view to the specified
        location.
        """
        new_x, new_y = new_pos

        x_lower_lim = self.min_x - self.margin
        x_upper_lim = self.max_x + self.margin - self.v_len

        y_lower_lim = self.min_y - self.margin
        y_upper_lim = self.max_y + self.margin - self.v_height

        # Do error checking - set to min and max as necessary
        # Minimum X
        if new_x < x_lower_lim:
            new_x = x_lower_lim
        # Maximum X
        elif new_x > x_upper_lim:
            new_x = x_upper_lim

        # Minimum Y
        if new_y < y_lower_lim:
            new_y = y_lower_lim
        # Maximum Y
        elif new_y > y_upper_lim:
            new_y = y_upper_lim

        # By subtracting the new value from the old value, 
        # we get a negative value if we need to move right (drags left)
        # and a positive value if we need to move left (drags right)
        # In other words, we won't need to flip the polarities to translate
        trans_x = self._vx - new_x
        trans_y = self._vy - new_y

        # Set the new values
        self._vx, self._vy = new_x, new_y
    
        # Translate
        gl.glTranslatef(trans_x, trans_y, 0) 

    #
    # This function is mostly derived from the get_in_region function, located
    # in tile.py from the cocos2d Python package. 
    #
    # See LICENSE.cocos for the complete license.
    #
    def get_visible_tiles(self):
        """
        Determines the boundaries of the current camera, and returns all tiles
        that can be found there-in.
        """
        left = max(0, self._vx) // self.tile_size
        right = min(self.max_x, self._vx + self.v_len) // self.tile_size

        bottom = max(0, self._vy) // self.tile_size
        top = min(self.max_y, self._vy + self.v_height) // self.tile_size

        return [ (x, y)
            for x in range( int(left), int(right) )
            for y in range( int(bottom), int(top) )
        ]
    # End cocos licensed section

    def get_border_positions(self):
        """
        Gets the
        """      
        return (
            (self._vx, self._vx + self.v_len), 
            (self._vy, self._vy + self.v_height)
        )

    def move_camera(self, dt):
        """
        Moves the camera using the given time difference and the camera's
        current velocity
        """
        trans_x = self._x_velo * dt
        trans_y = self._y_velo * dt

        if not (trans_x == trans_y == 0):
            self.set_camera_position((self._vx + trans_x, self._vy + trans_y))
            
    def on_key_press(self, symbol, modifiers):
        if symbol == key.W:
            self._y_velo += CAMERA_VELOCITY
        elif symbol == key.A:
            self._x_velo -= CAMERA_VELOCITY
        elif symbol == key.D:
            self._x_velo += CAMERA_VELOCITY
        elif symbol == key.S:
            self._y_velo -= CAMERA_VELOCITY

    def on_key_release(self, symbol, modifiers):
        if symbol == key.W:
            self._y_velo -= CAMERA_VELOCITY
        elif symbol == key.A:
            self._x_velo += CAMERA_VELOCITY
        elif symbol == key.D:
            self._x_velo -= CAMERA_VELOCITY
        elif symbol == key.S:
            self._y_velo += CAMERA_VELOCITY
