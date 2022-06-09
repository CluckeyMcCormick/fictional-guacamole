# FicGuac
This directory constitutes the actual proper Godot project. Everything needed to compile and run the project exists in this directory.

## Render Layers
The **3D Render Layers** are set at the project level. Each `VisualInstance` (i.e. any 3D node that renders something) can be set to exist on some mixture of these layers. It can exist on one layer, many layers, or even no layers.

The editor always renders everything, so why should it matter? The real power of the *render layers* is in how it interacts with the `Camera`. See, `Camera` nodes also have *render layers*. They will only render nodes that exist on the layers the `Camera` is configured with. In that way, the layers control what the `Camera` can or cannot see.

While this has multiple applications, it's core use is currently for our shaders (see *Special Effects*).

Godot naturally supports 20 layers. Each layer can be given a name, to help differentiate it from the other layers. At present, we use only 6 layers. These are:

- (Bit 0/ Layer 1): **Default Render**
	+ As the layer is named, this is the default layer for any `VisualInstance`. In any Godot project, 
	this bit is automatically enabled on any new 3D `VisualInstance` nodes. Ergo, I've just left it
	as-is. In-game, this basically translates to any item the player can see that exhibits no other
	visually odd behavior.
	  
- (Bit 1/ Layer 2): **Obstacle Actual**
	+ A core element of this game is an isometric perspective of a 3D environment. A direct
	consequence of that art-direction, though, is that items can very easily become obscured behind
	walls and other obstacles. We use shaders to get around this, but it means we need two versions
	of each obscuring obstacle. This layer denotes the "actual" form of the obstacle, which the users
	will see 90% of the time.
	
- (Bit 2/ Layer 3): **Obstacle Alternate**
	+ This is the companion layer to the *Obstacle Actual* layer above. It denotes the "alternate"
	form of the obstacle that should be used for whatever behind-the-wall rendering solution we've
	cooked up. This allows us to use a mesh or sprite to express that an obstacle is still there -
	it's just obscured for the sake of gameplay.

- (Bit 3/ Layer 4): **Silhouettable**
	+ Another solution for behind-the-wall rendering is to use paint "silhouettes" on the screen
	whenever objects are behind walls. This render layer denotes all visuals that should be
	candidates for silhouettes. Ideally, that should just be characters and other such entities.

- (Bit 4/ Layer 5): **Special Effects (Rerender)**
	+ There's a possibility that rendering a special effect `VisualInstance` could mess with other
	special effects - especially those that involve rendering the screen twice. This *visual layer*
	indicates that this is a special effect that is safe to re-render and SHOULD be re-rendered.

- (Bit 5/ Layer 6): **Special Effects (No rerender)**
	+ A companion to the *Special Effects (Rerender)* layer. If re-rendering a `VisualInstance`
	would cause a special-effect to malfunction, then it should exist on this layer. This is most
	commonly used for the special effects that are actually doing the re-rendering. A re-render
	special effect that re-renders itself creates this weird sticky screen where nothing gets
	cleared, which we'd like to avoid.

## Physics Layers
The **3D Physics Layers**, or **3D Collision Layers**, control what physics objects collide with each other.

That's simple enough to understand, but it gets more confusing. Most (if not all) physics objects have two separate *physics layer* settings that they track - the *Layer* and the *Mask*.

The *Layer* denotes which *physics layer* the given object exists on - that's obvious enough. 

The *Mask* denotes which *physics layer* the given object collides with. Ergo, it does not necessarily follow that a physics object will collide with another if they exist on the same layer. Only if their masks align with the other's
layers. 

And as though that weren't confusing enough, the physics layers are used for more than just collisions. Through 3D Areas, the physics layers also serve as our detection mechanism for when entities enter or exit center spots. In addition, we frequently need to use physics raycasts to determine visibility. We also have to keep in mind that physics is also used for entity picking - actually selecting entities via mouse clicks. Oh, and the collision layers are also used to generate navigation meshes.

So our physics layers need to serve as Collision Detection, Occlusion Detection, Entity Detection, and Entity Picking. Each physics body then exists on a given set of layers but collides with another set. Perhaps unsurprisingly, these layers are much more messy than the *visual layers*.

