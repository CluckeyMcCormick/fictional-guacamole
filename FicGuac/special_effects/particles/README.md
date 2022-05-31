# Particles
The *Particles* directory is for any particle related special effects - their textures, their code, and their scenes.

Each particle effect in Godot is essentially made up of three components: the emitter (which is an actual node in the scene), The Override Material that textures the particle, and the Particle Material that describes the behavior of the particles (and sometimes the appearance!). The settings for the particle effect are thus spread across these three components.

This gets tricky - for example, the size of the emitting area is set in the particle material and is fixed. However, we may want our particle effect to be larger or smaller depending on what the particle system is working supposed to be effecting - say we have a fire particle effect that we use for campfires, burning trees, burning people, etc. So we need to scale up the emitter to compensate, but then we also need to increase the particle count to deal with the newly increased emitter area. And let's not even start with calculating the emitter's visibility `AABB`!

While this divide is actually structurally sound and very good from an engineering perspective, it does make our job somewhat thornier. While I *could* just make several different particle materials with different emitter sizes and behaviors, I'm betting that reusing particle materials will allow for better overall performance. Less materials to render per-scene will improve frame rate and decrease the strain on lower-end systems. As an added advantage, reusing materials in this way will help us make our particles aesthetically consistent.

To maximize the reusage of material resources, we have a few custom resources and a scene.

First, we have `ParticleReadySpatialMaterial`, which is a `SpatialMaterial` extended with extra fields. These extra fields allow us to group the visual information - the pass meshes and particle size hints - with the visual information in the `SpatialMaterial` resource.

Next, we need to bind the `ParticleReadySpatialMaterial` together with a behavior-describing `ParticleMaterial` or `ShaderMaterial`. For that, we have the `ScalableParticleBlueprint`. It also includes some extra fields that control both overall particle system visuals and behavior.

Finally, the `ScalableParticleBlueprint` is used to instantiate a `ScalableParticleEmitter`. This particle emitter can then be scaled to emit particles over a given area.

## Directories

### Particle Materials
Home directory for our `ParticleMaterial` resources.

### Particle Ready
Home directory for our `ParticleReadySpatialMaterial` custom resources.

### Scalable Blueprints
Home directory for our `ScalableParticleBlueprint` custom resources.

### Sprites
Home directory for our particle sprites custom resource.

## Particle Ready Spatial Material
A spatial material which does (most of) the heavy lifting for determining a particle's appearance. Aside from the usual responsibilities of a `SpatialMaterial`, it comes with additional fields to determine the base size and shape of the particles.

### Configurables

#### Mesh Passes
Each particle consists of a number of meshes that are basically spawned on top of each other; these are (for some obscure graphical reason that is beyond me) called *passes*. Up to four pass meshes can be added.

Please keep in mind that the only *draw pass meshes* currently supported by the corresponding *Rich Particle Emitter* are:

 - `QuadMesh`
 - `CubeMesh`

Keep in mind that the size of these meshes is considered the base size of the particles. Depending on the `ParticleMaterial` there will may further scaling, but this is the base.

#### Particle Size Hint
When calculating the *AABB* for a given system, we need to factor in the particle
size. To avoid actually having to do that manually, we'll instead use this size hint to approximate the particle size, and assume it's a box. This is technically over-generous (and imprecise) but that ensures that the particle systems LOOK right.

## Scalable Particle Blueprint
This custom resource ties together a `ParticleReadySpatialMaterial` with a `ParticleMaterial` (or `ShaderMaterial`) and some extra instructions for instantiating a *Scalable Particle Emitter* - hence the *blueprint* designation.

### Configurables

#### PRSM
The  `ParticleReadySpatialMaterial` for this blueprint. I had to make the variable name an acronym because I failed to be concise when devising a class name (whoopsie, hehe). The blueprint should reject any resources that are not `ParticleReadySpatialMaterial` resources.

#### Particle Material

A couple of things to note:

