extends Node

# This mode is a manifest - a list of lists, if you will, of various parts of
# our game compiled here for easy access across multiple child scenes. The core
# idea of placing this in a global, autoloading scene instead of in invidual
# appropriate scenes is actually done for modders, of all things. These
# centralized lists make it easy to add custom scenes to the appropriate
# categories from anywhere in the game. Of course, I suppose there's a danger to
# that but that is just the price of convenience. And modability!

# Different test scenes
var TEST_SCENES = {
    "Pawn Standing Test" : "res://tests/PawnStandingTest.tscn",
    "Cubit Driver Test" : "res://tests/CubitDriverTest.tscn",
    "Viewport Shader Test" : "res://tests/ViewportShaderTest.tscn",
    "Dynamic Navigation Mesh Test" : "res://tests/DynamicNavMeshTest.tscn",
    "Advanced Kinematics Test" : "res://tests/AdvancedKinematicTest.tscn",
    "Rat Emulation Test" : "res://tests/RatEmulationTest.tscn",
    "Basic Item Test" : "res://tests/BasicItemTest.tscn",
    "Advanced Item Test" : "res://tests/AdvancedItemTest.tscn",
    "Attack Model Test" : "res://tests/AttackModelTest.tscn",
    "Particle Zoo Test" : "res://tests/ParticleZooTest.tscn",
}

# Different particle materials
var PARTICLE_MATERIALS = {
    "Fire, Diamond32" : "res://special_effects/particles/FireDiamond32_mat.tres",
    "Poison, Bubble32" : "res://special_effects/particles/PoisonBubble32_mat.tres",
}
