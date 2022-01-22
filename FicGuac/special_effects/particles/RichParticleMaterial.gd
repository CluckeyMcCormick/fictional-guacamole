extends ParticlesMaterial

# Unfortunately, in Godot 3, we can't set a custom class name for a resource, so
# to verify that a ParticlesMaterial is a RichParticlesMaterial we'll need to
# manually check for one of these fields.

export(int) var base_particle_count = 60
export(float) var root_particle_slope = 10
export(float) var recommended_lifetime = 1
export(Material) var override_material = null
export(Mesh) var pass_1 = null
export(Mesh) var pass_2 = null
export(Mesh) var pass_3 = null
export(Mesh) var pass_4 = null

# How big is a particle on each axis? We use this hint so we don't need to
# code around all of the possible particle shapes
export(Vector3) var particle_size_hint = Vector3.ZERO
