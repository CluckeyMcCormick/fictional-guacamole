
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
    def __init__(self, min_vals, max_vals, view_area, margin_size, tile_size):
        """
        Initializes the camera.

        Inputs:

        min_vals: tuple containing the map's minimum x and y values, in tiles
        max_vals: tuple containing the map's max x and y values, in tiles
        view_area: tuple expressing the length (x size) and height (y size) of
                        the camera's viewing area. Measured in pixels.
        view_start: tuple expressing the camera's start location, in pixels
        """
        super(TileCamera, self).__init__()

        # Set some default variables
        self._tmargin = 0
        self._vpx = 0
        self._vpy = 0

        # The minimum values and maximum values, expressed in tile counts
        self._tx_min = 0
        self._tx_max = 0
        self._ty_min = 0
        self._ty_max = 0

        # Set the tile size, in pixels
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
        self._vp_len, self._vp_height = view_area

        print(self._vpx, self._vpy)

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
    def position(self):
        return (self._vpx, self._vpy)

    def set_position(self, value):
        """
        Sets the camera's position.

        The camera's position is it's lower-left location. We use the location
        information in discerning what tiles are visible to the player.

        This method moves the camera by translating the view to the specified
        location.
        """
        new_vpx, new_vpy = value

        x_lower_lim = self._tx_min * self.tile_size
        x_upper_lim = self._tx_max + (self._tmargin * 2)
        x_upper_lim = (x_upper_lim * self.tile_size) - self._vp_len

        y_lower_lim = self._ty_min * self.tile_size
        y_upper_lim = self._ty_max + (self._tmargin * 2)
        y_upper_lim = (y_upper_lim * self.tile_size) - self._vp_height

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
        self._vpx -= trans_x
        self._vpy -= trans_y
    
        # Translate
        gl.glTranslatef(trans_x, trans_y, 0) 

        print("WXYZ: ", self._vpx, self._vpy)

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
        right = min(self._tx_max * self.tile_size, self._vpx + self._vp_len)
        right = right // self.tile_size

        bottom = max(0, self._vpy ) // self.tile_size
        top = min(self._ty_max * self.tile_size, self._vpy + self._vp_height)
        top = top // self.tile_size

        # Return the list of coordinates onscreen, minus the margin
        return [ (x - self._tmargin, y  - self._tmargin)
            for x in range( int(left), int(right) )
            for y in range( int(bottom), int(top) )
        ]
    # End cocos licensed section

    def get_border_positions(self):
        """
        Gets the
        """

        return (
            (self._vpx, self._vpx + self._vp_len), 
            (self._vpy, self._vpy + self._vp_height)
        )

    def move_camera(self, dt):
        """
        Moves the camera using the given time difference and the camera's
        current velocity
        """
        trans_x = self._x_velo * dt
        trans_y = self._y_velo * dt

        if not (trans_x == trans_y == 0):
            self.set_position( (self._vpx + trans_x, self._vpy + trans_y) )
 
    def move_camera_by_pixels(self, pix_dx, pix_dy):
        self.set_position( (self._vpx + pix_dx, self._vpy + pix_dy) )

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

        # Move by pixel
        elif symbol == key.UP:
            self.move_camera_by_pixels(0, self.tile_size)
        elif symbol == key.DOWN:
            self.move_camera_by_pixels(0, -self.tile_size)
        elif symbol == key.LEFT:
            self.move_camera_by_pixels(-self.tile_size, 0)
        elif symbol == key.RIGHT:
            self.move_camera_by_pixels(self.tile_size, 0)

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
    def __init__(self, min_vals, max_vals, view_area, margin_size, tile_size):
        super(DiffCamera, self).__init__(min_vals, max_vals, 
            view_area, margin_size, tile_size
        )

        self.left_border = CameraBorder(self._vpx, 0, self.tile_size, True)
        self.bottom_border = CameraBorder(self._vpy, 0, self.tile_size, True)

        self.right_border = CameraBorder(self._vpx, self._vp_len, self.tile_size, False)
        self.top_border = CameraBorder(self._vpy, self._vp_height, self.tile_size, False)

    def diff_reset(self):
        self.left_border.apply_change(self._vpx)
        self.left_border.reset()
        self.right_border.apply_change(self._vpx)
        self.right_border.reset()

        self.bottom_border.apply_change(self._vpy)
        self.bottom_border.reset()
        self.top_border.apply_change(self._vpy)
        self.top_border.reset()

    def set_position(self, new_pos, reset=False):
        super(DiffCamera, self).set_position(new_pos)
        if reset:
            self.diff_reset()
        else:
            self.left_border.apply_change(self._vpx)
            self.right_border.apply_change(self._vpx)
            self.bottom_border.apply_change(self._vpy)
            self.top_border.apply_change(self._vpy)

    def get_tile_diff(self, reset=True):

        # Step 2: If the movement didn't break any of our targets
        if( not self.left_border.has_change() and 
            not self.bottom_border.has_change() and
            not self.right_border.has_change() and
            not self.top_border.has_change()
        ):
            # Then back out
            return [], []

        # Step 4: set some necessary variables
        make_tiles = set()
        cull_tiles = set()

        # Step 5: construct the ranges
        # In order to construct the "new" and "old" sets, we need to know the
        # the borders of both and what our borders should be for the other axis
        #
        # Thus, we construct the following tuple:
        #
        #( make range, cull range, other axis range)
        #
        
        # These values will stop Step 5 from running (as necessary) 
        x_make_range, x_cull_range, mc_y_range = ([], [], [])
        y_make_range, y_cull_range, mc_x_range = ([], [], [])

        # Did we change at the left border?
        left_change = False
        # Did we change at the right border?
        right_change = False
        # Did we change at the bottom border?
        bottom_change = False
        # Did we change at the top border?
        top_change = False

        #
        # Craft the MAKE list on x
        #
        # If we have a make on left
        if self.left_border.has_make():
            x_make_range = self.left_border.get_make_range()
            left_change = True
        # Otherwise, if we have a make on right, make on right
        elif self.right_border.has_make():
            x_make_range = self.right_border.get_make_range()
            right_change = True

        #
        # Craft the CULL list on x
        #
        # If we have a cull on left
        if self.left_border.has_cull():
            x_cull_range = self.left_border.get_cull_range()
            left_change = True
        # Otherwise, if we have a cull on right, cull on right
        elif self.right_border.has_cull():
            x_cull_range = self.right_border.get_cull_range()
            right_change = True

        #
        # Craft the MAKE list on y
        #
        # If we have a make on bottom
        if self.bottom_border.has_make():
            y_make_range = self.bottom_border.get_make_range()
            bottom_change = True
        # If we have a make on top
        elif self.top_border.has_make():
            y_make_range = self.top_border.get_make_range()
            top_change = True

        #
        # Craft the CULL list on y
        #
        # If we have a make on bottom
        if self.bottom_border.has_cull():
            y_cull_range = self.bottom_border.get_cull_range()
            bottom_change = True
        # If we have a make on top
        elif self.top_border.has_cull():
            y_cull_range = self.top_border.get_cull_range()
            top_change = True

        mc_x_range = range( 
            self.left_border.get_current_tile(),
            self.right_border.get_current_tile() + 1
        )

        mc_y_range = range( 
            self.bottom_border.get_current_tile(),
            self.top_border.get_current_tile() + 1
        )

        print("& " * 5, x_make_range, x_cull_range, mc_y_range)
        print("# " * 5, y_make_range, y_cull_range, mc_x_range)
        print("vpx/y", self._vpx, self._vpy)
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
        if left_change:
            self.left_border.reset()
        if right_change:
            self.right_border.reset()
        if bottom_change:
            self.bottom_border.reset()
        if top_change:
            self.top_border.reset()


        print("~" * 15)

        return make_tiles, cull_tiles