Godot naturally supports 20 layers. Each layer can be given a name, to help differentiate it from the other layers. To help make things simpler, they layers are grouped into "blocks" based on their purpose. There are three blocks - the *World Matter* block, the *World Dynamics* block, and the *Agent-Entity* block.

### World Matter Block

This block deals with what I term the *World Matter* - the actual physical, static building blocks of the world. It largely deals with the terrain, and various attributes the terrain can have.

- (Bit 0/ Layer 1): **Terrain**
	+ This layer represents all static terrain pieces. Buildings, the floor, etc.

- (Bit 1/ Layer 2): **User Ray Blocking**
	+ This layer is meant to act as a flag in conjunction with the *Terrain* layer. This
	is the layer that user input rays (i.e. for object picking) exist on - by placing
	a terrain piece (or anything for that matter) on this layer, it creates a space
	block for the user's inputs.

- (Bit 2/ Layer 3): **Camera Obstruction**
	+ This layer is for any physics body that blocks, obscures, and obstructs the camera.
	We use this to query whether the camera can currently see a given point in space.
	+ I fully acknowledge that this layer is a bit odd since it effectively mixes the
	visual aspects of the engine with the physics aspects. That's not the greatest but
	it's also the best we can do. This is a important feature, particularly for special
	effects.

### World Dynamics Block

This block deals with elements of the world that are more dynamic than the *World Matter* block - those elements that frequently appear and disappear and/or move. This also includes items that need to be detected on the-fly, but are otherwise intangible (like Fire, or AI breadcrumbs).

- (Bit 4/ Layer 5): **Hazard**
	+ This layer represents the collision space of a hazard for pathing and detection 
	purposes.

- (Bit 5/ Layer 6):
	+ Currently unused.

- (Bit 6/ Layer 7): **Interaction Hint**
	+ This layer is for "hints" - entities that we place in the world in order to
	somehow advance, inform, or improve the AI. The AI needs to detect these hints
	dynamically, hence the assignment of a physics layer. This hint layer will
	specifically denote the target positions for "interacting" with world objects.
	Like picking up weapons or using furniture.
	
- (Bit 7/ Layer 8): **World Hint**
	+ This hint layer is for world hints, which contain information about the world
	and may be sought by certain AI. These will most likely be "markers" - marking
	an area as high ground, or marking an area as a safe zone, or marking out a
	particular kind of building.

- (Bit 8/ Layer 9): **Movement Hint**
	+ This hint layer is for movement hints, which describe where movement actions
	can be taken by certain AI. For example, it may indicate that crouching is
	required or that a gap can be crossed by jumping.

### Agent-Entity Block

This block is for the various agents (i.e. Motion AI) and entities (items, projectiles, etc.).

- (Bit 10/ Layer 11): **Agent**
	+ This layer is for active agents (i.e. Motion AI) that move through the
	world - such as the Pawn.

Because the game is being actively developed - new features speculated, added, and removed - these layers are in a state of flux.

## Input Mapping
Godot has a pretty good system for handling inputs - inputs (button presses, mouse clicks, etc.) are mapped with event names at the project level. The individual nodes in the project can then handle these events individually.

The mapping of inputs-to-events is a little bit all-over the place right now. Much like the *physics layers*, we're constantly adding and removing inputs as requirements change. Godot also comes with some default inputs that we haven't deleted, mostly dealing with UI actions.

The current events we have are:

- `debug_print`
	+ We frequently need to print out debug information in a test of some kind. This input
	allows us to print out debug information on-demand.
- `camera_move_forward`
	+ Camera control - moves the camera forward.
- `camera_move_backward`
	+ Camera control - moves the camera backwards.
- `camera_move_left`
	+ Camera control - moves the camera leftward.
- `camera_move_right`
	+ Camera control - moves the camera rightward.
- `camera_move_recenter`
	+ Camera control - moves the camera back to it's starting position. An unusual control
	of little utility that will most likely be removed at some point.
