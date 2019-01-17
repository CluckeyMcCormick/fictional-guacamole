
from pyglet import gl
from pyglet.window import key

import math

CAMERA_VELOCITY = 500

class TileCamera(object):
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

        min_vals: tuple containing the map's minimum x and y values, in tiles
        max_vals: tuple containing the map's max x and y values, in tiles
        view_area: tuple expressing the length (x size) and height (y size) of
                        the camera's viewing area. Measured in pixels.
        margin_size: the size of the blank space we'll allow at the min or the
                        max - just so that it doesn't dead stop before the edge of
                        a tile. Measured in tiles.
        view_offset tuple expressing the x and y offset of the view_area from
                        the origin. Measured in pixels.
        view_start: tuple expressing the camera's start location, in pixels
        """
        super(TileCamera, self).__init__()

        # Set some default variables
        self._tmargin = 0
        self._vpx = 0
        self._vpy = 0
        self._vpx_off = 0
        self._vpy_off = 0

        # The minimum values and maximum values, expressed in tile counts
        self._tx_min = 0
        self._tx_max = 0
        self._ty_min = 0
        self._ty_max = 0

        self.tile_size = tile_size

        # The velocities for the camera's current movement
        self._x_velo = 0
        self._y_velo = 0

        # Set the margin size
        self.margin = margin_size

        # Set the minimum and maximum values
        self.maximum = max_vals
        self.minimum = min_vals

        # The view's x size (horizontal length) and y size (vertical height)
        self.vp_len, self.vp_height = view_area

        # Set the offset
        self.offset = view_offset

        # Adjust the starting position
        self.position = view_start

    @property
    def minimum(self):
        return (self._tx_min, self._ty_min)

    @minimum.setter
    def minimum(self, value):
        new_tx_min, new_ty_min = value
        # If either value is negative
        if (new_tx_min < 0 or new_ty_min < 0):
            raise ValueError(
                "Minimum camera values must not be negative - x:[%d] y[%d]".format(
                    new_tx_min, new_ty_min
                )
            )
        # If either value is above the max
        if (new_tx_min > self._tx_max or new_ty_min > self._ty_max):
            raise ValueError(
                "Minimum camera values must not be above the max - tx:[%d] ty[%d], max tx:[%d] max ty:[%d]".format(
                    new_tx_min, new_ty_min, self._tx_max, self._ty_max
                )
            )

        # Otherwise, there were no errors. Set the values
        self._tx_min = new_tx_min
        self._ty_min = new_ty_min

    @property
    def maximum(self):
        return (self._tx_max, self._ty_max)

    @maximum.setter
    def maximum(self, value):
        new_tx_max, new_ty_max = value
        # If either value is negative
        if (new_tx_max < 0 or new_ty_max < 0):
            raise ValueError(
                "Maximum camera values must not be negative - tx:[%d] ty[%d]".format(
                    new_tx_max, new_ty_max
                )
            )
        # If either value is above the max
        if (new_tx_max < self._tx_min or new_ty_max < self._ty_min):
            raise ValueError(
                "Minimum camera values must not be above the max - tx:[%d] ty[%d], min tx:[%d] min ty:[%d]".format(
                    new_tx_max, new_ty_max, self._tx_min, self._ty_min
                )
            )

        # Otherwise, there were no errors. Set the values
        self._tx_max = new_tx_max
        self._ty_max = new_ty_max

    @property
    def margin(self):
        return self._tmargin

    @margin.setter
    def margin(self, value):
        # If the new value is negative
        if (value < 0):
            raise ValueError("Margin not be negative - tx:[%d] ty[%d]".format(value))
        # Otherwise, there was no error. 
        # First, calculate the old and new margins in pixels
        old_pmargin = self._tmargin * self.tile_size
        new_pmargin = value * self.tile_size

        # Second, subtract out the current margin
        self._vpx -= old_pmargin
        self._vpy -= old_pmargin

        # Third, add in the new margin
        self._vpx += new_pmargin
        self._vpy += new_pmargin

        # Fourth / Finally, set the margin
        self._tmargin = value

    @property
    def offset(self):
        return (self._vpx_off, self._vpy_off)

    @offset.setter
    def offset(self, value):
        """
        Sets the camera's offset.

        While setting the camera's position translates the world, setting the
        offset changes the camera's position but does NOT translate the world.

        The overall effect is that our perspective of the world shifts, but
        what we are viewing remains the same.
        """

        new_px_off, new_py_off = value 
        
        # Calculate the difference
        off_dpx = new_px_off - self._vpx_off
        off_dpy = new_py_off - self._vpy_off

        x_lower_lim = (self._tx_min + self._tmargin) * self.tile_size
        x_upper_lim = (self._tx_max + (self._tmargin * 2)) * self.tile_size - self.vp_len

        y_lower_lim = (self._ty_min + self._tmargin) * self.tile_size
        y_upper_lim = (self._ty_max + (self._tmargin * 2)) * self.tile_size - self.vp_height

        # Do error checking - set to min and max as necessary
        # Minimum X
        if self._vpx + off_dpx < x_lower_lim:
            off_dpx += (self._vpx + off_dpx) - x_lower_lim 
        # Maximum X
        elif self._vpx + off_dpx > x_upper_lim:
            off_dpx += x_upper_lim - (self._vpx + off_dpx)

        # Minimum Y
        if self._vpy + off_dpy < y_lower_lim:
            off_dpy += (self._vpy + off_dpy) - y_lower_lim
        # Maximum Y
        elif self._vpy + off_dpy > y_upper_lim:
            off_dpy +=  y_upper_lim - (self._vpy + off_dpy)

        self._vpx += off_dpx
        self._vpy += off_dpy

        self._vpx_off += off_dpx
        self._vpy_off += off_dpy

    @property
    def position(self):
        return (self._vpx, self._vpy)

    @position.setter
    def position(self, value):
        """
        Sets the camera's position.

        The camera's position is it's lower-left location. We use the location
        information in discerning what tiles are visible to the player.

        This method moves the camera by translating the view to the specified
        location.
        """
        new_vpx, new_vpy = value

        x_lower_lim = (self._tx_min + self._tmargin) * self.tile_size
        x_upper_lim = (self._tx_max + (self._tmargin * 2)) * self.tile_size - self.vp_len

        y_lower_lim = (self._ty_min + self._tmargin) * self.tile_size
        y_upper_lim = (self._ty_max + (self._tmargin * 2)) * self.tile_size - self.vp_height

        # Do error checking - set to min and max as necessary
        # Minimum X
        if new_vpx < x_lower_lim:
            new_vpx = x_lower_lim
        # Maximum X
        elif new_vpx > x_upper_lim:
            new_vpx = x_upper_lim

        # Minimum Y
        if new_vpy < y_lower_lim:
            new_vpy = y_lower_lim
        # Maximum Y
        elif new_vpy > y_upper_lim:
            new_vpy = y_upper_lim

        # By subtracting the new value from the old value, 
        # we get a negative value if we need to move right (drags left)
        # and a positive value if we need to move left (drags right)
        # In other words, we won't need to flip the polarities to translate
        trans_x = self._vpx - new_vpx
        trans_y = self._vpy - new_vpy

        # Set the new values
        self._vpx, self._vpy = new_vpx, new_vpy
    
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

        left = max(0, self._vpx) // self.tile_size
        right = min(self._tx_max * self.tile_size, self._vpx + self.vp_len) // self.tile_size

        bottom = max(0, self._vpy ) // self.tile_size
        top = min(self._ty_max * self.tile_size, self._vpy + self.vp_height) // self.tile_size

        # Return the list of coordinates onscreen, minus the margin
        return [ (x - self._tmargin, y - self._tmargin)
            for x in range( int(left), int(right) )
            for y in range( int(bottom), int(top) )
        ]
    # End cocos licensed section

    def get_border_positions(self):
        """
        Gets the
        """
        pmargin = self._tmargin * self.tile_size

        return (
            (self._vpx - pmargin, self._vpx + self.v_len - pmargin), 
            (self._vpy - pmargin, self._vpy + self.v_height - pmargin)
        )

    def move_camera(self, dt):
        """
        Moves the camera using the given time difference and the camera's
        current velocity
        """
        trans_x = self._x_velo * dt
        trans_y = self._y_velo * dt

        if not (trans_x == trans_y == 0):
            self.position = (self._vpx + trans_x, self._vpy + trans_y)
            
    def on_key_press(self, symbol, modifiers):
        if symbol == key.W:
            self._y_velo += CAMERA_VELOCITY
        elif symbol == key.A:
            self._x_velo -= CAMERA_VELOCITY
        elif symbol == key.D:
            self._x_velo += CAMERA_VELOCITY
        elif symbol == key.S:
            self._y_velo -= CAMERA_VELOCITY
        elif symbol == key.P:
            print(("~" * 5), "MARK", ("~" * 5))
            print( self._vpx, self._vpx / self.tile_size, int(self._vpx / self.tile_size))
        elif symbol == key.O:
            print(("*" * 5), "HERE", ("*" * 5))
            print( self._vpx, self._vpx / self.tile_size, int(self._vpx / self.tile_size))

    def on_key_release(self, symbol, modifiers):
        if symbol == key.W:
            self._y_velo -= CAMERA_VELOCITY
        elif symbol == key.A:
            self._x_velo += CAMERA_VELOCITY
        elif symbol == key.D:
            self._x_velo -= CAMERA_VELOCITY
        elif symbol == key.S:
            self._y_velo += CAMERA_VELOCITY


class DiffCamera(TileCamera):
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
        super(DiffCamera, self).__init__(min_vals, max_vals, 
            view_area, margin_size, tile_size, view_offset, view_start
        )
        self.reset_boundaries()

        print("~" * 15)

        print("  ", self._up_next)
        print(self._left_next,"   ", self._right_next)
        print("  ", self._left_next)

    def reset_boundaries(self):
        # Set the old position (for diff getting purposes)
        self._vpx_old = int(self._vpx / self.tile_size) * self.tile_size
        self._vpy_old = int(self._vpy / self.tile_size) * self.tile_size

        self.set_diff_boundaries()

    def set_camera_position(self, new_pos):
        self.position = new_pos
        reset_boundaries()

    def get_tile_diff(self, reset=True):

        dvpx = (int(self._vpx / self.tile_size) * self.tile_size) - self._vpx_old
        dvpy = (int(self._vpy / self.tile_size) * self.tile_size) - self._vpy_old

        # Step 1: Translate the pixel change into tile change
        tile_dx = int(dvpx / self.tile_size)
        tile_dy = int(dvpy / self.tile_size)

        # Step 2: Back out if no change
        if abs(tile_dx) == 0 and abs(tile_dy) == 0:
            return [], []

        # Step 4: set some necessary variables
        make_tiles = set()
        cull_tiles = set()

        # In order to construct the "new" and "old" sets, we need to know the
        # the borders of both and what our borders should be for the other axis
        #
        # Thus, we construct the following tuple:
        #
        #( make range, cull range, other axis range)
        #
        
        # These values will stop Step 5 from running (if necessary) 
        x_info_tuple = ([], [], [])
        y_info_tuple = ([], [], [])

        tile_x = int(self._vpx / self.tile_size)
        tile_x_len = int((self._vpx + self.vp_len) / self.tile_size)

        tile_y = int(self._vpy / self.tile_size)
        tile_y_height = int((self._vpy + self.vp_height) / self.tile_size)

        if tile_dx <= -1:
            x_info_tuple = (
                range( self._left_next, self._left_next + tile_dx, -1 ),
                range( self._right_next - 1, self._right_next - 1 + tile_dx, -1 ),
                range( tile_y, tile_y_height)
            )
        elif tile_dx >= 1:
            x_info_tuple = (
                range( self._right_next, self._right_next + tile_dx ),
                range( self._left_next + 1, self._left_next + 1 + tile_dx ),
                range( tile_y, tile_y_height)
            )

        if tile_dy <= -1:
            y_info_tuple = (
                range( self._down_next, self._down_next + tile_dy, -1 ),
                range( self._up_next - 1, self._up_next - 1 + tile_dy, -1 ),
                range( tile_x, tile_x_len)
            )
        elif tile_dy >= 1:
            y_info_tuple = (
                range( self._up_next, self._up_next + tile_dy ),
                range( self._down_next + 1, self._down_next + 1 + tile_dy  ),
                range( tile_x, tile_x_len )
            )

        x_make_range, x_cull_range, mc_y_range = x_info_tuple
        y_make_range, y_cull_range, mc_x_range = y_info_tuple
        #
        # Step 5: Using the ranges we just determined, build the cull and 
        #         make sets 

        # Create the make and cull sets for x 
        for x in x_make_range:
            for y in mc_y_range:
                make_tiles.add( (x - self._tmargin, y - self._tmargin) )
        for x in x_cull_range:
            for y in mc_y_range:
                cull_tiles.add( (x - self._tmargin, y - self._tmargin) )

        # Create the make and cull sets for x 
        for y in y_make_range:
            for x in mc_x_range:
                make_tiles.add( (x - self._tmargin, y - self._tmargin) )
        for y in y_cull_range:
            for x in mc_x_range:
                cull_tiles.add( (x - self._tmargin, y - self._tmargin) )

        # Step 3: If we're going to get the tile diff, reset the diff
        if reset:
            # Set the "old" values to the nearest multiple of tile_size
            if tile_dx <= -1 or tile_dx >= 1:
                self._vpx_old = int(self._vpx / self.tile_size) * self.tile_size
            if tile_dy <= -1 or tile_dy >= 1:
                self._vpy_old = int(self._vpy / self.tile_size) * self.tile_size
            self.set_diff_boundaries()
        
        print("~" * 15)

        print("  ", self._up_next)
        print(self._left_next,"   ", self._right_next)
        print("  ", self._down_next)

        return make_tiles, cull_tiles

    def set_diff_boundaries(self):
        #print( self._vpx, self._vpx / self.tile_size, int(self._vpx / self.tile_size))
        self._left_next = int(self._vpx / self.tile_size) - 1
        self._right_next = int( (self._vpx + self.vp_len) / self.tile_size)
        self._down_next = int(self._vpy / self.tile_size) - 1
        self._up_next = int( (self._vpy + self.vp_height) / self.tile_size)
