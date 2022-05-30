extends SpatialMaterial
class_name ParticleReadySpatialMaterial

# What's the draw pass meshes?
export(Mesh) var pass_1 = null
export(Mesh) var pass_2 = null
export(Mesh) var pass_3 = null
export(Mesh) var pass_4 = null

# How big is a particle on each axis? We use this hint so we don't need to
# code around all of the possible particle shapes
export(Vector3) var particle_size_hint = Vector3.ZERO
