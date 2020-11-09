extends KinematicBody

# Since the cubit's position is measured from the origin - which is the center
# of of the cube. However, our waypoints sit on the floor. So we need to adjust
# those incoming points vertically. 0.5 is the height of the cubit, and .001396
# was the OBSERVED remainder.
const FLOOR_DISTANCE = .001396 + 0.5

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
    $KinematicDriver.target_position = floor_position
    destination = floor_position

func _on_KinematicDriver_request_position(kine_driver, old_position):
    # Get our current position
    var curr_pos = self.global_transform.origin
    
    # The adjusted position is at the base of the cube
    kine_driver.adj_position = curr_pos - Vector3(0, FLOOR_DISTANCE, 0)

# Function called on target_reached signal from the driver
func _on_KinematicDriver_target_reached(position):
    # Save the destination so we can emit it after destroying it
    var sav_dest = destination
    # We no longer have a destination!
    destination = null
    # Send the signal up the line - echo it, in other words. Use sav_dest
    # because the position value we got handed is the adjusted value
    emit_signal("target_reached", self, sav_dest)
    
