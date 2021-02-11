# Tests
The core concept behind the *Tests* directory is that we should have scenes to test - to every extent possible - singular concepts in the game. This allows us to establish a baseline for error testing.

These tests frequently serve as the point-of-development for the features they test. For example, we developed and tested *Dynamic Navigation* in the corresponding test. Because of that, they change often.

Each scene has been designed to run individually. If you wish to run them using a common menu, see the *Test Shell* in the *Test GUI Core*.

Note that the tests are listed here are not necessarily in alphabetical order, but from "simplest" to "most complex". In other words, tests listed later generally build on features that were tested in isolation in the earlier tests. For example, we may have a test for integration with navigation meshes, and then most subsequent tests have navigation meshes as a given.

### Test Assets
Some tests require scenes and assets that don't have a place in the wider project. Those wayward items go here. This includes various visual experiments, like alternate sprites.

### Test GUI Core
One of the problems with running the scenes individually is that it doesn't test certain aspects of Godot. For example, how graceful are scene transitions? Is there a load time associated with certain assets? Is there necessary cleanup that needs to be prepared when a scene exits?

The scenes in *Test GUI Core* provide us with a method for testing these transitions, and provide a common GUI to all test scenes. 

### TrenchBroom
This directory contains the various `.map` files used by *TrenchBroom* and *Qodot* to generate our test terrain.

## Pawn Standing Test
This test is literally just to test how the *Pawn*'s various sprites look when standing still.

It was difficult, without this test, to adjust the collision shape to the correct size. If the shape is too tall, the Pawn noticeably floats. If the shape is too short, the Pawn is clipped into the ground.

Trying to test this in other scenes, where the *Pawn* is frequently moving and spazzing around, was difficult. This scene serves as a perfect test bed.

## Cubit Driver Test
The *Kinematic Driver* is the core concept being tested here. It's meant to test both the driver's basic movement functionality as well as demonstrate how easy it is to make integrate and use the *Kinematic Driver*.

## Slope Step Test
A very key test, this scene tests how the *Pawn* tackles slopes of a certain steepness and slopes of a certain height. This is very important to how the *Pawn* moves around the world.

It could use an update - there should be a button to skip the current test.

As the potential movement types increase, there will probably be a new test that is similar to this one (yet tests everything a bit more).

## Viewport Shader Test
This scene tests various *Viewport Shaders* from our *Special Effects* directory. More specifically, it serves as a test of all the *Viewport Shaders* that are used for cutaways/xray - i.e. showing the position of something behind an occluding surface. It tests how these shaders interact with each other and various extant game assets.

## Dynamic Navigation Test
This scene tests dynamic navigation meshes - how the *Pawn* follows them, and how they interact with existing game assets. It also features *Viewport Shaders* in an actual use case.

## Advanced Kinematics Test
While the *Slope Step Test* was good, it suffered from some pretty serious handicaps. We couldn't skip or cancel tests, the tests were constructed by hand (which was hard to modify), we couldn't modulate the time at all, and it was difficult to observe the *Pawn* falling.

I became that there MUST have been a better way. The *Advanced Kinematics Test* is the sum of that effort. It features three tests - the fall test, the slope test, and the step test. The slope and the step test have configurations so we can test different levels with ease. The fall test allows us to test how the *Pawn* falls.

This test also sports a force-cancel button and a time-dilation slider for extra ease-of-use.