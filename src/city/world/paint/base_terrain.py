"""
base_terrain.py

Contains functions for generating the base terrain of the world. Meant to be
used on blank worlds, so they're generally incompatible and can produce some
undefined behavior if used together.
"""

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
def voroni(world_data, orders, tile_set, points, max_dist, default):
    _, y_size = world_data.get_sizes()
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = world_data.make_terrain_shaped()
    shaped_counts = world_data.make_counts_shaped()

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
            
            designate = tile_set.get_designate(closest_choice)

            avg_x = x // AVERAGE_ZONE_LEN
            avg_y = y // AVERAGE_ZONE_LEN

            # Update the average roster
            shaped_counts[avg_x, avg_y, designate] += 1

            # Set the current tile to the closest point type
            shaped_world[x, y] = designate

# CRED: Credit goes to Yvan Scher's article about Perlin noise in Python.
# Revelead unto me the existence of the Python noise module, and gave some an
# example to start playing with.
# https://medium.com/@yvanscher/playing-with-perlin-noise-generating-realistic-archipelagos-b59f004d8401
def perlin(world_data, orders, tile_set, scale, octaves, persistence, lacunarity, base):
    x_size, y_size = world_data.get_sizes()
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = world_data.make_terrain_shaped()
    shaped_counts = world_data.make_counts_shaped()

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

            designate = tile_set.get_designate(choice)

            avg_x = x // AVERAGE_ZONE_LEN
            avg_y = y // AVERAGE_ZONE_LEN

            # Update the average roster
            shaped_counts[avg_x, avg_y, designate] += 1

            # Set the current tile to the closest point type
            shaped_world[x, y] = designate

def only_grass(world_data, orders, tile_set):
    x_size, y_size = world_data.get_sizes()
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = world_data.make_terrain_shaped()
    shaped_counts = world_data.make_counts_shaped()

    for x in range(first, limit):
        for y in range(y_size):

            choice = PrimaryKey.GRASS

            designate = tile_set.get_designate(choice)

            avg_x = x // AVERAGE_ZONE_LEN
            avg_y = y // AVERAGE_ZONE_LEN

            # Update the average roster
            shaped_counts[avg_x, avg_y, designate] += 1

            # Set the current tile to the closest point type
            shaped_world[x, y] = designate

def stochastic(world_data, orders, tile_set):
    _, y_size = world_data.get_sizes()
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = world_data.make_terrain_shaped()
    shaped_counts = world_data.make_counts_shaped()

    choice_list = list(PrimaryKey)

    for x in range(first, limit):
        for y in range(y_size):
            choice = random.choice( choice_list )
            designate = tile_set.get_designate(choice)

            avg_x = x // AVERAGE_ZONE_LEN
            avg_y = y // AVERAGE_ZONE_LEN

            # Update the average roster
            shaped_counts[avg_x, avg_y, designate] += 1

            # Set the current tile to the closest point type
            shaped_world[x, y] = designate