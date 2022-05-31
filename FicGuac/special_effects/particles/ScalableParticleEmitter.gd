extends Particles

const MAXI_X_ANGLE_DEG = 0
const MINI_X_ANGLE_DEG = 180
const MAXI_Y_ANGLE_DEG = 90
const MINI_Y_ANGLE_DEG = 270

# What's the ParticleReadySpatialMaterial that we'll use as the override
# material for this system?
export(Resource) var blueprint = null setget set_blueprint

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    # Skip all of this debug nonsense, for now.
    return
    
    # Start DEBUG nonsense
    var dd = get_node("/root/DebugDraw")
    
    var d_origin = self.global_transform.origin
    var d_end = self.visibility_aabb.end
    var d_position = self.visibility_aabb.position
    
    # Scaled Z
    dd.draw_line_3d(
        d_origin + (d_position * self.scale),
        d_origin + (d_end * self.scale),
        Color.white
    )
    dd.draw_line_3d(
        d_origin + (d_position * self.scale),
        d_origin + (Vector3(d_end.x, d_position.y, d_end.z) * self.scale),
        Color.white
    )
    dd.draw_line_3d(
        d_origin + (d_end * self.scale),
        d_origin + (Vector3(d_position.x, d_end.y, d_position.z) * self.scale),
        Color.white
    )
    
    dd.draw_box(
        d_origin - (self.process_material.emission_box_extents / 2),
        self.process_material.emission_box_extents,
        Color.springgreen
    )
    dd.draw_box(
        d_origin - ((self.process_material.emission_box_extents * self.scale) / 2),
        self.process_material.emission_box_extents * self.scale,
        Color.crimson
    )

func set_blueprint(new_blueprint : ScalableParticleBlueprint):
    # Used to count the number of passes (drawn meshes). Saves us from having to
    # manually set the pass count.
    var pass_count = 0

    # Used to verify each draw pass
    var draws = []
    
    # First off, if the object we got handed is not a Scalable Particle
    # Blueprint, we can't really do much of anything can we? Inform the user and
    # back out.
    if not new_blueprint is ScalableParticleBlueprint:
        printerr("Attempted to give non-SPB resource to scalable emitter.")
        printerr("Please use a ScalableParticleBlueprint.")
        return

    # Now we can check the prsm field to verify that it is a
    # ParticleReadySpatialMaterial.
    if not new_blueprint.prsm is ParticleReadySpatialMaterial:
        printerr("Scaleable emitter's blueprint had a non-PSRM override material!")
        printerr("Please use a ParticleReadySpatialMaterial.")
        return

    # Also verify that it has an appropriate particle material
    if (not new_blueprint.particle_material is ParticlesMaterial) and \
        (not new_blueprint.particle_material is ShaderMaterial):
        printerr("Error with scaleable emitter's blueprint particle material!")
        printerr("The material is absent or not a ParticlesMaterial or ShaderMaterial.")
        return

    # If the particle material is a proper ParticlesMaterial...
    if new_blueprint.particle_material is ParticlesMaterial:
        # Ensure the blueprint's particle material is one of our "valid" shapes
        match new_blueprint.particle_material.emission_shape:
            ParticlesMaterial.EMISSION_SHAPE_POINT:
                pass
            ParticlesMaterial.EMISSION_SHAPE_SPHERE:
                pass
            ParticlesMaterial.EMISSION_SHAPE_BOX:
                pass
            _:
                printerr(
                    "Invalid Scalable Particles EmissionShape: ",
                    new_blueprint.particle_material.emission_shape
                )
                return
    # Otherwise, this must be a ShaderMaterial, which doesn't actually have an
    # emission shape. We'll just have to assume it's a 1x1x1 box.
    
    # Okay, now we need to verify that the draw passes found in the blueprint's
    # prsm (ParticleReadySpatialMaterial) are supported. So, pack the draw
    # passes into an array for ease-of-iteration.
    draws = [
        new_blueprint.prsm.pass_1, new_blueprint.prsm.pass_2,
        new_blueprint.prsm.pass_3, new_blueprint.prsm.pass_4
    ]   
    
    # For each draw pass, verify that it's valid.
    for d in draws:
        if d == null:
            continue
        if d is QuadMesh:
            continue
        elif d is CubeMesh:
            continue
        else:
            printerr("Only QuadMesh and CubeMesh are supported draw types")
            return

    # If we're here, then... everything looks good, I guess! Set the blueprint,
    # then set the process material and override material given by the
    # blueprint.
    blueprint = new_blueprint
    self.process_material = blueprint.particle_material
    self.material_override = blueprint.prsm

    # Default the number of draw passes
    self.draw_passes = 4
    
    # Now we need to set the passes. First, we'll just move over all of the
    # passes.
    self.draw_pass_1 = material_override.pass_1
    self.draw_pass_2 = material_override.pass_2
    self.draw_pass_3 = material_override.pass_3
    self.draw_pass_4 = material_override.pass_4
    
    # Now we'll count out how many of those AREN'T null and, thus, our pass
    # count!
    if self.draw_pass_1 != null:
        pass_count += 1
    if self.draw_pass_2 != null:
        pass_count += 1
    if self.draw_pass_3 != null:
        pass_count += 1
    if self.draw_pass_4 != null:
        pass_count += 1
    
    # Set the ACTUAL pass count
    self.draw_passes = pass_count
    
    # Now move over all of the "recommended" variables
    self.lifetime = blueprint.rcmnd_lifetime
    self.one_shot = blueprint.rcmnd_one_shot
    self.preprocess = blueprint.rcmnd_preprocess
    self.speed_scale = blueprint.rcmnd_speed_scale
    self.explosiveness = blueprint.rcmnd_explosiveness
    self.randomness = blueprint.rcmnd_randomness
    self.fixed_fps = blueprint.rcmnd_fixed_fps
    self.fract_delta = blueprint.rcmnd_fract_delta
    
