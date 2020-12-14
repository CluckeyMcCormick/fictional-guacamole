# Farm
This directory contains all our assets and scenes relating to our *Farm* scene. The scene itself is pretty simple; there's just a lot subscenes that go into it.

## Farm
The actual *Farm* scene that the whole directory is dedicated to. It allows us to create a field of crops to an exact size. Currently this only allows rectangular fields - which is actually how fields typically look, so that's fine.

### Configurables
##### Plot Size
The size of the farm field/plot, on X and Z (in this case, the Y configurable is Z). Has a minimum size of (3, 3).

##### Crop Type
The type of crop planted in this field. Each type of crop is it's own scene and, because of that, can have any number of unique behaviors.

## Crops
The directory where the crops scenes and assets are stored. Word of warning - I made most of the assets myself and they're pretty much all awful. They're all good, codewise.

## GrassToDirtLibrary
To create the tiling in the *Farm* scene, we use a `GridMap` node. This requires a `MeshLib` resource as input and, ergo, a scene to export as a `Meshlib`. This is that scene. 

It consists of 8 edge tiles and 1 center tile. The four corners should only occur once; the other five tiles can be repeated ad nauseam.