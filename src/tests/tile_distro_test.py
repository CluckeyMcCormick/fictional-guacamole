
import noise

import math

DISTRO_MIN = -0.5
DISTRO_MAX = 0.5

CUSTOM_MIN = 0
CUSTOM_MAX = 100

X_SIZE = 250
Y_SIZE = 250

def range_convert(old_min, old_max, new_min, new_max, in_val):

    val = in_val - old_min
    val /= (old_max - old_min)
    val *= new_max - new_min
    val += new_min

    return val;

def noise_to_custom(in_val):
    return range_convert(DISTRO_MIN, DISTRO_MAX, CUSTOM_MIN, CUSTOM_MAX, in_val)

def run():

    base = 1
    scale = 10.0
    octaves = 10#6
    persistence = 0.5
    lacunarity = 2.0

    val_dictoria = {}

    min_val = math.inf
    max_val = -math.inf

    for i in range(CUSTOM_MIN, CUSTOM_MAX + 1):
        val_dictoria[i] = 0

    for x in range(X_SIZE):
        for y in range(Y_SIZE):
            value = noise.pnoise2(
                x/scale, y/scale, 
                octaves=octaves, persistence=persistence, 
                lacunarity=lacunarity, 
                repeatx=X_SIZE, repeaty=Y_SIZE, base=base
            )

            #print(value)

            if value < min_val:
                min_val = value
            elif value > max_val:
                max_val = value

            #continue

            value = noise_to_custom(value)

            if int(value) in val_dictoria:
                val_dictoria[int(value)] += 1

    for i in range(CUSTOM_MIN, CUSTOM_MAX + 1):
        print("VAL |{0}| - {1}".format(i, val_dictoria[i]))

    print("min:{0} max:{1}".format(min_val, max_val))