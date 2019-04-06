
from PIL import Image

import game_util
from city.world import generator

VALUE_MIN = -400
VALUE_MAX = 0

PIXEL_MIN = 0
PIXEL_MAX = 2 ** 8 # 8 bit maximum value

IMAGE_SIZE = 400

def bandw_convert(in_val):
    new_val = game_util.range_convert(VALUE_MIN, VALUE_MAX, PIXEL_MIN, PIXEL_MAX, in_val)
    new_val = max( PIXEL_MIN, min( new_val, PIXEL_MAX ) )

    return new_val

def run():

    im = Image.new('L', (IMAGE_SIZE, IMAGE_SIZE) )

    pixels = im.load()

    gennies = [
        generator.PerlinGenerator( (IMAGE_SIZE, IMAGE_SIZE), 0),
        generator.PerpendicularGenerator(1, 1, (0, IMAGE_SIZE), val_range=(0, IMAGE_SIZE))
    ]

    for x in range(IMAGE_SIZE):
        for y in range(IMAGE_SIZE):
            # Sum up this value across all the provided generators
            value = 0
            for gen in gennies:
                value += gen.get_value(x, y)

            # Write the pixel result. Have to do (IMAGE_SIZE - 1) - y to make
            # sure (0, 0) is in the lower-left corner.
            pixels[x, (IMAGE_SIZE - 1) - y] = int(bandw_convert(value))

    im.save("watershed_heightmap.png")