- Both `ParticleMaterial` and `ShaderMaterial` are accepted. However, the behavior if you use a non-particle `ShaderMaterial` is untested and undefined.
- If using a `ShaderMaterial`, the particles should be constrained to a 1x1x1 space. Since there is no emitter shape to scale from, we assume the particles occupy a 1x1x1 volume for the purposes of scaling the visibility.
- If using a `ParticleMaterial`, the only *emission shapes* currently supported by the corresponding *Scalable Particle Emitter* are:
 - Point
 - Sphere
 - Box

I think we could support more emission shapes, but that would require me to be good at math.

#### Base Particle Count
The basic number of particles for the emitter. If a given emitter somehow ends up having zero volume, it will at least have this many particles.

#### Root Particle Slope
This is the slope we use to scale the number of particles based on the volume of a given emitter. I'll explain the math but I really recommend **just playing with this value** to see what you can get out of it.

Okay, now for the actual math - we start by calculating the volume of a given emitter-area. We then take the *cubic root* and multiply by this value the *root particle slope*. We then add this sloped cubic-root value to the *base particle count* to calculate the total number of particles.

This works because taking the cubic root of the volume turns the value from a *cubic, exponential* system into a *linear* one, thus allowing us to scale the particle count at a normal rate. At least I think so. This idea was kind of a wake-up-in-a-cold-sweat-after-midnight idea so who knows, maybe it was just given to me by some sort wretched math goblin (though is there truthfully any sort of math goblin that isn't wretched?).

#### Recommended (RCMND) Values
We also have a series of variables that are passed one-to-one to an emitter. These are prepended with a *rcmnd* (recommended) prefix. They are:

- RCMND Lifetime
- RCMND One Shot
- RCMND Preprocess
- RCMND Speed Scale
- RCMND Explosiveness
- RCMND Randomness
- RCMND Fixed FPS
- RCMND Fract Delta

## Scalable Particle Emitter
This scene is a single-node scene; it's just a regular `ParticleEmitter` node that's been amped up with a few functions to take advantage of the *Scalable Particle Blueprint*.

This node was intended to be instantiated from code and then manually fed *Scalable Particle Blueprints*. Ergo, if you tried to use it in editor it probably wouldn't work how you expected. If you updated the blueprint it wouldn't refresh, and the nodes "scale" property is not necessarily what we're scaling to. Still, with a little work, it could be doable. Just, that's outside of what we need this thing for so I'm not doing it.

### Configurables

#### Blueprint
The `ScalableParticleEmitter`'s current `ScalableParticleBlueprint`.

### Functions

Right now there's only two functions you need to worry about, which need to be called to configure the *Scalable Particle Emitter* appropriately. This is technically a programming faux-pas: two separate configuration functions where one would suffice. I'm lazy though, so I'll let it slide for now.

#### `set_blueprint`
This function takes in a new `ScalableParticleBlueprint` and transfers over the variables. It sets the `process_material`, in addition to the `material_override`, the draw passes, and those *rcmnd* variables. This does not set the AABB or deal with current scaling, that is handled by `scale_emitter`.

For this function to work:

- The `new_blueprint` must be a `ScalableParticleBlueprint`.
- The new blueprint's `prsm` variable must be a `ParticleReadySpatialMaterial`.
- The new blueprint's `prsm` draw passes must either be `QuadMesh` or `CubeMesh`.
- The new blueprint's `particle_material` variable must be either a `ParticlesMaterial` or a `ShaderMaterial`.
- If the new blueprint's `particle_material` is a `ParticlesMaterial`, the *emission shape* must be a Point, Sphere, or Box.
- The `prsm`'s draw passes must all either be a `QuadMesh` or `CubeMesh`.

#### `scale_emitter`
This function takes in a new `Vector3` scale and performs all the number crunching and variable adjustment required to make the particle system behave consistent at all scales. It's not perfect, but it works well enough.

For this function to work:

- The `blueprint` must not be null.
- The `particle_material` must not be null.
- The `material_override` must be a `ParticleReadySpatialMaterial` or a `ShaderMaterial`.
- If the `process_material` is a `ParticlesMaterial`, the *emission shape* must be a Point, Sphere, or Box.
- The `material_override`'s particle-ready draw passes must all either be `QuadMesh` or `CubeMesh`.