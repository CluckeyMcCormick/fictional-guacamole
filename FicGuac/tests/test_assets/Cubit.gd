extends KinematicBody

# Since the cubit's position is measured from the origin - which is the center
# of of the cube. However, our waypoints sit on the floor. So we need to adjust
# those incoming points vertically. 0.5 is the height of the cubit, and .001396
# was the OBSERVED remainder.
const FLOOR_DISTANCE_ADD = .001396 + 0.5

# Signal issued when this cubit reaches it's target. Includes the specific cubit
# and the cubit's current position (which will be effectively the same as the
# previous target).
signal target_reached(cubit, position)

# This is the destination, which we update when set_destination is called
var destination setget set_destination

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Kinematic Driver coupling functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Set the destination of this Cubit. The position must be on the floor. For most
# purposes (like path following), this is naturally where the point will be.
func set_destination(floor_position : Vector3):
    # Shift the floor position so it will align with this node's origin. By
    # making the specific to each sub/scene, we can ensure modularity
    var adjusted_pos = floor_position + Vector3(0, FLOOR_DISTANCE_ADD, 0)
    $KinematicDriver.target_position = adjusted_pos
    destination = adjusted_pos

# Function called on target_reached signal from the driver
func _on_KinematicDriver_target_reached(position):
    # Save the destination so we can emit it after destroying it
    var sav_dest = destination
    # We no longer have a destination!
    destination = null
    # Send the signal up the line - echo it, in other words. Use sav_dest
    # because the position value we got handed is the adjusted value
    emit_signal("target_reached", self, sav_dest)
    
