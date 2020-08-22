extends Node

# These functions need to return two different items - a PoolVector2Array and a
# PoolVector3Array. Since GDScript lacks custom classes, and there's no
# returning multiple values, we'll pack our return values into a dictionary.
# We'll get the values out using these key constants.
const VECTOR3_KEY = "vertex_pool_array"
const VECTOR2_KEY = "uv_pool_array"

# Most of the functions in this utility script draw rectangular polygons using
# only two points: A and B. That's because we can draw simple rectangular faces
# like so:
#
#       B-----------------Ad      Given A and B, where A and B are both Vector2
#       |                  |      values, drawing a polygon is trivial! All we
#       |                  |      need is a constant (that will change with the
#       Bd-----------------A      type of face).
#
# We'll use the designations A-derivative ("Ad") and B-derivative ("Bd") to
# refer to the derived points as designated above.

static func create_upward_face(pointA : Vector2, pointB : Vector2, height : float):
    var v2 = PoolVector2Array()
    var v3 = PoolVector3Array()
    
    # Triangle 1
    v3.append( Vector3(pointA.x, height, pointA.y) ) # A
    v3.append( Vector3(pointB.x, height, pointB.y) ) # B
    v3.append( Vector3(pointA.x, height, pointB.y) ) # Ad
    v2.append( pointA ) # A
    v2.append( pointB ) # B
    v2.append( Vector2(pointA.x, pointB.y) ) # Ad
    
    # Triangle 2
    v3.append( Vector3(pointA.x, height, pointA.y) ) # A
    v3.append( Vector3(pointB.x, height, pointA.y) ) # Bd
    v3.append( Vector3(pointB.x, height, pointB.y) ) # B
    v2.append( pointA ) # A
    v2.append( Vector2(pointB.x, pointA.y) ) # Bd
    v2.append( pointB ) # B

    # Pack the pool arrays into a dictionary
    return {VECTOR3_KEY: v3, VECTOR2_KEY: v2}

# Creates a face where the position on the X-axis is locked. The user can
# control what direction is the "front" by manipulating pointA and pointB
# appropriately. I've also observed that the texture of vertical faces is often
# inverted, so an option is provided to invert the texture vertically - it is
# enabled by default.
static func create_xlock_face(
    pointA : Vector2, pointB : Vector2, x_pos : float, invert_UV_y: bool = true
):
    var v2 = PoolVector2Array()
    var v3 = PoolVector3Array()
    
    var A3 = Vector3(x_pos, pointA.y, pointA.x)
    var B3 = Vector3(x_pos, pointB.y, pointB.x)
    var Ad3 = Vector3(x_pos, pointB.y, pointA.x)
    var Bd3 = Vector3(x_pos, pointA.y, pointB.x)

    var A2 = pointA
    var B2 = pointB
    var Ad2 = Vector2(pointA.x, pointB.y)
    var Bd2 = Vector2(pointB.x, pointA.y)
    
    if invert_UV_y:
        A2.y = -A2.y
        B2.y = -B2.y
        Ad2.y = -Ad2.y
        Bd2.y = -Bd2.y
    
    # Triangle 1
    v3.append( A3 ) # A
    v3.append( B3 ) # B
    v3.append( Ad3 ) # Ad
    v2.append( A2 ) # A
    v2.append( B2 ) # B
    v2.append( Ad2 ) # Ad

    # Triangle 2
    v3.append( A3 ) # A
    v3.append( Bd3 ) # Bd
    v3.append( B3 ) # B
    v2.append( A2 ) # A
    v2.append( Bd2 ) # Bd
    v2.append( B2 ) # B

    return {VECTOR3_KEY: v3, VECTOR2_KEY: v2}

