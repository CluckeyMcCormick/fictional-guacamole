# Trees
This directory contains all the scenes (and some of the assets) relating to our trees.

## Woods
The *Woods* scene is the current scene for grouping trees - rather than manually placing trees, it allows us to place wide swaths of trees over a specified area. Unfortunately, it's mostly a prototype right now. It only places trees in a square and doesn't alter their position at all. This will most likely see changes or possible modifications in the future.

Currently comes with darkened grass tiles placed under the trees. Trees are only placed om the middle tiles; the edge tiles are left empty.

### Configurables
##### Woods Size
The size of the woods, on X and Z (in this case, the Y configurable is Z). Has a minimum size of (3, 3).

## GrassToDarkGrassLibrary
To create the tiling in the *Woods* scene, we use a `GridMap` node. This requires a `MeshLib` resource as input and, ergo, a scene to export as a `Meshlib`. This is that scene. 

It consists of 8 edge tiles and 1 center tile. The four corners should only occur once; the other five tiles can be repeated ad nauseam.

## PineTree
The *PineTree* scene is, currently, our only tree. It comes with controls for easily switching between three different kinds of trees (which are all just palette swaps)

The tree itself is currently implemented as an `AnimatedSprite`. This was a deliberate choice with several key advantages. It makes switching between different types of trees and sprite trivial - we don't need to load different assets, we just need to build the correct animation string. This is useful for any state change - maybe the tree burning down, or getting snowed or, or showing light level, or a change of seasons (probably not with pine trees). It will also making animating the trees easier. I'd really like for that to happen at some point but there's no way I could personally do that.

Another oddity of the *PineTree* is that it actually has two sprites - the primary sprite, and an alternate sprite. Since the *PineTree* uses a large sprite that can easily occlude other sprites, we need an alternate sprite that blocks less of the screen. Currently, this sprite is more or less just a stump.

While it's currently recommended to use the *Woods* scene, the *PineTree* is perfectly self-contained and ready to be placed in any scene by hand.

##### Tree Type
Control for different types of trees. Simple-and-easy dropdown list.