- `formation_order`
	+ This control is used to issue a "move order" - to tell a Pawn where they should go.
	The name comes from an older version of the prototype that was based on Pawns moving
	in a strict formation.
- `camera_move_zoom_in`
	+ Camera control - zooms the camera inward.
- `camera_move_zoom_out`
	+ Camera control - zooms the camera outward.
- `game_core_pause`
	+ The `game_core` series of inputs is meant to be common across all scenes. This
	particular input is meant to pause the game.

## Project Directories
I tried my best to split files into directories based on category - however, you may notice that there is definitely some overlap between them, or that some directories are confusingly promoted over others. Organizing isn't an exact science... 

Wherever possible, scenes are stored together with their assets. This is *Godot's* suggested best-practice. In some cases, there might be WAY TOO MANY assets, so these directories may have an extra `assets` directory.

### Addons
Any *Godot* addons - other people's code and assets distributed through the *Godot Asset Library* - go here.


### Buildings
The buildings in this game are fairly complex - most are glued together using assets that are procedurally generated at runtime. In recognition of this complexity, they've been given their own directory.

This is differentiated from `Terrain` in that it is artificial, rather than natural. It's a very slim distinction. 

### GUI
To ensure consistency across scenes, we build common GUI elements and store them here - like pause menus or loading screens. This allows us to do weird stuff, like rendering the loading screen over the pause screen. That doesn't sound that weird but trust me, that's a big thing in Godot.

### Items
The different items in the game. *Items* are physics objects that can be picked up and put down - possibly even equipped, stored, consumed, or installed.

So that's things like food, corpses, weapons, or even projectiles. It also currently includes furniture, which is a sort of weird edge case of item.

### Motion AI
Does it move? Does it think? In that case, it's a *Motion AI*. This is the directory where we keep our NPC/AI scenes and assets - *Motion AI* was just the best name I could come up with. I guess *Actors* would be a good alternate name but, honestly, I like the clarity of *Motion AI*.

### Scenes
We used to keep all scenes in this folder. Now, it's a directory for scenes and assets that will be used in game-ready scenes, such as environment assets or `Camera` rigs.

### Special Effects
This is a directory of special effects, very much in the movie sense - these scenes and assets are intended purely to create visual effects. Most of our shaders reside here.

### Status
This directory is for resources, scenes, and scripts associated with object/motion AI status - health, being on fire, etc. It's something that doesn't quite belong to the Motion AI, nor do it belong to objects. It's really a category all it's own.

### Terrain
Anything the characters will climb over, on, under, and through is considered terrain. At present I think this category may be overly broad. We may, over time, migrate assets out of this directory into their own directory. In a way, the *Buildings* directory is already an example of that. For now, it suits our purposes well enough.

### Tests
Games are complicated, and this project is no exception. To help test the game, we've developed individual scenes to put particular game concepts to the test. Those tests reside here.

### Textures
This is where *most* of the textures sit - not all of them, but most of them. This directory is mandatory for the *Qodot* addon and the *Trenchbroom* level editor. Any texture that would be used by them, such as terrain textures or building component textures, needs to go in this directory.

### Util
The contents of this directory are meant for debugging or otherwise enhancing other scenes. It's best to see this as a toolbox that other scenes draw from.


## `Manifest.gd`
For certain reasons, we may need global lists - say, a list of all the different NPCs in the game, or a list of all the currently available scenarios. These may need to be modified by incoming mods. To improve modability, we keep this manifest - this list of lists - that is globally available. That way, a change in one of the lists here will propagate throughout the entire game.

### (Public) Variables

##### `TEST_SCENES`
A dictionary of all the different test scenes, with "proper" (human-readable) names for keys.

##### `PARTICLE_BLUEPRINTS`
A dictionary of all the different particle blueprints, with "proper" (human-readable) names for keys.

##### `PARTICLE_SCENES`
A dictionary of all the different prebuilt particle systems (i.e. those in nodes), with "proper" (human-readable) names for keys.

##### `STATUS_CONDITIONS`
A dictionary of all the different status conditions, with "proper" (human-readable) names for keys.