func scale_emitter(new_scale : Vector3):
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    # Step 0: Verification
    #
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if self.process_material == null:
        printerr("No process material to scale with!!!")
        return
    if (not process_material is ParticlesMaterial) and \
        (not process_material is ShaderMaterial):
        printerr("Error with scaleable emitter's particle material!")
        printerr("The material is neither a ParticlesMaterial nor a ShaderMaterial.")
        return
    if not self.material_override is ParticleReadySpatialMaterial:
        printerr("Current override material is not a Partical Ready Material!!!")
        return
    
    # Used to verify each draw pass
    var draws = [
        self.material_override.pass_1, self.material_override.pass_2,
        self.material_override.pass_3, self.material_override.pass_4
    ]

    for d in draws:
        if d == null:
            continue
        if d is QuadMesh:
            continue
        elif d is CubeMesh:
            continue
        else:
            printerr("Only QuadMesh and CubeMesh are supported draw types")
            return
    
    # First, we need to determine the maximum possible length required for the
    # spawn box. 
    var spawn_len_x
    var spawn_len_y
    var spawn_len_z

    # Then we'll need to determine how far the particles can make it once
    # they've started spawning. We need to do this for each axis on each
    # direction - hence "max" is positive and "min" is negative.
    var max_x
    var min_x
    var max_y
    var min_y
    var max_z
    var min_z

    # We'll use these to calculate emission ranges on a given axis.
    var xy = Vector2.ZERO
    var xz = Vector2.ZERO
    var zy = Vector2.ZERO

    # Temp variable - we'll need this.
    var temp
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    # Step 1: Calculate spawn box
    #
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    # Okay, first we're gonna start with the spawn stuff, which is actually
    # pretty easy. All we need to do is take the right value, depending on our
    # emission shape. If this is a ParticlesMaterial...
    if process_material is ParticlesMaterial:
        match self.process_material.emission_shape:
            # If we're emitting from a single point, then there's nothing we
            # need to do here.
            ParticlesMaterial.EMISSION_SHAPE_POINT:
                spawn_len_x = 0
                spawn_len_y = 0
                spawn_len_z = 0
                self.amount = self.blueprint.base_particle_count
            # If we're emitting in a sphere-shape, then the length for each is
            # the diameter of the sphere.
            ParticlesMaterial.EMISSION_SHAPE_SPHERE:
                # Grab the radius
                temp = self.process_material.emission_sphere_radius
                # Set the spawn lengths
                spawn_len_x = self.temp
                spawn_len_y = self.temp
                spawn_len_z = self.temp
                # Now, calculate the volume
                temp = (4/3) * PI \
                    * (spawn_len_x * new_scale.x) \
                    * (spawn_len_y * new_scale.y) \
                    * (spawn_len_z * new_scale.z)
                # The amount of particles to spawn is our base...
                self.amount = self.blueprint.base_particle_count
                # ... PLUS the cubic root of the volume * the density.
                self.amount += int(
                    pow(temp, 1.0/3.0) * self.blueprint.root_particle_slope
                )
                # Finally, double the spawn lengths (since we want the
                # diameters)
                spawn_len_x *= 2
                spawn_len_y *= 2
                spawn_len_z *= 2
                
            # If we're emitting in a box-shape, then grab the length for each
            # side of the box.
            ParticlesMaterial.EMISSION_SHAPE_BOX:
                # Set the spawn lengths - * 2 because these are EXTENTS, not
                # sizes
                spawn_len_x = self.process_material.emission_box_extents.x * 2
                spawn_len_y = self.process_material.emission_box_extents.y * 2
                spawn_len_z = self.process_material.emission_box_extents.z * 2
                # Calculate the volume, using the scale
                temp = (spawn_len_x * new_scale.x) \
                    * (spawn_len_y * new_scale.y) \
                    * (spawn_len_z * new_scale.z)
                # The amount of particles to spawn is is our base...
                self.amount = self.blueprint.base_particle_count
                # ... PLUS the cubic root of the volume * the density.
                self.amount += int(
                    pow(temp, 1.0/3.0) * self.blueprint.root_particle_slope
                )
            _:
                printerr(
                    "Invalid Particle Material EmissionShape: ", 
                    self.process_material.emission_shape
                )
                return
    # Otherwise, this MUST be a ShaderMaterial, hopefully set to Particles mode.
    # So...
    else:
        # We're just going to charitably assume that the ShaderMaterial is
        # emitting in a 1x1x1 box. Ergo, we can just carry over the scale
        # straight.
        spawn_len_x = new_scale.x
        spawn_len_y = new_scale.y
        spawn_len_z = new_scale.z
    
    # Now, technically, the max we can over-extend on a side is by half of the
    # size hint. However, since we'd do that at both sides, that adds up to the
    # whole of the size hint. Ergo, we just add in the size hint Easy!
    spawn_len_x += self.material_override.particle_size_hint.x
    spawn_len_y += self.material_override.particle_size_hint.y
    spawn_len_z += self.material_override.particle_size_hint.z
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    # Step 2: Calculate possible unit movement, per-axis per-direction
    #
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Right, get ready for some real trigonometric BS. We need to calculate how
    # far a particle could possibly move on a given axis in either direction.
    # Now, the easiest thing to assume is that a particle has full movement on
    # an axis - think of a series of particles being shot out along each in each
    # direction at maximum possible velocity and acceleration. However, that's
    # not how things work - with the particle material's SPREAD value and
    # DIRECTION vector, this gets tricky.
    #
    # See, the particles are "shot" in a given direction as specified by the
    # DIRECTION unit vector. The SPREAD value specifies, in degrees, the
    # plus-or-minus angle variance FROM THE DIRECTION. So, in order to calculate
    # maximum or minimum possible distances on each axis, we need to calculate
    # unit distances on each axis, in each direction.
    # So, first, if this is a ParticlesMaterial...
    if process_material is ParticlesMaterial:
        # Then devolve the direction Vector3 in 3 Vector2 pairings.
        xy.x = self.process_material.direction.x
        xy.y = self.process_material.direction.y
        xz.x = self.process_material.direction.x
        xz.y = self.process_material.direction.z
        zy.x = self.process_material.direction.z
        zy.y = self.process_material.direction.y
    # Otherwise, this MUST be a ShaderMaterial. So...
    else:
        # Then there's not REALLY a direction for us to work with - let's just
        # set everything to zero.
        xy = Vector2.ZERO
        xz = Vector2.ZERO
        zy = Vector2.ZERO
    
    # Next, we'll calculate the maximum and minimum angles (the angles that get
    # us the highest or lowest possible values from cos and sin) for each axis
    # using the calculate_maxi_angles & calculate_mini_angles functions. We'll
    # then take the output and "unitize" it by feeding it through either cosine
    # or sine. Since each axis gets to go twice for both
    # First up, X-Y
    temp = calculate_maxi_angles(xy)
    max_x = cos( deg2rad(temp.x) )
    max_y = sin( deg2rad(temp.y) )
    temp = calculate_mini_angles(xy)
    min_x = cos( deg2rad(temp.x) )
    min_y = sin( deg2rad(temp.y) )
    # Next, X-Z
    temp = calculate_maxi_angles(xz)
    max_x = max( cos( deg2rad(temp.x) ), max_x)
    max_z = sin( deg2rad(temp.y) )
    temp = calculate_mini_angles(xz)
    min_x = min( cos( deg2rad(temp.x) ), min_x)
    min_z = sin( deg2rad(temp.y) )
    # Finally, Z-Y
    temp = calculate_maxi_angles(zy)
    max_z = max( cos( deg2rad(temp.x) ), max_z)
    max_y = max( sin( deg2rad(temp.y) ), max_y)
    temp = calculate_mini_angles(zy)
    min_z = min( cos( deg2rad(temp.x) ), min_z)
    min_y = min( sin( deg2rad(temp.y) ), min_y)
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    # Step 3: Calculate the maximum displacement in each direction on each
    #         axis, given the calculated unit_weight, scale, and gravity.
    #
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # If this is a ParticlesMaterial...
    if process_material is ParticlesMaterial:
        # Then we can calculate the displacement using the particle material's
        # gravity.
        # X
        max_x = displacement(
            max_x, new_scale.x, self.process_material.gravity.x
        )
        min_x = displacement(
            min_x, new_scale.x, self.process_material.gravity.x
        )
        # Y
        max_y = displacement(
            max_y, new_scale.y, self.process_material.gravity.y
        )
        min_y = displacement(
            min_y, new_scale.y, self.process_material.gravity.y
        )
        # Z
        max_z = displacement(
            max_z, new_scale.z, self.process_material.gravity.z
        )
        min_z = displacement(
            min_z, new_scale.z, self.process_material.gravity.z
        )
    
    # Now, the MAX values need to be the MAX possible, and the MIN values need
    # to be the MIN possible - so we'll ensure that all MAX >= 0 & all MIN <= 0.
    # X
    max_x = max(max_x, 0)
    min_x = min(min_x, 0)
    # Y
    max_y = max(max_y, 0)
    min_y = min(min_y, 0)
    # Z
    max_z = max(max_z, 0)
    min_z = min(min_z, 0)

    #print("Spawn Lengths: ", spawn_len_x, " ", spawn_len_y, " ", spawn_len_z)
    #print("    Maxi ", max_x, " ", max_y, " ", max_z)
    #print("    Mini ", min_x, " ", min_y, " ", min_z)

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    # Step 4: AABB Construction
    #
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    # Add in the spawn lengths
    max_x += spawn_len_x / 2
    min_x -= spawn_len_x / 2
    max_y += spawn_len_y / 2
    min_y -= spawn_len_y / 2
    max_z += spawn_len_z / 2
    min_z -= spawn_len_z / 2
    
    self.visibility_aabb.position.x = min_x
    self.visibility_aabb.position.y = min_y
    self.visibility_aabb.position.z = min_z
    self.visibility_aabb.end.x = max_x
    self.visibility_aabb.end.y = max_y
    self.visibility_aabb.end.z = max_z
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    # Step 5: DrawPass Mesh Adjustments
    #
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if self.material_override.pass_1 != null:
        if self.material_override.pass_1 is QuadMesh:
            self.draw_pass_1 = QuadMesh.new()
            draw_pass_1.size.x = material_override.pass_1.size.x / new_scale.x
            draw_pass_1.size.y = draw_pass_1.size.x
        elif self.material_override.pass_1 is CubeMesh:
            self.draw_pass_1 = CubeMesh.new()
            draw_pass_1.size.x = material_override.pass_1.size.x / new_scale.x
            draw_pass_1.size.y = material_override.pass_1.size.y / new_scale.y
            draw_pass_1.size.z = material_override.pass_1.size.z / new_scale.z
        else:
            printerr("Only QuadMesh and CubeMesh are supported draw types")
            return

    if self.material_override.pass_2 != null:
        if self.material_override.pass_2 is QuadMesh:
            self.draw_pass_2 = QuadMesh.new()
            draw_pass_2.size.x = material_override.pass_2.size.x / new_scale.x
            draw_pass_2.size.y = draw_pass_2.size.x
        elif self.material_override.pass_2 is CubeMesh:
            self.draw_pass_2 = CubeMesh.new()
            draw_pass_2.size.x = material_override.pass_2.size.x / new_scale.x
            draw_pass_2.size.y = material_override.pass_2.size.y / new_scale.y
            draw_pass_2.size.z = material_override.pass_2.size.z / new_scale.z
        else:
            printerr("Only QuadMesh and CubeMesh are supported draw types")
            return

    if self.material_override.pass_3 != null:
        if self.material_override.pass_3 is QuadMesh:
            self.draw_pass_3 = QuadMesh.new()
            draw_pass_3.size.x = material_override.pass_3.size.x / new_scale.x
            draw_pass_3.size.y = draw_pass_3.size.x
        elif self.material_override.pass_3 is CubeMesh:
            self.draw_pass_3 = CubeMesh.new()
            draw_pass_3.size.x = material_override.pass_3.size.x / new_scale.x
            draw_pass_3.size.y = material_override.pass_3.size.y / new_scale.y
            draw_pass_3.size.z = material_override.pass_3.size.z / new_scale.z
        else:
            printerr("Only QuadMesh and CubeMesh are supported draw types")
            return
            
    if self.material_override.pass_4 != null:
        if self.material_override.pass_4 is QuadMesh:
            self.draw_pass_4 = QuadMesh.new()
            draw_pass_4.size.x = material_override.pass_4.size.x / new_scale.x
            draw_pass_4.size.y = draw_pass_4.size.x
        elif self.material_override.pass_4 is CubeMesh:
            self.draw_pass_4 = CubeMesh.new()
            draw_pass_4.size.x = material_override.pass_4.size.x / new_scale.x
            draw_pass_4.size.y = material_override.pass_4.size.y / new_scale.y
            draw_pass_4.size.z = material_override.pass_4.size.z / new_scale.z
        else:
            printerr("Only QuadMesh and CubeMesh are supported draw types")
            return

    self.scale = new_scale

