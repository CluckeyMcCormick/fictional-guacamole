import random
import numpy
import math

from ctypes import c_byte

import noise

from .assets.terrain_primary import PrimaryKey

def make_voroni_points(sizes, points, choice_list):

    x_size, y_size = sizes

    # First, build some Voroni Points:
    voronis = []

    for i in range(points):
        choice = random.choice( choice_list )
        x = random.randint(0, x_size - 1)
        y = random.randint(0, y_size - 1)

        voronis.append( ( (x, y), choice ) )

    return voronis

# CRED: Credit goes to Rosetta Code's Voroni Diagram article/thing for
# at least some of this algorithm (especially the math.hypot part)
# https://rosettacode.org/wiki/Voronoi_diagram#Python

def voroni(world_raw, orders, sizes, tile_set, points, max_dist, default):
    _, y_size = sizes
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = numpy.frombuffer( world_raw.get_obj(), dtype=c_byte ).reshape( sizes )

    for x in range(first, limit):
        for y in range(y_size):
            # Find the closest point
            closest_dist = math.inf
            closest_choice = default

            # For each point...
            for coord, choice in points:
                c_x, c_y = coord
                # Calculate the distance
                dist = math.hypot( c_x - x, c_y - y )
                # If it's closer, than use that point!
                if (dist < closest_dist) and (dist < max_dist):
                    closest_dist = dist
                    closest_choice = choice
            
            # Set the current tile to the closest point type
            shaped_world[x, y] = tile_set.get_designate(closest_choice)

# Cred: https://medium.com/@yvanscher/playing-with-perlin-noise-generating-realistic-archipelagos-b59f004d8401
def perlin(world_raw, orders, sizes, tile_set, scale, octaves, persistence, lacunarity, base):
    x_size, y_size = sizes
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = numpy.frombuffer( world_raw.get_obj(), dtype=c_byte ).reshape( sizes )

    for x in range(first, limit):
        for y in range(y_size):

            value = noise.pnoise2(
                x/scale, y/scale, 
                octaves=octaves, persistence=persistence, 
                lacunarity=lacunarity, 
                repeatx=x_size, repeaty=y_size, base=base
            )

            choice = PrimaryKey.GRASS
            
            if value < -0.4:
                choice = PrimaryKey.STONE 

            elif value < -0.35:
                choice = PrimaryKey.DIRT

            elif value < 0.35:
                choice = PrimaryKey.GRASS

            elif value < 0.4:
                choice = PrimaryKey.DIRT 

            elif value < 1.0:
                choice = PrimaryKey.STONE

            # Set the current tile to the closest point type
            shaped_world[x, y] = tile_set.get_designate(choice)

def stochastic(world_raw, orders, sizes, tile_set):
    _, y_size = sizes
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = numpy.frombuffer( world_raw.get_obj(), dtype=c_byte ).reshape( sizes )

    for x in range(first, limit):
        for y in range(y_size):
            choice = random.choice( list(PrimaryKey) )
            shaped_world[x, y] = tile_set.get_designate(choice)
