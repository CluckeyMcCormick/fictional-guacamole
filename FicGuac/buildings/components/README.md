# Building Components
Rather than modeling buildings as static models in Blender or something, we assemble buildings using various components - sort of like building blocks. The components have a bunch of different configurable parameters, allowing us to control the size of the components on various dimensions.

While this required a lot of initial programming work, it makes adding new buildings really quick and easy. I'm very happy
with them all.

This README will not cover all configurables for all building component scenes. All of the scenes run in-editor, so you can experiment and observe what the size sliders do on your own. Instead, this README will focus on the intention behind components, as well as non-observable configurables or a particular component's peculiarities.

### Common Configurables
There are some configurable options that are common to multiple components:

- *Render Layers 3D*
	+ Each one of the building components is composed of a static body with multiple
	mesh components under it. Because of this, we can't access those meshes directly
	once a components is instanced into a scene. To handle that, we have this
	*render layer* configurable - every time it's updated, the change gets carried
	down to the meshes under the static body. This ensures that all of the meshes
	on a component are on a consistent *visual layer*.
- *Update on Value Change*
	+ This is an editor-specific option. When in the editor, adjusting a component
	will update the size of that component in real time. However, for composite
	components (which are made up of various sub-components), this can cause the
	editor to hang as multiple components build all at the same time. Turning this to
	"off" allows composite components to build in one pass, rather than multiple
	redundant passes.
- *Shadow Only Mode*
	+ Like the *Render Layers 3D* option, this configurable raises a property that
	exists at level of individual meshes and raises it to the component level.
	*Shadow Only Mode* effectively controls the state of each mesh child's
	*Cast Shadow* property - *Shadows Only* if on, or defaulting to just *On* if off.
	Yes that is confusing, just avoid thinking about it. This configurable was
	originally added so that so that we could "drop" components to create a cutaway
	effect.

### Column
The Column is meant to be a square column, with all sides textured the same. It does, however, offer an option to provide an "alternate" material as well as a material for the top of the column.

You can delegate which faces use which of the side faces use which material - either the "primary" or the ""alternate". Each face defaults to using the primary. The "alternate" texture is meant to be used with a shadow texture for artificial shading, but other applications are possible.

### Foundation
The Foundation is meant to be the building's... foundation. Each foundation is composed of a "Wall", "Frame", and "Floor". While both the "Frame" and the "Floor" constitute what is, objectively, the floor, they are differentiated so we can do texture/material nonsense. The "Frame" actually frames/surrounds the "Floor" texture, giving the impression of a foundation composed of multiple materials.

Because the Foundation was meant to be used close to the floor, there was next-to-no chance the Foundation would ever block the camera. Because of that, the *Shadow Only Mode* hasn't been implemented yet for this component.

### Roof (Gable)
This Roof (Gable) is meant to represent a gabled roof - one of those roofs that come to a triangular peak that's pretty common (for me, I guess; I see it a lot).

This is currently the only roof type; I expect I'll add more at some point as the game requires, but I'm in no rush.

The Roof is divided into five components. The first two components are:

1. The sheeting, which is what goes on top of the roof - like the shingles.
2. The gable, which is the peaked components at either end of the Roof. This should most likely match the wall texture of whatever building the roof is sat upon.

There are then three components that constitute the *fascia*, which is the actually bulk of the roof the *sheeting* upon. These are:

3. The sideboard, which is the on the angled part of the fascia on the "sides" of the roof.
4. The longboard, which is the long flat part on either length of the roof.
5. The underboard, which is the underside of the fascia. Its basically the downward face of the sheeting.

The fascia is separated like this to allow for multiple kinds of materials. This was originally intended for use with a thatch roof, but is currently used to imply shading.

### Stairs
This component is just a regular set of stairs. It's divided into three components - the "Forwards", the "Sides", and the "Tops". The idea was that we could provide one material for each to get good looking stairs. It technically works, but it also makes the stairs one of the hardest-to-texture items in this game. We need to create a different texture for each set stairs depending on the size of the steps.

Because of that, this component is a candidate for a rework. Surely we can do SOMETHING better!

Because the Stairs were meant to be used close to the floor, there was next-to-no chance the Foundation would ever block the camera. Because of that, the *Shadow Only Mode* hasn't been implemented yet for this component. There's a chance that this might get implemented in the future, as larger stairs will be required to reach greater heights. 

### Wall (Basic)
This is a regular, good ol' fashioned wall. It was designed with the intention that one side would serve as the exterior of the building, while the other side would serve as the interior. Originally, the user wasn't supposed to see the tops and sides of the walls, so those are referred to by the term *cutaway*. Of course, these are just suggestions, and the Wall can be used in any number of ways.

We generally don't generate a bottom for the wall, since the perspective of the game means we won't actually see that part. However, that also means there's nothing to block the light. We eventually started using the Wall in situations where it wasn't attached to the ground. So the wall includes a *Render Bottom Cap* configurable to render the bottom cap.

The Wall also includes a *UV Shift*, so that the texture of the wall can be shifted. This is largely for when we have two or more Walls that need to appear cohesive.

### Wall (Gap)
This scene is our first composite component - it's made up of two or three individual Wall scenes, arranged so that they form a sort-of-doorway.

It features many of the same controls as the regular wall, but with new controls for the *Gap* that exists between the two primary walls.

### Wall (Set)
The Wall Set is our second composite component - it uses a mixture of Columns and Walls to model a complete three-or-four walled room. It allows for easy sizing and allows you to pick the style of the fourth wall.

One remarkable feature is that the *Shadow Only Mode* is no longer a boolean - it is now an enumerated choice list. This choice list allows us to set the shadow mode on walls two-at-a-time, effectively giving us a cutaway view of the walls.