func displacement(unit_weight : float, scale : float, gravity : float):
    # Now we need to calculate how far a particle moves in a given time period.
    # To do that, we'll need the displacement formula:
    #
    # s = (u * t) + (0.5 * a * (t^2))
    #
    # Where s = displacement, u = initial velocity, a = acceleration, & t = time
    
    # Of course, that's a whole lot messier with our unit vector and how scale
    # interferes with velocity and and acceleration in Godot particles. Also
    # damping should be here somewhere but I honestly can't crunch the math for
    # that. Maybe sometime in the future.
    
    # Time is going to remain constant, so we need to calculate the acceleration
    # and base velocity.
    var acceleration
    var base_velocity
    var result = 0
    
    # First up - acceleration. Acceleration is equivalent to acceleration,
    # scaled appropriately
    acceleration = self.process_material.linear_accel
    # So to it goes for the velocity too.
    base_velocity = self.process_material.initial_velocity
    
    # First, start with the velocity
    result = base_velocity * self.lifetime
    # Next, add in the acceleration
    result += 0.5 * acceleration * (pow(self.lifetime, 2))
    # Apply the unit_weight
    result *= unit_weight
    
    # Now, apply the gravity. Gravity ignores the weighting.
    result += 0.5 * gravity * (pow(self.lifetime, 2))
    
    # Scale the result and return!
    return result * scale

