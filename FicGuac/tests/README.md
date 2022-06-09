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

## Viewport Shader Test
This scene tests various *Viewport Shaders* from our *Special Effects* directory. More specifically, it serves as a test of all the *Viewport Shaders* that are used for cutaways/xray - i.e. showing the position of something behind an occluding surface. It tests how these shaders interact with each other and various extant game assets.

## Dynamic Navigation Test
This scene tests dynamic navigation meshes - how the *Pawn* follows them, and how they interact with existing game assets. It also features *Viewport Shaders* in an actual use case.

## Advanced Kinematics Test
The *Advanced Kinematics Test* was constructed to test out the movement abilities of our AI. It features three tests - the fall test, the slope test, and the step test. The slope and the step test have configurations so we can test different levels with ease. The fall test allows us to test how the *Pawn* falls.

This test also sports a force-cancel button and a time-dilation slider for extra ease-of-use.

## Rat Emulation Test
This test is meant to test out the `RatPawn`, which is an intermediate step in developing our AI. It also serves as an early test of how we can use *Qodot* and *TrenchBroom* classes. 

## Basic Item Test
This test tries out some very basic item pick-up, moving, and dropping. It only moves one item at a time and has a tendency to accidentally punt some items off the edge.

## Advanced Item Test
An improved version of the Basic Item Test. Features an actual item testing arena - with walls. Spawns the items on demand and moves them to a random location. Some items are purposefully spawned out of reach, to test failure state resolution. Also ensures we don't try to grab items through walls.

## Particle Zoo Test
Particle effects are an efficient way of rendering certain phenomenon - even if they can hurt performance. The purposes of this test is to:

- Test the performance impact of having many particle effects on screen at once.
- Observe how the particle effects behave/appear when in motion.
- Test the scaling behavior of scalable particle systems.

This test auto-populates the available particle systems from `Manifest`'s `PARTICLE_BLUEPRINTS` and `PARTICLE_SCENES` dictionaries.

## Condition Zoo Test
This test allows us to view the effects of various conditions against various types of world agents.