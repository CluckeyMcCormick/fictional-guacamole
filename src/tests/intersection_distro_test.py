
import noise

import math

DISTRO_MIN = -0.5
DISTRO_MAX = 0.5

CUSTOM_MIN = 0
CUSTOM_MAX = 30 # MAX is always excluded 

X_SIZE = 250
Y_SIZE = 250

# Inclusivated
LOWER_DIV_BOUNDRY = 13
UPPER_DIV_BOUNDRY = 17

min_val = math.inf
max_val = -math.inf

def range_convert(old_min, old_max, new_min, new_max, in_val):

    val = in_val - old_min
    val /= (old_max - old_min)
    val *= new_max - new_min
    val += new_min

    return val;

def noise_to_custom(in_val):
    return range_convert(DISTRO_MIN, DISTRO_MAX, CUSTOM_MIN, CUSTOM_MAX, in_val)

def generate_value(x, y, base):
    global min_val
    global max_val

    scale = 10.0
    octaves = 10#6
    persistence = 0.5
    lacunarity = 2.0

    value = noise.pnoise2(
        x/scale, y/scale, 
        octaves=octaves, persistence=persistence, 
        lacunarity=lacunarity, 
        repeatx=X_SIZE, repeaty=Y_SIZE, base=base
    )

    if value < min_val:
        min_val = value
    elif value > max_val:
        max_val = value

    value = noise_to_custom(value)

    if value <= LOWER_DIV_BOUNDRY:
        value = 0
    elif value < UPPER_DIV_BOUNDRY:
        value = 1
    else:
        value = 2

    return value

def run():

    base_a = 1
    base_b = 2

    val_dictoria = {}

    for x in range(X_SIZE):
        for y in range(Y_SIZE):

            va = generate_value(x, y, base_a)
            vb = generate_value(x, y, base_b)

            final_value = (va, vb)

            if final_value not in val_dictoria:
                val_dictoria[final_value] = 0

            val_dictoria[final_value] += 1

    for i in val_dictoria.keys():
        print("VAL |{0}| - {1}".format(i, val_dictoria[i]))

    print("min:{0} max:{1}".format(min_val, max_val))