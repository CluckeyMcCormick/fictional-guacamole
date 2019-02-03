import random
import numpy
import math

from ctypes import c_byte

import noise

def make_voroni_points(sizes, points):

    x_size, y_size = sizes

    # First, build some Voroni Points:
    voronis = []

    for i in range(points):
        choice = random.choice( [2, 4] )
        x = random.randint(0, x_size - 1)
        y = random.randint(0, y_size - 1)

        voronis.append( ( (x, y), choice ) )

    return voronis

# CRED: Credit goes to Rosetta Code's Voroni Diagram article/thing for
# at least some of this algorithm (especially the math.hypot part)
# https://rosettacode.org/wiki/Voronoi_diagram#Python

def voroni(world_raw, orders, sizes, points, max_dist, default_choice):
    _, y_size = sizes
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = numpy.frombuffer( world_raw.get_obj(), dtype=c_byte ).reshape( sizes )

    for x in range(first, limit):
        for y in range(y_size):
            # Find the closest point
            closest_dist = math.inf
            closest_choice = default_choice

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
            shaped_world[x, y] = closest_choice

# Cred: https://medium.com/@yvanscher/playing-with-perlin-noise-generating-realistic-archipelagos-b59f004d8401
def perlin(world_raw, orders, sizes, scale, octaves, persistence, lacunarity, base):
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

            choice = 0
            
            if value < -0.4:
                choice = 4 # Stone

            elif value < -0.3:
                choice = 2 # Dirt

            elif value < 0.3:
                choice = 1 # Grass

            elif value < 0.4:
                choice = 2 # Water

            elif value < 1.0:
                choice = 4 # Ice

            """
            if 0.1 < value < 0.5:
                choice = 1
            elif -0.3 < value <= 0.1:
                choice = 2
            elif -0.7 < value <= -0.3:
                choice = 3
            elif value <= -0.7:
                choice = 4
            """

            # Set the current tile to the closest point type
            shaped_world[x, y] = choice

def stochastic(world_raw, orders, sizes):
    _, y_size = sizes
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = numpy.frombuffer( world_raw.get_obj(), dtype=c_byte ).reshape( sizes )

    for x in range(first, limit):
        for y in range(y_size):
            shaped_world[x, y] = random.randint(0, 7)