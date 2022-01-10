# Particles
The *Particles* directory is for any particle related special effects - their textures, their code, and their scenes.

Each particle effect in Godot is essentially made up of two components: the emitter (which is an actual node in the scene) and the Particle Material that describes it. The settings for the particle effect are spread across these two components.

This gets tricky - for example, the size of the emitting area is set in the material and is fixed. However, we may want our particle effect to be larger or smaller depending on what's on fire. So we need to scale up the emitter to compensate, but then we also need to increase the particle count to deal with the newly increased emitter area. And let's not even start with calculating the emitter's visibility `AABB`!

While this divide is actually structurally sound and very good from an engineering perspective, it does make our job somewhat thornier.

Because of all of this, our particle materials are all assumed to emit particles in a 1x1x1 unit box.

## RichParticleMaterial
Our answer to the emitter-material particle divide is this script-extended resource which packs the emitter variables (or the values to calculate them) into the material itself. Hence, it is a *rich* `ParticleMaterial`.

### Configurables
#### Particle Density
The density of particles, in terms of particles per unit cubed. Since we know each particle material emits in a 1x1x1 cube, we can scale the cube to any size by scaling the emitter. Given a volume, this variable can be used to adjust the emitter's overall particles to give a consistent effect at any scale.

#### Recommended Lifetime
The lifetime of the particles emitted is configured in the emitter, not the particle material. This configurable is the particle lifetime, in seconds. It's mostly a recommendation, but it's a good one!

#### Override Material
The *Override Material* is the material used in the emitter's *Material Override* field - this can be seen under the *Geometry* sub-menu. This is the material that particles will actually spawn with, and will be manipulated by the particle material.

#### Mesh Passes
Each particle consists of a number of meshes that are basically spawned on top of each other; these are (for some obscure graphical reason that is beyond me) called *passes*. This array of meshes allows you to set the number of passes AND the meshes used for each pass. Not sure we'll ever need more than one but this is a general purpose resource SO an array of meshes is what you get!

