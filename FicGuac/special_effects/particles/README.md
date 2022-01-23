# Particles
The *Particles* directory is for any particle related special effects - their textures, their code, and their scenes.

Each particle effect in Godot is essentially made up of two components: the emitter (which is an actual node in the scene) and the Particle Material that describes it. The settings for the particle effect are spread across these two components.

This gets tricky - for example, the size of the emitting area is set in the material and is fixed. However, we may want our particle effect to be larger or smaller depending on what the particle system is working supposed to be effecting - say we have a fire particle effect that we use for campfires, burning trees, burning people, etc. So we need to scale up the emitter to compensate, but then we also need to increase the particle count to deal with the newly increased emitter area. And let's not even start with calculating the emitter's visibility `AABB`!

While this divide is actually structurally sound and very good from an engineering perspective, it does make our job somewhat thornier. While I *could* just make several different particle materials with different emitter sizes and behaviors, I'm betting that reusing particle materials will allow for better overall performance. Less materials to render per-scene and all that.

Because of all of this, our particle materials are all assumed to emit particles in a 1x1x1 unit box.

## Rich Particle Material
Our answer to the emitter-material particle divide is this script-extended resource which packs the emitter variables (or the values to calculate them) into the material itself. Hence, it is a *rich* `ParticleMaterial`.

A couple of things to note:

- A *Rich Particle Material*, if designed to be scale-able, should always have an emission area of roughly 1x1x1.
- The only *emission shapes* currently supported by the corresponding *Rich Particle Emitter* are:
 - Point
 - Sphere
 - Box
- The only *draw pass meshes* currently supported by the corresponding *Rich Particle Emitter* are:
 - `QuadMesh`
 - `CubeMesh`


### Configurables
#### Base Particle Count
The basic number of particles. If a given emitter somehow ends up having zero volume, it will at least have this many particles.

#### Root Particle Slope
This is the slope we use to scale the number of particles based on the volume of a given emitter. I'll explain the math but I really recommend **just playing with this value** to see what you can get out of it.

Okay, now for the actual math - we start by calculating the volume of a given emitter-area. We then take the *cubic root* and multiply by this value the *root particle slope*. We then add this sloped cubic-root value to the *base particle count* to calculate the total number of particles.

This works because taking the cubic root of the volume turns the value from a *cubic, exponential* system into a *linear* one, thus allowing us to scale the particle count at a normal rate. At least I think so. This idea was kind of a wake-up-in-a-cold-sweat-after-midnight idea so who knows, maybe it was just given to me by some sort wretched math goblin (though is there truthfully any sort of math goblin that isn't wretched?).

#### Override Material
The *Override Material* is the material used in the emitter's *Material Override* field - this can be seen under the *Geometry* sub-menu. This is the material that particles will actually spawn with, and will be manipulated by the particle material.

#### Mesh Passes
Each particle consists of a number of meshes that are basically spawned on top of each other; these are (for some obscure graphical reason that is beyond me) called *passes*. Up to four pass meshes can be added.

Please keep in mind that the only *draw pass meshes* currently supported by the corresponding *Rich Particle Emitter* are:
 - `QuadMesh`
 - `CubeMesh`

#### Particle Size Hint
When calculating the *AABB* for a given system, we need to factor in the particle
size. To avoid actually having to do that manually, we'll instead use this size hint to approximate the particle size, and assume it's a box. This is technically over-generous but that ensures that the particle systems LOOK right.

#### Recommended (RCMND) Values
We also have a series of variables that are passed one-to-one to an emitter. These are appended with a *rcmnd* (recommended) prefix. They are:

- RCMND Lifetime
- RCMND One Shot
- RCMND Preprocess
- RCMND Speed Scale
- RCMND Explosiveness
- RCMND Randomness
- RCMND Fixed FPS
- RCMND Fract Delta

## Rich Particle Emitter
This scene is a single-node scene; it's just a regular `ParticleEmitter` node that's been amped up with a few functions to take advantage of the *Rich Particle Materials*.

### Functions

Right now there's only two functions you need to worry about, which need to be called to configure the *Rich Particle Emitter* appropriately. This is technically a programming faux-pas: two separate configuration functions where one would suffice. I'm lazy though, so I'll let it slide for now.

#### `set_rich_material`
This function takes in a new `RichParticleMaterial` and transfers over the variables. This does not set the AABB or deal with current scaling, that is handled by `scale_emitter`.

For this function to work:

- The `process_material` must not be null.
- The `process_material` must be a `RichParticleMaterial`. This check is performed by checking for certain variables.
- The `process_material`'s *emission shape* must be a Point, Sphere, or Box.
- The `process_material`'s *emission shape* must be a `QuadMesh` or `CubeMesh`.

#### `scale_emitter`
This function takes in a new `Vector3` scale and performs all the number crunching and variable adjustment required to make the particle system behave consistent at all scales. It's not perfect, but it works well enough.

For this function to work:

- The `process_material` must not be null.
- The `process_material` must be a `RichParticleMaterial`. This check is performed by checking for certain variables.
- The `process_material`'s *emission shape* must be a Point, Sphere, or Box.
- The `process_material`'s *emission shape* must be a `QuadMesh` or `CubeMesh`.