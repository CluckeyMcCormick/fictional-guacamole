extends Node

# These functions need to return two different items - a PoolVector2Array and a
# PoolVector3Array. Since GDScript lacks custom classes, and there's no
# returning multiple values, we'll pack our return values into a dictionary.
# We'll get the values out using these key constants.
const VECTOR3_KEY = "vertex_pool_array"
const VECTOR2_KEY = "uv_pool_array"

# --------------------------------------------------------
#
# Simple Face Creation
#
# --------------------------------------------------------
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

# Creates a face where the position on the Y-axis is locked. The user can
# control what direction is "upwards" by manipulating pointA and pointB
# appropriately. UV coordinates must be provided as uvA and uvB.
static func create_ylock_face(
    pointA : Vector2, pointB : Vector2, y_pos : float,
    uvA : Vector2, uvB : Vector2
):
    var v2 = PoolVector2Array()
    var v3 = PoolVector3Array()
    
    var A3 = Vector3(pointA.x, y_pos, pointA.y)
    var B3 = Vector3(pointB.x, y_pos, pointB.y)
    var Ad3 = Vector3(pointA.x, y_pos, pointB.y)
    var Bd3 = Vector3(pointB.x, y_pos, pointA.y)

    var A2 = uvA
    var B2 = uvB
    var Ad2 = Vector2(uvA.x, uvB.y)
    var Bd2 = Vector2(uvB.x, uvA.y)
    
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

# Wrapper for the above function - allows the user to specify just floats for
# the UV coordinates, rather than Vector2 types. The y values are taken from the
# two vertex points.
static func create_ylock_face_linear(
    pointA : Vector2, pointB : Vector2, y_pos : float,
    uvA: float, uvB : float
):
    var new_uvA = Vector2(uvA, pointA.y)
    var new_uvB = Vector2(uvB, pointB.y)
    return create_ylock_face(pointA, pointB, y_pos, new_uvA, new_uvB)

# Wrapper for the regular create_xlock_face function. This one passes the
# two vertex points as the UV points, but shifts them by the appropriate values
# in the uv_shift vector. This creates a face that is shifted from it's position
# in texture space. This is intended as a workaround for shifting textures when
# the face was constructed away from it's intended destination. Or we just wanna
# shift the texture around.
static func create_ylock_face_shifted(
    pointA : Vector2, pointB : Vector2, y_pos : float,
    uv_shift: Vector3
):
    # Determine the degree of shifting
    var boiled_shift = Vector2(uv_shift.x, uv_shift.z)
    # Calculate the new UV coordinates
    var uvA = pointA + boiled_shift
    var uvB = pointB + boiled_shift
    
    return create_ylock_face(pointA, pointB, y_pos, uvA, uvB)

# Wrapper for the regular create_xlock_face function, but this one passes the
# two vertex points as the UV points, creating a face that has the UV values
# aligned with it's initial position in space. 
static func create_ylock_face_simple(
    pointA : Vector2, pointB : Vector2, y_pos : float
):
    return create_ylock_face(pointA, pointB, y_pos, pointA, pointB)
  
# Creates a face where the position on the X-axis is locked. The user can
# control what direction is the "front" by manipulating pointA and pointB
# appropriately. I've also observed that the texture of vertical faces is often
# inverted, so an option is provided to invert the texture vertically - it is
# enabled by default. UV coordinates must be provided as uvA and uvB.
static func create_xlock_face(
    pointA : Vector2, pointB : Vector2, x_pos : float,
    uvA : Vector2, uvB : Vector2, invert_UV_y : bool = true
):
    var v2 = PoolVector2Array()
    var v3 = PoolVector3Array()
    
    var A3 = Vector3(x_pos, pointA.y, pointA.x)
    var B3 = Vector3(x_pos, pointB.y, pointB.x)
    var Ad3 = Vector3(x_pos, pointB.y, pointA.x)
    var Bd3 = Vector3(x_pos, pointA.y, pointB.x)

    var A2 = uvA
    var B2 = uvB
    var Ad2 = Vector2(uvA.x, uvB.y)
    var Bd2 = Vector2(uvB.x, uvA.y)
    
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

