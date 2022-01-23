extends ParticlesMaterial

# Unfortunately, in Godot 3, we can't set a custom class name for a resource, so
# to verify that a ParticlesMaterial is a RichParticlesMaterial we'll need to
# manually check for one of these fields.

# What's our base particle count - i.e. if this material is in a zero-volume
# emitter, how many particles do we have?
export(int) var base_particle_count = 60
# What's the particle scalar/slope for the volume's cubic root?
export(float) var root_particle_slope = 10
# What's the override material for this system?
export(Material) var override_material = null
# What's the draw pass meshes?
export(Mesh) var pass_1 = null
export(Mesh) var pass_2 = null
export(Mesh) var pass_3 = null
export(Mesh) var pass_4 = null

# How big is a particle on each axis? We use this hint so we don't need to
# code around all of the possible particle shapes
export(Vector3) var particle_size_hint = Vector3.ZERO

# Now we enter the recommended block (which we truncate to rcmnd). All of the
# rcmnd variables are just parallels to the emitter values.
export(float) var rcmnd_lifetime = 1
export(bool) var rcmnd_one_shot = false
export(float, 0, 600) var rcmnd_preprocess = 0
export(float, 0, 64) var rcmnd_speed_scale = 1
export(float, 0, 1) var rcmnd_explosiveness = 0
export(float, 0, 1) var rcmnd_randomness = 0
export(int) var rcmnd_fixed_fps = 0
export(bool) var rcmnd_fract_delta = true