func calculate_maxi_angles(unit : Vector2):
    # First, we calculate the base angle. We want it to be between 0 & 360, so
    # we add 360 and then modulus out that same 360.
    var base_angle = fmod( rad2deg( unit.angle() ) + 360, 360 )
    
    # We need to calculate a plus-or-minus angle spread.
    var spread_minus = 0
    var spread_plus = 0
    
    # If this is a process material...
    if process_material is ParticlesMaterial:
        # The spread is a plus-or-minus value, so add in and remove the spread
        # from the base angle to calculate our angular extents
        spread_minus = base_angle - self.process_material.spread
        spread_plus = base_angle + self.process_material.spread
    
    # The smallest distance from the spread_minus & spread_plus angles to our
    # target MAXI angles.
    var minus_distance
    var plus_distance
    
    # The return value; we'll pack in the ideal angles, in degrees, into the x
    # and y.
    var maxi_angles = Vector2.ZERO
    
    # First, we'll start with X. If MAXI_X_ANGLE_DEG degrees, our peak, is
    # contained in our spread...
    if (spread_minus <= MAXI_X_ANGLE_DEG) and (MAXI_X_ANGLE_DEG <= spread_plus):
        # Then the answer is easy - it's MAXI_X_ANGLE_DEG degrees!
        maxi_angles.x = MAXI_X_ANGLE_DEG
    else:
        # So if we didn't pass over MAXI_X_ANGLE_DEG degrees, then that means
        # that one of our spread points must be the CLOSEST WE CAN POSSIBLY GET
        # TO MAXI_X_ANGLE_DEG, since the two spread values represent our maximum
        # extent. So, get the distance from each spread to MAXI_X_ANGLE_DEG.
        # Pick the smallest value, going either direction.
        minus_distance = min(
            abs(spread_minus - MAXI_X_ANGLE_DEG),
            abs((MAXI_X_ANGLE_DEG + 360) - spread_minus)
        )
        plus_distance = min(
            abs(spread_plus - MAXI_X_ANGLE_DEG),
            abs((MAXI_X_ANGLE_DEG + 360) - spread_plus)
        )
        
        # If the MINUS is closer to MAXI_X_ANGLE_DEG then the PLUS, use the
        # minus angle.
        if minus_distance <= plus_distance:
            maxi_angles.x = spread_minus
        # Otherwise, use the plus angle.
        else:
            maxi_angles.x = spread_plus
            
    # Now we'll do Y.
    if (spread_minus <= MAXI_Y_ANGLE_DEG) and (MAXI_Y_ANGLE_DEG <= spread_plus):
        maxi_angles.y = MAXI_Y_ANGLE_DEG
    else:
        minus_distance = min(
            abs(spread_minus - MAXI_Y_ANGLE_DEG),
            abs((MAXI_Y_ANGLE_DEG + 360) - spread_minus)
        )
        plus_distance = min(
            abs(spread_plus - MAXI_Y_ANGLE_DEG),
            abs((MAXI_Y_ANGLE_DEG + 360) - spread_plus)
        )
        
        if minus_distance <= plus_distance:
            maxi_angles.y = spread_minus
        else:
            maxi_angles.y = spread_plus
    
    # All done! Return the maximum angles.
    return maxi_angles

