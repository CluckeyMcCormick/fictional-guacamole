# Special Effects
The *Special Effects* directory is for any assets (shaders in particular) and scenes that are used to create visual effects, but don't really have any other purpose outside of that.

## Viewport Shader Templates
We have a special class of shaders, known as the *Viewport Shaders*, that use `Viewport` nodes to create various effects. There are currently a lot of variations on these shaders, and their use of `ViewportTexture` textures means that they have behavior unique amongst other shaders. 

## Hiding Mesh
The *Hiding Mesh* is a mesh that shows and hides itself depending on whether it can be "seen" by the camera. Rather than using a `VisibilityNotifier` node to track this, the *Hiding Mesh* uses physics raycasts to a dedicated camera node. This is a bit messy since it meshes visual and physical components but it's the best way to track occlusion (as opposed to whatever heuristic `VisibilityNotifier` uses).

The default behavior of the mesh is to show when hidden - that is, it will show itself when occluded. This behavior can be inverted, so that it only shows when showing (and hides when hidden).

There is an option to show or hide the *Hiding Mesh* with an animation instead of just changing the visibility.

### Configurables

##### Show On Hidden
This option, enabled by default, controls when the shows itself. If enabled, the mesh only shows itself when hidden/occluded from view. It will hide when it is no longer occluded.

Disabling this option inverts the behavior: the mesh shows itself when not occluded, and hides when occluded.

##### Target Camera
In order to test whether the mesh is occluded or not, we need a target node to cast to. This is intended to be a 3D `Camera` node, but any 3D `Spatial` will suffice.

If this node is not provided, the *Hiding Mesh* will not be able to test occlusion and the hiding functionality will not work.

##### Test Source
By default, we cast from the *Hiding Mesh*'s origin to the *Target Camera*'s origin. However - sometimes we might, for whatever reason, want to cast from a different node's origin rather than the *Hiding Mesh*'s origin. The *Test Source* configurable node, if specified, will serve as the occlusion raycast's origin.

##### Occlusion Layers
As stated multiple times, we need to use physics raycasts to determine occlusion. This physics layer configurable allows for fine control of what physics layers can be considered "occluding".

##### Animation Length
This configurable controls the length of the grow-and-shrink animation of the *Hiding Mesh*. If this value is less than or equal to 0, there will be no animation (this is the default). Instead, the visibility of the *Hiding Mesh* will be toggled appropriately.