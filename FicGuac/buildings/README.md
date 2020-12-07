# Buildings
Buildings in this game are complex setpieces, with their own internal logic. This will eventually include logic for spawning furniture and even getting destroyed, but for now it's mostly visibility stuff.

### Hut
The Hut is currently our only building, and will eventually become the Pawn's default house. It's utilized in several of our tests, largely because it exemplifies the kind of "obscuring" terrain that will likely comprise the game.

## Components
I originally tried making buildings in OpenSCAD and Blender. Not only did I dislike those programs for modeling, but the output wasn't very good, and the pipeline took DAYS.

I decided, then, to create a series of *components* that would allow me to build houses quickly and easily. Think of them like building blocks. The range is a little bit limited right now but there's a lot of potential to expand.

## Textures
This is the directory that contains our texture assets. Most of these assets were designed with a particular ration in mind - 32 pixels corresponding to 1 world unit. You can see this in several textures.

The textures have been sorted into a series of "building materials". Each series is numbered, like `bm_s00` or `bm_s01`. This was done to group assets by their license. You should be aware, then, that not all assets in this directory exist under the project's license. So more restrictive licensing may be present - look out for `.license` files.