# Creates a face where the position on the Z-axis is locked. The user can
# control what direction is the "front" by manipulating pointA and pointB
# appropriately. I've also observed that the texture of vertical faces is often
# inverted, so an option is provided to invert the texture vertically - it is
# enabled by default.
static func create_zlock_face(
    pointA : Vector2, pointB : Vector2, z_pos : float, invert_UV_y: bool = true
):
    var v2 = PoolVector2Array()
    var v3 = PoolVector3Array()
    
    var A3 = Vector3(pointA.x, pointA.y, z_pos)
    var B3 = Vector3(pointB.x, pointB.y, z_pos)
    var Ad3 = Vector3(pointA.x, pointB.y, z_pos)
    var Bd3 = Vector3(pointB.x, pointA.y, z_pos)

    var A2 = pointA
    var B2 = pointB
    var Ad2 = Vector2(pointA.x, pointB.y)
    var Bd2 = Vector2(pointB.x, pointA.y)
    
    if invert_UV_y:
        A2.y = -A2.y
        B2.y = -B2.y
        Ad2.y = -Ad2.y
        Bd2.y = -Bd2.y
    
    # Triangle 1
    v3.append( A3 ) # A
    v3.append( B3 ) # B
    v3.append( Ad3 ) # Ad
    v2.append( A2 ) # A
    v2.append( B2 ) # B
    v2.append( Ad2 ) # Ad

    # Triangle 2
    v3.append( A3 ) # A
    v3.append( Bd3 ) # Bd
    v3.append( B3 ) # B
    v2.append( A2 ) # A
    v2.append( Bd2 ) # Bd
    v2.append( B2 ) # B

    return {VECTOR3_KEY: v3, VECTOR2_KEY: v2}

# This function works like the xlock_face function above, but with a special
# exception - the user can pass in UV values for point A and point B. These
# values are used in the x component of the UV vectors. This is meant to be used
# for creating continous textures across non-continous surfaces
static func create_xlock_face_uv(
    pointA : Vector2, pointB : Vector2, x_pos : float, uvA: float, uvB : float,
    invert_UV_y: bool = true
):
    var v2 = PoolVector2Array()
    var v3 = PoolVector3Array()
    
    var A3 = Vector3(x_pos, pointA.y, pointA.x)
    var B3 = Vector3(x_pos, pointB.y, pointB.x)
    var Ad3 = Vector3(x_pos, pointB.y, pointA.x)
    var Bd3 = Vector3(x_pos, pointA.y, pointB.x)

    var A2 = Vector2(uvA, pointA.y)
    var B2 = Vector2(uvB, pointB.y)
    var Ad2 = Vector2(uvA, pointB.y)
    var Bd2 = Vector2(uvB, pointA.y)
    
    if invert_UV_y:
        A2.y = -A2.y
        B2.y = -B2.y
        Ad2.y = -Ad2.y
        Bd2.y = -Bd2.y
    
    # Triangle 1
    v3.append( A3 ) # A
    v3.append( B3 ) # B
    v3.append( Ad3 ) # Ad
    v2.append( A2 ) # A
    v2.append( B2 ) # B
    v2.append( Ad2 ) # Ad

    # Triangle 2
    v3.append( A3 ) # A
    v3.append( Bd3 ) # Bd
    v3.append( B3 ) # B
    v2.append( A2 ) # A
    v2.append( Bd2 ) # Bd
    v2.append( B2 ) # B

    return {VECTOR3_KEY: v3, VECTOR2_KEY: v2}

# This is also a custom UV function, just for a z-locked surface
static func create_zlock_face_uv(
    pointA : Vector2, pointB : Vector2, z_pos : float, uvA: float, uvB : float, 
    invert_UV_y: bool = true
):
    var v2 = PoolVector2Array()
    var v3 = PoolVector3Array()
    
    var A3 = Vector3(pointA.x, pointA.y, z_pos)
    var B3 = Vector3(pointB.x, pointB.y, z_pos)
    var Ad3 = Vector3(pointA.x, pointB.y, z_pos)
    var Bd3 = Vector3(pointB.x, pointA.y, z_pos)

    var A2 = Vector2(uvA, pointA.y)
    var B2 = Vector2(uvB, pointB.y)
    var Ad2 = Vector2(uvA, pointB.y)
    var Bd2 = Vector2(uvB, pointA.y)
    
    if invert_UV_y:
        A2.y = -A2.y
        B2.y = -B2.y
        Ad2.y = -Ad2.y
        Bd2.y = -Bd2.y
    
    # Triangle 1
    v3.append( A3 ) # A
    v3.append( B3 ) # B
    v3.append( Ad3 ) # Ad
    v2.append( A2 ) # A
    v2.append( B2 ) # B
    v2.append( Ad2 ) # Ad

    # Triangle 2
    v3.append( A3 ) # A
    v3.append( Bd3 ) # Bd
    v3.append( B3 ) # B
    v2.append( A2 ) # A
    v2.append( Bd2 ) # Bd
    v2.append( B2 ) # B

    return {VECTOR3_KEY: v3, VECTOR2_KEY: v2}
