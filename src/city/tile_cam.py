
from pyglet import gl
from pyglet.window import key

import math

CAMERA_VELOCITY = 500

class TileCamera(object):
    """
        Operates our "camera" by tracking relevant variables and calling 
        glTranslatef.

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

        Just a note - at this time, changing the size of the view window is not
        supported!
    """
    def __init__(self, min_vals, max_vals, view_area, margin_size, tile_size):
        """
        Initializes the camera.

        Arguments:

        min_vals -- tuple containing the map's minimum x and y values, in tiles
        max_vals -- tuple containing the map's max x and y values, in tiles
        view_area -- tuple expressing the length (x size) and height (y size) of
                     the camera's viewing area. Measured in pixels.
        margin_size -- tuple expressing the camera's blank space margin, in tiles
        tile_size -- size of each tile, expressed in pixels
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
        """The margin size, in tiles."""
        return self._tmargin

    @margin.setter
    def margin(self, value):
        """Sets the margin size. Requires a positive value."""
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
        """Returns the minimum, in tile size, as a (x, y) tuple."""
        return (self._tx_min, self._ty_min)

    @minimum.setter
    def minimum(self, value):
        """Sets the minimum, in tile size. Requires a (x, y) tuple."""
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
        """Returns the maximum, in tile size, as a (x, y) tuple."""
        return (self._tx_max, self._ty_max)

    @maximum.setter
    def maximum(self, value):
        """Sets the maximum, in tile size. Requires a (x, y) tuple."""
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
        """
        Returns the pixel position as a (x, y) tuple.

        The X and Y values are appropriately shifted by the pixel size of the
        margin.
        """
        margin_shift = self._tmargin * self.tile_size
        return (self._vpx - margin_shift, self._vpy - margin_shift)

    def set_position(self, value, add_margin=True):
        """
        Sets the camera's position and translates the view to the specified
        location.

        The camera's position is it's lower-left location. We use the location
        information in discerning what tiles are visible to the player.

        This method will not allow the camera to go out-of-bounds, and will cap
        any values at the camera's limits.

        Arguments:

        value -- A (x, y) position tuple. Measured in pixels.

        Keyword arguments:

        add_margin -- If True, the the pixel size of margin will be added into
                      [value] before calculations have begun.
        """
        new_vpx, new_vpy = value

        margin_p = self.tile_size * self._tmargin

        if add_margin:
            new_vpx += margin_p
            new_vpy += margin_p

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

        left = int(self._vpx / self.tile_size)
        right = int((self._vpx + self._vp_len) / self.tile_size)

        bottom = int(self._vpy / self.tile_size)

        top = int( (self._vpy + self._vp_height) / self.tile_size)

        # Return the list of coordinates onscreen, minus the margin
        return [ (x - self._tmargin, y  - self._tmargin)
            for x in range( left, right + 1 ) # + 1 to include our current tile
            for y in range( bottom, top  + 1) # + 1 to include our current tile
        ]
    # End cocos licensed section

    def get_border_positions(self):
        """
        Gets the pixel positions of the left, right, bottom, and top borders.

        Returns a tuple of two tuples: ( left, right, bottom, top )
        """

        margin_shift = self._tmargin * self.tile_size

        return (
            self._vpx - margin_shift, self._vpx - margin_shift + self._vp_len, 
            self._vpy - margin_shift, self._vpy - margin_shift + self._vp_height
        )

    def move_camera(self, dt):
        """
        Moves the camera using the given time difference and the camera's
        current velocity.
        """
        trans_x = self._x_velo * dt
        trans_y = self._y_velo * dt

        if not (trans_x == trans_y == 0):
            self.set_position( (self._vpx + trans_x, self._vpy + trans_y), add_margin=False )
 
    def move_camera_by_pixels(self, pix_dx, pix_dy):
        """
        This function moves the camera by the specified number of pixels.
        Mostly meant for use by outside classes.
        """
        self.set_position( (self._vpx + pix_dx, self._vpy + pix_dy), add_margin=False )

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
    A variant of TileCamera that tracks it's position changes. At anytime, we
    can get two lists of tiles to both make and to cull.
    """
    def __init__(self, min_vals, max_vals, view_area, margin_size, tile_size):
        """
        Initializes the camera.

        Arguments:

        min_vals -- tuple containing the map's minimum x and y values, in tiles
        max_vals -- tuple containing the map's max x and y values, in tiles
        view_area -- tuple expressing the length (x size) and height (y size) of
                     the camera's viewing area. Measured in pixels.
        margin_size -- tuple expressing the camera's blank space margin, in tiles
        tile_size -- size of each tile, expressed in pixels
        """
        super(DiffCamera, self).__init__(min_vals, max_vals, 
            view_area, margin_size, tile_size
        )
        # Create our X axis borders
        self.left_border = CameraBorder(self._vpx, 0, self.tile_size, True)
        self.bottom_border = CameraBorder(self._vpy, 0, self.tile_size, True)

        # Create our Y axis borders
        self.right_border = CameraBorder(self._vpx, self._vp_len, self.tile_size, False)
        self.top_border = CameraBorder(self._vpy, self._vp_height, self.tile_size, False)

    def diff_reset(self):
        """
        Resets the diff tracking mechanisms so that they "forget" the old
        position.

        This method is intended for when the camera moves in a non-continous
        manner - for example, if we were to manually jump the camera to a
        certain position.
        """

        self.left_border.apply_change(self._vpx)
        self.left_border.reset()
        self.right_border.apply_change(self._vpx)
        self.right_border.reset()

        self.bottom_border.apply_change(self._vpy)
        self.bottom_border.reset()
        self.top_border.apply_change(self._vpy)
        self.top_border.reset()

    def set_position(self, new_pos, add_margin=True, reset=False):
        """
        Sets the camera's position and translates the view to the specified
        location.

        The camera's position is it's lower-left location. We use the location
        information in discerning what tiles are visible to the player.

        This method will not allow the camera to go out-of-bounds, and will cap
        any values at the camera's limits.

        Arguments:

        new_pos -- A (x, y) position tuple. Measured in pixels.

        Keyword arguments:

        add_margin -- If True, the the pixel size of margin will be added into
                      [value] before calculations have begun.

        reset -- If True, the method will call diff_reset after moving the
                 camera. Only intended for when the camera is moving in a 
                 non-continous manner - for example, if we were to manually 
                 jump the camera to a certain position.
        """
        super(DiffCamera, self).set_position(new_pos, add_margin=add_margin)
        if reset:
            self.diff_reset()
        else:
            self.left_border.apply_change(self._vpx)
            self.right_border.apply_change(self._vpx)
            self.bottom_border.apply_change(self._vpy)
            self.top_border.apply_change(self._vpy)

    def get_tile_diff(self, reset=True):
        """
        Produces a tuple, containing two collections: a make collection, and a
        cull collection. The tuple is (make, cull).

        Each entry in either collection is an (x, y) tuple, shifted to exclude
        the margin. This means the values can be anywhere from [tile_min - 
        t_margin] to [tile_max + t_margin] (inclusive).

        Returns a make set/list and a cull set/list. Either one may be empty if
        there are no tiles to make / cull, respectively.

        Keyword arguments:

        reset -- If True, the method will reset those borders that reported
                 their changes. This will allow you to avoid unecessary 
                 repeated tiles on subsequent calls.

        """

        # Step 1: If the movement didn't break any of our targets
        if( not self.left_border.has_change() and 
            not self.bottom_border.has_change() and
            not self.right_border.has_change() and
            not self.top_border.has_change()
        ):
            # Then back out
            return [], []

        # Step 2: set some necessary variables
        make_tiles = set()
        cull_tiles = set()

        # Step 3: construct the ranges
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
            x_make_range = self.left_border.make_range
            left_change = True
        # Otherwise, if we have a make on right, make on right
        elif self.right_border.has_make():
            x_make_range = self.right_border.make_range
            right_change = True

        #
        # Craft the CULL list on x
        #
        # If we have a cull on left
        if self.left_border.has_cull():
            x_cull_range = self.left_border.cull_range
            left_change = True
        # Otherwise, if we have a cull on right, cull on right
        elif self.right_border.has_cull():
            x_cull_range = self.right_border.cull_range
            right_change = True

        #
        # Craft the MAKE list on y
        #
        # If we have a make on bottom
        if self.bottom_border.has_make():
            y_make_range = self.bottom_border.make_range
            bottom_change = True
        # If we have a make on top
        elif self.top_border.has_make():
            y_make_range = self.top_border.make_range
            top_change = True

        #
        # Craft the CULL list on y
        #
        # If we have a make on bottom
        if self.bottom_border.has_cull():
            y_cull_range = self.bottom_border.cull_range
            bottom_change = True
        # If we have a make on top
        elif self.top_border.has_cull():
            y_cull_range = self.top_border.cull_range
            top_change = True

        mc_x_range = range( 
            self.left_border.current_tile,
            self.right_border.current_tile + 1
        )

        mc_y_range = range( 
            self.bottom_border.current_tile,
            self.top_border.current_tile + 1
        )

        #
        # Step 4: Using the ranges we just determined, build the cull and 
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

        #
        # Step 5: If we're going to reset, only reset those that changed
        #
        if reset:
            if left_change:
                self.left_border.reset()
            if right_change:
                self.right_border.reset()
            if bottom_change:
                self.bottom_border.reset()
            if top_change:
                self.top_border.reset()

        return make_tiles, cull_tiles

