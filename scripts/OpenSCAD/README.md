# OpenSCAD Scripts
>Note: this README was written for those who may be unfamiliar with OpenSCAD or programming in general. These scripts are part of this project's art asset pipeline and may be used by people who aren't programmeing pros or have never used a CAD (computer-aided design) program at all. The script descriptions will still be useful for more advanced users.

[OpenSCAD](http://www.openscad.org/) is a cross-platform 3D modeling program that generates shapes using programming-language scripts. It is mostly intended for use with 3D printing, but the models can
be used for other purposes.

As a programmer first and for most, OpenSCAD naturally appeals to my sensibilities. Being programmatic makes fine control much easier. It's always been easier for me to understand shapes as compositions and extractions of other shapes, which OpenSCAD allows for. It also allows for directly plugging in vertices, which always makes me a lot happier.

However, OpenSCAD has limited animation capabilities and no lighting or texturing. It also can't export a model in a format compatible with Godot. So we use OpenSCAD for any heavy modeling, and then use Blender for animation and sprite-making.

### OpenSCAD Syntax

OpenSCAD uses a *functional* programming language. An explanation of *EXACTLY* what that means exceeds the scope of this README, but you should know why these OpenSCAD scripts might appear as indecipherable nonsense.

The most common programming languages today are *imperative* programming languages. You modify the state of the program by issuing a series of commands in a basically linear order (*except for when it doesn't but that also exceeds this document's scope*). It's like writing a set of instructions - do A, do B, then do C.

A *functional* programming language, on the other hand is... harder to describe. A lot of programmers (myself included) really struggle with functional programming because it's like an entirely different way of thinking. It's like speaking a second or third language, in a way. I can only imagine how difficult a read it is for someone completely unversed in any form of programming.

Basically, in functional programming, a program's state resets after one instruction. That's honestly probably wrong but for the purpose of **understanding** we're gonna run with it. Anyway, because it works like that, the only way to chain instructions together is to nest them inside of each other. This has the unfortunate side effect of the **first instruction actually being the last instruction acted upon**. I think this is a too-broad generalization of functional programming languages, but it is **exactly correct in OpenSCAD**.

For example - let's say we want a red cube that sits at `(10, 10, 10)`, with each side having a length of `1`. 

In an imperative programming language, this would look like:

```
cube([1,1,1]);
color("red");
translate([10,10,10]);
```

But in OpenSCAD, this all get's turned around. There's multiple ways to write this; you could do:

```
translate([10,10,10]) color("red") cube([1,1,1]);
```

Or you could do:

```
translate([10,10,10])
{
    color("red")
    {
        cube([1,1,1]);
    }
}
```

You can see how `translate` is now the first command, even though it's the last instruction run. The best way to understand this is as a sentence - like the [OpenSCAD documentation](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/First_Steps/Changing_the_color_of_an_object) says:

> If you think of the entire command as a sentence, then `color()` is an "adjective" that describes the "object" of the sentence (which is a "noun"). In this case, the object is the `cube()` to be created. The adjective is placed before the noun in the sentence, like so: `color() cube();`. In the same way, `translate()` can be thought of as a "verb" that acts upon the object...

I hope that gives someone some level of understanding, however minor. If you're having a hard time understanding the nonsense (understandable), try messing around with the OpenSCAD scripts to see what shapes you can get. Start by modifying constants and then see if you can move on to applying different functions.

## Included Scripts

### `weapon_short_sword.scad`
This script generates our standard short (i.e. one handed) sword model. The constant-parameters in this script allow us to control:

- The Pommel
- The Grip
- The Guard
- The Blade (including the Edge, the Tip, and the Fuller)

There's been a great amount of work done towards describing how swords looked at particular times, and how the forms evolved between the different periods of time. I have largely ignored this for my own ease.