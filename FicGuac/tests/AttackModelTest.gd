extends Spatial

# Preload our melee task (single target) so we can instance it on demand
const MELEE_SINGLE_TASK_PRELOAD = preload("res://motion_ai/common/tasking/MeleeAttackTarget.tscn")

# The thickness of the torus - in other words, the difference between the inner
# radius and the outer radius.
const TORUS_THICKNESS = .2
# The pawn can operate in three modes - outside the guiding torus, inside the
# guiding torus, and consistently dipping in and out of the guiding torus. How
# far do we deviate from the torus, be it inside or outside?
const TARGET_RADIAL_DEVIATION = .5

# Because the TargetPawn moves between points we specify, and there is some
# processing delay between reaching a point and getting a new point, the
# TargetPawn displays a weird stepping behavior if we keep giving it points that
# are too close together. To avoid this, we increase the angle-between-points
# as the torus gets smaller, and decrease it as it gets bigger.
# What's the angle step (angle-between-points) at the torus' smallest size?
const ANGLE_STEP_MIN = 30
# What's the angle step at the torus' biggest size?
const ANGLE_STEP_MAX = 5

# What's the angle we're on for this whole torus thing?
var current_angle = 0

# Was our last iteration (i.e. point) on the outside of the torus? Yes, this
# actually matters
var last_iteration_outside = false

# Called when the node enters the scene tree for the first time.
func _ready():
    # Make the Pawn path to itself. This should trigger the path_complete
    # signal, kicking off our processing loop.
    $TargetPawn.move_to_point($TargetPawn.global_transform.origin)
    
func _on_TargetPawn_path_complete(pawn, position):
    # Nab the currently configured radius, since we'll be using that
    var radius = $ControlGUI/RadiusSlider.value
    # Using the inverse_lerp function, calculate our weight between the minimum
    # radius and the maximum radius. Basically, if we're at minimum it'll be
    # 0.0; if we're at maximum, it'll be 1.0. If it's between, it'll be an
    # appropriate measure in between.
    var radial_weight = inverse_lerp(
        $ControlGUI/RadiusSlider.min_value,
        $ControlGUI/RadiusSlider.max_value,
        radius
    )
    
    # Increment the angle, applying the weight we calculated above to increment
    # by the appropriate degree.
    current_angle += lerp(ANGLE_STEP_MIN, ANGLE_STEP_MAX, radial_weight)
    # Make sure the angle is greater-than-or-equal-to 0 and less-than 360
    current_angle = fmod(current_angle, 360.0)
    
    # Calculate the new target position using MATH
    var new_target = Vector3(
        cos( deg2rad(current_angle) ),
        0,
        sin( deg2rad(current_angle) )    
    )
    
    # Scale up the new target position depending on our currently configured
    # behavior
    match $ControlGUI/BehaviorOptions.selected:
        # Outside
        0:
            new_target *= (radius + TARGET_RADIAL_DEVIATION)
            last_iteration_outside = true
        # Radial Dipping
        1:
            # If our last iteration was outside the torus radius....
            if last_iteration_outside:
                # Then go inside the torus!
                new_target *= (radius - TARGET_RADIAL_DEVIATION)
                last_iteration_outside = false
                
            # Otherwise, if our last iteration was inside the torus radius...
            else:
                # Then go outside the torus radius!
                new_target *= (radius + TARGET_RADIAL_DEVIATION)
                last_iteration_outside = true
        # Inside
        2:
            new_target *= (radius - TARGET_RADIAL_DEVIATION)
            last_iteration_outside = false
    
    # Pass it to the target pawn
    $TargetPawn.move_to_point( new_target )

func _on_RadiusSlider_value_changed(value):
    # Set the inner and outer radius values appropriately
    $CSGTorus.inner_radius = value - (TORUS_THICKNESS / 2)
    $CSGTorus.outer_radius = value + (TORUS_THICKNESS / 2)

func _on_AttackGoButton_pressed():
    match $ControlGUI/AttackOptionButton.selected:
        0:
            var task = MELEE_SINGLE_TASK_PRELOAD.instance()
            var arg_dict = {}
            
            # Create the arg_dict
            arg_dict[task.AK_ATTACK_TARGET] = $TargetPawn
            # Initialize!!!
            task.specific_initialize(arg_dict)

            # Now, assign the pawn to move ALL those items
            $AttackPawn.give_task(task)
        _:
            pass
