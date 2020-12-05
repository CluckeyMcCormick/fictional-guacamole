# Fictional Guacamole
This is an as-of-yet unnamed Godot game project. I would give a more sufficient description than that but the ideas are shifting constantly and I don't want to bind myself. I will say this project is largely for my own satisfaction so I'm not exactly committed to any singular elevator pitch.

However, all iterations of this game have a common core of features:

- 3D isometric perspective
- Deliberate mix of sprites and full models in 3D space
- Heavy emphasis on multi-actor combat (i.e. lots of individuals)

Besides being my personal time-and-energy sink, this project has a broader goal: it's my hope that this project can serve as a learning tool, or the framework from which someone else can build their own project.

That's why I am building the project open-source and GitHub. I'm trying to make the commits as informative as possible so that the changes in each commit are clear, as well as (more importantly) the reasoning behind those decisions. I hope that this pseudo-development journal serves SOMEBODY (it's already helped me keep track of what I'm doing). 

Rather than using wiki-style documentation, I'm going to document the game using a series of `README` files that are placed in the relevant directories. These scripts will serve to document the expected function and reasoning behind the current directory and it's files. This *documentation-in-place* strategy might be unorthodox but it will enhance this project's utility as a learning project. It naturally lines up better with how people will experience the repo - by clicking through the various folders to see what-is-what. I haven't ever seen a project do this, which leads me to conclude it's actually a *terrible* idea with some sort of invisible pitfall that will destroy me. :smiley:

Most of this documentation is written with the expectation that it will be viewed both by someone trying to understand the project and by the merely curious - so the level of detail in the documents may vary.

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
