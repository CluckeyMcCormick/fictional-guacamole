extends Resource
class_name ScalableParticleBlueprint

# What's the ParticleReadySpatialMaterial that we'll use as the override
# material for this system?
export(Material) var prsm = null setget set_prsm
# What's the particle material for this system?
export(Material) var particle_material = null setget set_particle_material

# What's our base particle count - i.e. if this material is in a zero-volume
# emitter, how many particles do we have?
export(int) var base_particle_count = 60
# What's the particle scalar/slope for the volume's cubic root?
export(float) var root_particle_slope = 10

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

func set_prsm(new_material):
    if (new_material is ParticleReadySpatialMaterial) or \
        (new_material is ParticleReadyShaderMaterial):
        prsm = new_material
    else:
        push_warning("Attempted to give non-PRSM resource to scalable blueprint.")
        push_warning("Please use a ParticleReady(Spatial/Shader)Material.")

func set_particle_material(new_material):
    if (new_material is ParticlesMaterial) or (new_material is ShaderMaterial):
        particle_material = new_material
    else:
        push_warning("Incompatible particle material for blueprint.")
        push_warning("Please use a ParticlesMaterial or a ShaderMaterial.")
