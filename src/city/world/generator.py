
import math
import noise

import game_util

"""
A "generator" is an odd sort of object (that may be unecessary), but it
satisfies two special criteria:

1. Given a x and y value, it produces a consistent value

2. As objects, they can be easily passed between functions.

This allows us to blindly mix-and-match these separate generators to hopefully
create something cool.

These are mostly meant for world generation.
"""
class RadialGenerator(object):
    """
    This generator creates a large bump located at the [center], extending in
    [radius] in all directions. The [range] of values extend from the center to
    the end of the radius.
    """
    def __init__(self, center, radius, rad_range=(1.0, -1.0)):
        """
        Creates a radial gradient.

        Inputs:

        center: a (x, y) tuple specifying the center shape

        radius: The radius of this radial gradient. Keep in mind this is
        measured in base-terrain tiles.

        rad_range: The (max, min) tuple that specifies the range of possible
        values. The [max] value will be at the center, the [min] value will be
        at the edge and anything past.
        """
        super(RadialGenerator, self).__init__()
        self.center = center
        self.radius = radius
        self.rad_range = rad_range

    def get_value(self, x, y):
        """
        Gets a value for the given x, y position.
        """
        c_x, c_y = self.center
        center_val, far_val = self.rad_range

        # Calculate the distance
        dist = math.sqrt( (c_x - x) ** 2 + (c_y - y) ** 2 )
        # Cap the distance at the radius length
        dist = min(dist, self.radius)
        # Convert from distance range to our value range
        value = game_util.range_convert(0, self.radius, center_val, far_val, dist)

        return value

class PerpendicularGenerator(object):
    """
    For this generator, all the values along a perpendicular line to the given
    line (that intersects at a given point) are the same value.

    Think like a Photoshop/GIMP gradient. If you stretch the tool from one
    corner to the other, you get a smooth gradient of colors where each
    diagonal is (approximately) the same color. That's the effect this
    generator is trying to recreate.
    """
    def __init__(self, rise, run, x_range, val_range=(-1.0, 1.0)):
        """
        Creates a perpendicular-linear value generator. 

        Inputs:

        rise: the rise of the generator line

        run: The run of the generator line

        x_range: The (min, max) tuple that specifies the x range of values that the
        algorithm will apply the val_range over.

        val_range: The (min, max) tuple of values that this generator will change
        between
        """
        super(PerpendicularGenerator, self).__init__()
        self.rise = rise
        self.run = run
        self.val_range = val_range
        self.x_range = x_range

    def get_value(self, x, y):
        """
        Gets a value for the given x, y position.
        """

        # Step 1: calculate our regular slope and perpendicular slope
        a = self.rise / self.run
        b = -(self.run / self.rise)

        # Step 2: calculate the y position for this X on the perpendicular line
        perp_y = b * x
        
        # Step 3: calculate how much we need to shift the perpendicular line up
        # or down to have it pass through the provided (x, y) point
        d = perp_y - y

        # Step 4: Calculate the X intersection of these two lines
        x_val = abs( d / (a - b) )

        # Step 5: Convert the x value into a value range value
        min_x, max_x = self.x_range
        min_val, max_val = self.val_range

        val = game_util.range_convert(min_x, max_x, min_val, max_val, x_val)

        return val

class PerlinGenerator(object):
    """
    This generator spits out perlin noise, based on the provided arguments.
    More or less just a wrapper for the pnoise2 function, with prepackeged
    arguments.
    """
    def __init__(self, sizes, BASE, scale=100.0, octaves=6, persistence=0.5, lacunarity=2.0):
        super(PerlinGenerator, self).__init__()
        self.X_SIZE, self.Y_SIZE = sizes
        self.BASE = BASE
        self.scale = scale
        self.octaves = octaves
        self.persistence = persistence
        self.lacunarity = lacunarity

    def get_value(self, x, y):
        return noise.pnoise2(
            x/self.scale, y/self.scale, 
            octaves=self.octaves, persistence=self.persistence,
            lacunarity=self.lacunarity, 
            repeatx=self.X_SIZE, repeaty=self.Y_SIZE, base=self.BASE
        )