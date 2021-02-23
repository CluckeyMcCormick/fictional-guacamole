extends Spatial

# Is the visual component of this item 3D - i.e. does it consist of a mesh or
# some other such object? This enables special behaviors for how we handle this
# visual instance.
export(bool) var is_3D = false
# The initial positional offset of the VisualItemShell IF this item is 3D.
export(Vector3) var visualized_offset_3D = Vector3.ZERO
