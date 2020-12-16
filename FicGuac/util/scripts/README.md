# Scripts
This directory is where utility scripts are stored - these utility scripts can be likened to tools. Unlike most scripts, they are not attached to a particular scene and are meant to be manually loaded into whatever class requires them.

## PolyGen, the Polygon Generator

We have several scenes that generate meshes on the fly. There's a lot of code that goes into generating a single face of a polygon, and it's very easy to mess up - so it only makes sense that we should have a dedicated script for generating polygons.

Each function returns a dictionary. This dictionary contains a `PoolVector2Array` and a `PoolVector3Array` - the *UV* coordinates and *Vertex* coordinates. These can the be fed into a `SurfaceTool` object.

Currently, we can only draw rectangular faces, locked to a certain axis. The game's aesthetic is very purposefully boxy so there hasn't been a need for more complex generation functions.

### Constants

##### `VECTOR3_KEY`
As previously stated, all the functions in the *Polygon Generator* return a dictionary. This is the key to access the `PoolVector3Array`, which is all of the vertices.

##### `VECTOR2_KEY`
As previously stated, all the functions in the *Polygon Generator* return a dictionary. This is the key to access the `PoolVector2Array`, which is all of the UV coordinates.

### Functions

There are three core functions - `create_xlock_face`, `create_ylock_face`, and `create_zlock_face`. Each takes in the same arguments but produces slightly different behavior.

There are then a further three variations on each of these functions - *Linear*, *Shifted*, and *Simple*. Each of these gives some sort of enhanced or streamlined functionality - mostly around handling UV coordinates.

##### `create_[xyz]lock_face`
The function creates a polygon face that is "locked" on a given axis. The new polygon can face either direction on the axis (positive or negative). Thus, `create_xlock_face`creates a face that faces positive or negative X. The same goes for `create_ylock_face` and `create_zlock_face`, with their respective axes.

All of the basic `create_[xyz]lock_face` functions take in a similar set of arguments:

- `pointA`: A `Vector2`. A corner of the rectangular face to be constructed. The two points are for the not-locked axes. Where possible, `x` corresponds to `x` and `y` corresponds to `y`. For example, if calling `create_xlock_face`, the `y` value will be on `y` and `x` value will be on `z`.
- `pointB`: A `Vector2`. The corner opposite of `pointA`. Works just like `pointA`.
- `[xyz]_pos`: A `float`. The mesh's position on its locked axis.
- `uvA`: A `Vector2`. The UV coordinate of `pointA`. These are applied straight, since  UV coordinates are only `Vector2` types.
- `uvB`: A `Vector2`. The UV coordinate of `pointB`. Works the same as `uvA`.
- `invert_UV_y`: A `bool`. It's been observed that, sometimes, the textures in a mesh will be upside down, contrary to expectation. To help deal with that, this boolean argument is provided. It will flip the `y` of the UV values. Defaults to `true`.

Depending on which corners are passed in for `pointA` and `pointB` will determine whether the mesh faces positive or negative on an axis. The rule-of-thumb is that `pointA` is on the left-hand and `pointB` is on the right-hand.

##### Linear
The *Linear* family of functions were intended to address disjointed textures between surfaces that naturally line up vertically but not horizontally.

These functions turn the `Vector2` arguments of `uvA` and `uvB` into floats. These floats are used to create the `x` values of each UV - the `y` values are automatically calculated using the `y` values in `pointA` and `pointB`. So, a mesh that starts at zero and is three tall will have `y` UV coordinates between zero and three.

While this function family hasn't been removed, it has largely been supplanted in use by the *Shifted* family of functions.

##### Simple
The *Simple* family of functions just removes the `uvA` and `uvB` argument altogether. The UV coordinates are derived entirely from the `pointA` and `pointB` values. Keep in mind that this means you may have to scale materials appropriately.

##### Shifted
The *Shifted* family of functions, similar to the *Simple* family, drop the `uvA` and `uvB` argument in favor of using `pointA` and `pointB`. However, there is an additional argument - the `uv_shift`. This argument allows the programmer to shift the UV coordinates of the mesh directly.

The `uv_shift` is a `Vector3`. The appropriate values are extracted from the `Vector3` and then applied to the UV coordinates. For example, if creating a `ylock_face`, the `x` and `z` values will be used to shift the UV.