class CameraBorder(object):
    """
    Tracks the "border" or "edge" of a camera. Allows each border to
    independently track when a make or cull is required, as well as provide the
    tiles that would need to be culled or listed.
    """
    def __init__(self, pixel_pos, offset, tile_size, is_near):
        """

        Initializes the camera border.

        Arguments:

        p_pos -- The current "position" of the camera
         
        offset -- The offset of the border from the position. This is for right
                  and top borders.
     
        tile_size -- The tile_size of the associated camera.
    
        is_near -- Is this border near (left & bottom), instead of far (top &
                   right)? The make and cull behavior changes depending on
                   which it is.
        """
        super(CameraBorder, self).__init__()

        self.p_pos = pixel_pos
        self.offset = offset
        self.tile_size = tile_size
        self.is_near = is_near

        # Initial reset
        self.reset()

    def reset(self):
        """
        Causes the border to reset/re-orient itself. This entails setting the
        current position to the "old" position, then recalculating the distance
        before a make and a cull.

        Ideally, this should be called whenever we process the cull and make
        lists.
        """
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
        """
        Sets the current position to the new position.
        """
        self.p_pos = new_pos

    def has_make(self):
        """
        Reports whether tiles need to be made on this border.
        """
        diff = self.p_pos - self.old_p_pos

        # If we're in a near tile,
        if self.is_near:
            # Make is negative
            return diff < self.make_dist
        else:
            # Make is positive
            return diff >= self.make_dist

    def has_cull(self):
        """
        Reports whether tiles need to be culled on this border.
        """
        diff = self.p_pos - self.old_p_pos

        # If we're in a near tile,
        if self.is_near:
            # Cull is positive
            return diff >= self.cull_dist
        else:
            # Cull is negative
            return diff < self.cull_dist

    def has_change(self):
        """
        Reports whether the border requires either a make or a cull.
        """
        return self.has_make() or self.has_cull()

    @property
    def make_range(self):
        """
        Returns a range object of tiles to make. 

        The range needs to be iterated through with another range in order to
        actually produce any usable (x, y) tuples.
        """
        make_range = []

        # If this is a near boundary
        if self.is_near:
            # The the current tile < old_tile
            make_range = range( self.tile, self.old_tile )
        # Otherwise, it must be a far boundary
        else:
            # Then the current tile > old_tile
            make_range = range( self.tile, self.old_tile, -1 )

        return make_range

    @property
    def cull_range(self):
        """
        Returns a range object of tiles to cull. 

        The range needs to be iterated through with another range in order to
        actually produce any usable (x, y) tuples.
        """
        cull_range = []

        # If this is a near boundary
        if self.is_near:
            # The the current tile > old_tile
            cull_range = range( self.old_tile, self.tile )
        # Otherwise, it must be a far boundary
        else:
            # Then the current tile < old_tile
            cull_range = range( self.old_tile, self.tile, -1 )

        return cull_range

    @property
    def old_tile(self):
        """
        Gets what the border considers to be the "old" tile - it's last
        position.
        """
        return int( (self.old_p_pos + self.offset) / self.tile_size)

    @property
    def current_tile(self):
        """
        Gets the current tile position.
        """
        return int( (self.p_pos + self.offset) / self.tile_size)