func calculate_mini_angles(unit : Vector2):
    # First, we calculate the base angle. We want it to be between 0 & 360, so
    # we add 360 and then modulus out that same 360.
    var base_angle = fmod( rad2deg( unit.angle() ) + 360, 360 )
    
    # We need to calculate a plus-or-minus angle spread.
    var spread_minus = 0
    var spread_plus = 0
    
    # If this is a process material...
    if process_material is ParticlesMaterial:
        # The spread is a plus-or-minus value, so add in and remove the spread
        # from the base angle to calculate our angular extents
        spread_minus = base_angle - self.process_material.spread
        spread_plus = base_angle + self.process_material.spread
    
    # The smallest distance from the spread_minus & spread_plus angles to our
    # target MAXI angles.
    var minus_distance
    var plus_distance
    
    # The return value; we'll pack in the ideal angles, in degrees, into the x
    # and y.
    var mini_angles = Vector2.ZERO
    
    # First, we'll start with X. If MINI_X_ANGLE_DEG degrees, our peak, is
    # contained in our spread...
    if (spread_minus <= MINI_X_ANGLE_DEG) and (MINI_X_ANGLE_DEG <= spread_plus):
        # Then the answer is easy - it's MINI_X_ANGLE_DEG degrees!
        mini_angles.x = MINI_X_ANGLE_DEG
    else:
        # So if we didn't pass over MINI_X_ANGLE_DEG degrees, then that means
        # that one of our spread points must be the CLOSEST WE CAN POSSIBLY GET
        # TO MINI_X_ANGLE_DEG, since the two spread values represent our maximum
        # extent. So, get the distance from each spread to MINI_X_ANGLE_DEG.
        # Pick the smallest value, going either direction.
        minus_distance = min(
            abs(spread_minus - MINI_X_ANGLE_DEG),
            abs((MINI_X_ANGLE_DEG + 360) - spread_minus)
        )
        plus_distance = min(
            abs(spread_plus - MINI_X_ANGLE_DEG),
            abs((MINI_X_ANGLE_DEG + 360) - spread_plus)
        )
        
        # If the MINUS is closer to MINI_X_ANGLE_DEG then the PLUS, use the
        # minus angle.
        if minus_distance <= plus_distance:
            mini_angles.x = spread_minus
        # Otherwise, use the plus angle.
        else:
            mini_angles.x = spread_plus
            
    # Now we'll do Y.
    if (spread_minus <= MINI_Y_ANGLE_DEG) and (MINI_Y_ANGLE_DEG <= spread_plus):
        mini_angles.y = MINI_Y_ANGLE_DEG
    else:
        minus_distance = min(
            abs(spread_minus - MINI_Y_ANGLE_DEG),
            abs((MINI_Y_ANGLE_DEG + 360) - spread_minus)
        )
        plus_distance = min(
            abs(spread_plus - MINI_Y_ANGLE_DEG),
            abs((MINI_Y_ANGLE_DEG + 360) - spread_plus)
        )
        
        if minus_distance <= plus_distance:
            mini_angles.y = spread_minus
        else:
            mini_angles.y = spread_plus
    
    # All done! Return the minimum angles.
    return mini_angles
