extends ParticlesMaterial

export(float) var particle_density = 1
export(float) var recommended_lifetime = 1
export(Material) var override_material = null
export(Array, Mesh) var mesh_passes = []
