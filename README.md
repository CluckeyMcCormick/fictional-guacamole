# Fictional Guacamole
This is an as-of-yet unnamed Godot game project. I would give a more sufficient description than that but the ideas are shifting constantly and I don't want to bind myself. I will say this project is largely for my own satisfaction so I'm not exactly committed to any singular elevator pitch.

However, all iterations of this game have a common core of features:

- 3D isometric perspective
- Deliberate mix of sprites and full models in 3D space
- Heavy emphasis on multi-actor combat (i.e. lots of individuals)

Besides being my personal time-and-energy sink, this project has a broader goal: it's my hope that this project can serve as a learning tool, or the framework from which someone else can build their own project.

That's why I am building the project open-source and on GitHub. I'm trying to make the commits as informative as possible so that the changes in each commit are clear, as well as (more importantly) the reasoning behind those decisions. I hope that this pseudo-development journal serves SOMEBODY (it's already helped me keep track of what I'm doing). 

## Documentation

Rather than using wiki-style documentation, I'm going to document the game using a series of `README` files that are placed in the relevant directories. These scripts will serve to document the expected function and reasoning behind the current directory and it's files. This *documentation-in-place* strategy might be unorthodox but it will enhance this project's utility as a learning tool. It naturally lines up better with how people will experience the repo - by clicking through the various folders to see what-is-what. I haven't ever seen a project do this, which leads me to conclude it's actually a *terrible* idea with some sort of invisible pitfall that will destroy me. :smiley:

Most of this documentation is written with the expectation that it will be viewed both by someone trying to understand the project and by the merely curious. Because textures can be readily observed, they are generally unexplained. Most of the documentation concerns *scenes* and intricacies with the game logic.

 The level of detail in the documents may vary - I take full responsibility and simultaneously refuse to apologize. I am lazy, and I did take shortcuts in some places. Sometimes I didn't have anything particularly unique to say about a directory and I didn't want to repeat myself. Othertimes, scenes were so similar to each other that I grouped their documentation together. In some instances, I also just avoided documentation by pointing out the best way to see how something worked was to play with it.

## Art Style
I'm not much of an artist, so this game hasn't got much of an art style. However, I have developed a set of rules that should make the game somewhat passable.

#### Colors
The game uses a *limited palette*. This really does a lot of the heavy lifting in terms of giving the game a consistent aesthetic. Currently, we use a modified version of *Resurrect64* by [Kerrie Lake](https://kerrielakeportfolio.wordpress.com/) (see the *Colors* directory). The palette has plenty of colors and I like it a lot, so a palette switch is unlikely.

#### Hierarchy of Reality
There's a concept that I'm calling *hierarchy of reality*. The idea is that, to represent something's solidity, power, or stability - it very *realness* - we use sprites or fully realized 3D models. The idea is that the less significant something is, and thus the less its hold on reality, the more flat it becomes. The ultimate end goal is to have the player, either as a single flat entity or commanding a bunch of flat entities, take on and defeat increasingly powerful monsters realized as 3D models. Sort of a David-and-Goliath thing. There are currently 3 (planned) levels:

1. *Flat (Physics) Sprite*: The entity is presented as a flat sprite in game. There is no attempt to hide the fact that this is literally just a flat sprite. There will probably be physics on these items so that they immediately fall over, revealing that it is the pixel equivalent of a cardboard cutout.
1. *Faux-3D Sprite*: The entity is still represented in game as a sprite, but is now rigidly locked to always face the camera. The sprites are actually 3D models, baked into isometric images (and then processed a little bit). 
1. *3D Model*: The entity is represented as a 3D model.

The current issue is that this rule is subordinate to both what looks good and what I'm actually capable of doing.

For example, trees are generally renown for their sturdiness. Following the hierarchy's logic, they should probably be 3D models. However, we're currently using camera-locked 2D sprites, which sort of straddles level 1 and level 2. That's because those tree sprites look pretty and good and I **DEEPLY** doubt my ability to make a good looking 3D model.

Another problem - furniture! I see furniture as kind of ephemeral - by its nature, less sturdy and more temporary than trees. However, because this is something our faux-3D sprites will interact with, we need a way to layer those sprites appropriately. That would mean baking new sprites for every type of sprite interacting with each piece of furniture. And we don't need that. And then, if we want to add physics to the furniture to add to scenes of devastation? In this instance it makes more practical sense for the furniture to be a 3D model.

#### Pixel Ratios
For texturing blocks and other items in the world, it was important that I maintain a consistent pixel count so everything appears to have the right level of detail. The current rule of thumb is *32 pixels per world-unit*. So, a 1x1 quad should be given a 32x32 texture.

There are exceptions to this, especially where higher fidelity is required. For example, the *Pawn* sprites totally flaunt this recommendation.

## Why Godot?
There's a lot of choices for game engines, but I ultimately used Godot. Originally I was messing around with Python, using various libraries to get the results I wanted. I was hoping to stay in Python for easy modding, but Python simply did NOT have the speed for what I needed to do. 

I was kind of interested in Unity, but they didn't support Linux and I refuse to develop in Windows. I had done some work in the jMonkey Engine - which was fun, but I had struggled with it. I was also worried about the logistics of actually deploying a Java applet, and wanted to try something else. 

I'm not sure how I came across Godot, but it allowed me to develop in Linux, headlined cross-platform support, and boasted good performance. That's what really drew me in.

## Running & Compiling
It should go without saying, but just in case: to run any of the code present in this repo, you'll need to download the repo.

The various utility scripts come explanations on how to run them - their associated programs, inputs, and outputs.

If you wish to run or possibly even compile the Godot project, [download the latest version of Godot](https://godotengine.org/download). This project is currently designed for Godot 3.0, and will most likely be incompatible with Godot 4.0 (in it's present state).

Once you've downloaded Godot, running the executable will launch the Project Manager. From this menu, select `Import` and select the downloaded repo's `FicGuac/project.godot` file.

At this point, running or compiling the project is the same as any other Godot project - a tutorial on that exceeds the scope of this document.

## Licensing
Unless otherwise stated (typically through a `.license` file), all the code and assets are distributed under the MIT license.

This project makes frequent use of open-source game art from the [OpenGameArt.org](https://opengameart.org/) community, especially for textures and sprites. These assets typically come under their own, more restrictive licenses - if you derive any project from this, make sure to keep track of those assets and not violate the terms there-in!