class CameraBorder(object):
    """docstring for CameraBorder"""
    def __init__(self, pixel_pos, offset, tile_size, is_near):
        super(CameraBorder, self).__init__()
        # The current "position" of the camera
        self.p_pos = pixel_pos
        # The offset of the border from the position
        self.offset = offset
        # The associated tile_size of the camera
        self.tile_size = tile_size
        # Is this border near (left & bottom), instead of far (top & right)
        self.is_near = is_near

        self.reset()

    def reset(self):
        # 1. Current position becomes the old position
        self.old_p_pos = self.p_pos
        # 2. Calculate the current tile
        curr_t = int( (self.p_pos + self.offset) / self.tile_size)
        # 3. Derive the "next" and "previous" offset depending on is_near
        # If we're near
        if self.is_near:
            # The "make" tile is the starting edge of our current tile
            make_dt = 0
            # The "cull" tile is the starting edge of the next tile
            cull_dt = 1
        else:
            # The "make" tile is the starting edge of the next tile
            make_dt = 1
            # The "cull" tile is the starting edge of our current tile
            cull_dt = 0

        # 4. Calculate the distance to the "cull" tile
        self.cull_dist = (curr_t + cull_dt) * self.tile_size
        self.cull_dist -= self.p_pos + self.offset
        # 5. Calculate the distance to the "make" tile
        self.make_dist = (curr_t + make_dt) * self.tile_size 
        self.make_dist -= self.p_pos + self.offset

    def apply_change(self, new_pos):
        self.p_pos = new_pos

    def has_make(self):
        diff = self.p_pos - self.old_p_pos

        # If we're in a near tile,
        if self.is_near:
            # Make is negative
            return diff < self.make_dist
        else:
            # Make is positive
            return diff >= self.make_dist

    def has_cull(self):
        diff = self.p_pos - self.old_p_pos

        # If we're in a near tile,
        if self.is_near:
            # Cull is positive
            return diff >= self.cull_dist
        else:
            # Cull is negative
            return diff < self.cull_dist

    def has_change(self):
        return self.has_make() or self.has_cull()

    def get_make_range(self):
        make_range = []

        tile = int( (self.p_pos + self.offset) / self.tile_size)
        old_tile = int( (self.old_p_pos + self.offset) / self.tile_size)

        # If this is a near boundary
        if self.is_near:
            # The the current tile < old_tile
            make_range = range( tile, old_tile )
        # Otherwise, it must be a far boundary
        else:
            # Then the current tile > old_tile
            make_range = range( tile, old_tile, -1 )

        return make_range

    def get_cull_range(self):
        cull_range = []

        tile = int( (self.p_pos + self.offset) / self.tile_size)
        old_tile = int( (self.old_p_pos + self.offset) / self.tile_size)

        # If this is a near boundary
        if self.is_near:
            # The the current tile > old_tile
            cull_range = range( old_tile, tile )
        # Otherwise, it must be a far boundary
        else:
            # Then the current tile < old_tile
            cull_range = range( old_tile, tile, -1 )

        return cull_range

    def get_old_tile(self):
        return int( (self.old_p_pos + self.offset) / self.tile_size)

    def get_current_tile(self):
        return int( (self.p_pos + self.offset) / self.tile_size)