# Wrapper for the above function - allows the user to specify just floats for
# the UV coordinates, rather than Vector2 types. The y values are taken from the
# two vertex points. This was originally implemented for walls with textures
# that met up vertically but not horizontally.
static func create_xlock_face_linear(
    pointA : Vector2, pointB : Vector2, x_pos : float,
    uvA: float, uvB : float, invert_UV_y: bool = true
):
    var new_uvA = Vector2(uvA, pointA.y)
    var new_uvB = Vector2(uvB, pointB.y)
    return create_xlock_face(pointA, pointB, x_pos, new_uvA, new_uvB, invert_UV_y)

# Wrapper for the regular create_xlock_face function. This one passes the
# two vertex points as the UV points, but shifts them by the appropriate values
# in the uv_shift vector. This creates a face that is shifted from it's position
# in texture space. This is intended as a workaround for shifting textures when
# the face was constructed away from it's intended destination. Or we just wanna
# shift the texture around.
static func create_xlock_face_shifted(
    pointA : Vector2, pointB : Vector2, x_pos : float,
    uv_shift: Vector3, invert_UV_y: bool = true
):
    # Determine the degree of shifting
    var boiled_shift = Vector2(uv_shift.z, uv_shift.y)
    # Calculate the new UV coordinates
    var uvA = pointA + boiled_shift
    var uvB = pointB + boiled_shift
    
    return create_xlock_face(pointA, pointB, x_pos, uvA, uvB, invert_UV_y)

# Wrapper for the regular create_xlock_face function, but this one passes the
# two vertex points as the UV points, creating a face that has the UV values
# aligned with it's initial position in space. 
static func create_xlock_face_simple(
    pointA : Vector2, pointB : Vector2, x_pos : float, invert_UV_y: bool = true
):
    return create_xlock_face(pointA, pointB, x_pos, pointA, pointB, invert_UV_y)

# Creates a face where the position on the Z-axis is locked. The user can
# control what direction is the "front" by manipulating pointA and pointB
# appropriately. I've also observed that the texture of vertical faces is often
# inverted, so an option is provided to invert the texture vertically - it is
# enabled by default.
static func create_zlock_face(
    pointA : Vector2, pointB : Vector2, z_pos : float, 
    uvA : Vector2, uvB : Vector2, invert_UV_y: bool = true
):
    var v2 = PoolVector2Array()
    var v3 = PoolVector3Array()
    
    var A3 = Vector3(pointA.x, pointA.y, z_pos)
    var B3 = Vector3(pointB.x, pointB.y, z_pos)
    var Ad3 = Vector3(pointA.x, pointB.y, z_pos)
    var Bd3 = Vector3(pointB.x, pointA.y, z_pos)

    var A2 = uvA
    var B2 = uvB
    var Ad2 = Vector2(uvA.x, uvB.y)
    var Bd2 = Vector2(uvB.x, uvA.y)
    
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

# Wrapper for the above function - allows the user to specify just floats for
# the UV coordinates, rather than Vector2 types. The y values are taken from the
# two vertex points. This was originally implemented for walls with textures
# that met up vertically but not horizontally.
static func create_zlock_face_linear(
    pointA : Vector2, pointB : Vector2, z_pos : float,
    uvA: float, uvB : float, invert_UV_y: bool = true
):
    var new_uvA = Vector2(uvA, pointA.y)
    var new_uvB = Vector2(uvB, pointB.y)
    return create_zlock_face(pointA, pointB, z_pos, new_uvA, new_uvB, invert_UV_y)

# Wrapper for the regular create_zlock_face function. This one passes the
# two vertex points as the UV points, but shifts them by the appropriate values
# in the uv_shift vector. This creates a face that is shifted from it's position
# in texture space. This is intended as a workaround for shifting textures when
# the face was constructed away from it's intended destination. Or we just wanna
# shift the texture around.
static func create_zlock_face_shifted(
    pointA : Vector2, pointB : Vector2, z_pos : float,
    uv_shift: Vector3, invert_UV_y: bool = true
):
    # Determine the degree of shifting
    var boiled_shift = Vector2(uv_shift.x, uv_shift.y)
    # Calculate the new UV coordinates
    var uvA = pointA + boiled_shift
    var uvB = pointB + boiled_shift
    
    return create_zlock_face(pointA, pointB, z_pos, uvA, uvB, invert_UV_y)

# Wrapper for the regular create_zlock_face function, but this one passes the
# two vertex points as the UV points, creating a face that has the UV values
# aligned with it's initial position in space. 
static func create_zlock_face_simple(
    pointA : Vector2, pointB : Vector2, z_pos : float, invert_UV_y: bool = true
):
    return create_zlock_face(pointA, pointB, z_pos, pointA, pointB, invert_UV_y)
