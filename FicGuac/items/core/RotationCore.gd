extends Node
tool

# Depending on the item, we want different rotations depending on what mode it
# is.
enum PreferredRotation {
    Z_TALL, # The Item sits facing the Z axis, positive and negative
    Z_FLAT, # The Item lays flat, aligning with Z but facing up/down on Y
    X_TALL, # The Item sits facing the X axis, positive and negative
    X_FLAT, # The Item lays flat, aligning with X but facing up/down on Y
    HALF_TALL, # The Item is rotated 45 degrees so it is halfway between X and Y
    HALF_FLAT # The Item is rotated, straddling X & Y, laying flat (up/down)
}

# To make things easier on ourselves, we prepack the rotations described above
# into these vectors.
const Z_TALL_VEC = Vector3(  0,  0, 0)
const Z_FLAT_VEC = Vector3(-90,  0, 0)
const X_TALL_VEC = Vector3(  0, 90, 0)
const X_FLAT_VEC = Vector3(-90, 90, 0)
const HALF_TALL_VEC = Vector3(  0, 45, 0)
const HALF_FLAT_VEC = Vector3(-90, 45, 0)

# We'll put together this dictionary to help us quickly and easily translate
# PreferredRotation enum values into rotation-degree vectors.
var enum_vector_translator = {
    PreferredRotation.Z_TALL: Z_TALL_VEC,
    PreferredRotation.Z_FLAT: Z_FLAT_VEC,
    PreferredRotation.X_TALL: X_TALL_VEC,
    PreferredRotation.X_FLAT: X_FLAT_VEC,
    PreferredRotation.HALF_TALL: HALF_TALL_VEC,
    PreferredRotation.HALF_FLAT: HALF_FLAT_VEC
}

# The rotation of the item when it is in the "independent" mode. Since the body
# has active physics in this mode, it's more of a starting point.
export(PreferredRotation) var independent_rotation setget set_independet_rotation
# The rotation of the item when it is stowed - carried or stored.
export(PreferredRotation) var carried_rotation setget set_carried_rotation
# The rotation of the item when it is stowed - carried or stored.
export(PreferredRotation) var stowed_rotation setget set_stowed_rotation

# --------------------------------------------------------
#
# Setters and a getter
#
# --------------------------------------------------------

func set_independet_rotation(new_rotation):
    # Set the new rotation
    independent_rotation = new_rotation
    
    # If we're not in the Editor...
    if not Engine.editor_hint:
        var msg = "Updating Independent Rotation outside of the editor is "
        msg += "valid, but not recommended. It's mostly a configurable."
        push_warning(msg)

func set_carried_rotation(new_rotation):
    # Set the new rotation
    carried_rotation = new_rotation
    
    # If we're not in the Editor...
    if not Engine.editor_hint:
        var msg = "Updating Carried Rotation outside of the editor is valid, "
        msg += "but not recommended. It's mostly a configurable."
        push_warning(msg)

func set_stowed_rotation(new_rotation):
    # Set the new rotation
    stowed_rotation = new_rotation
    
    # If we're not in the Editor...
    if not Engine.editor_hint:
        var msg = "Updating Stowed Rotation outside of the editor is valid but "
        msg += "not recommended. It's mostly a configurable."
        push_warning(msg)

func get_independent_rotation():
    return enum_vector_translator[independent_rotation]

func get_carried_rotation():
    return enum_vector_translator[carried_rotation]
    
func get_stowed_rotation():
    return enum_vector_translator[stowed_rotation]
