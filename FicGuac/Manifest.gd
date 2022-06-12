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
    "Condition Zoo Test" : "res://tests/ConditionZoo.tscn",
}

# Scalable Particle Blueprint (SPB) manifest - these are meant to be used with
# dynamically created ScalableParticleEmitter nodes
var PARTICLE_BLUEPRINTS = {
    "SPB Fire, Fusil32" : "res://special_effects/particles/scalable_blueprints/spb_fire.tres",
    "SPB Fire Explosion" : "res://special_effects/particles/scalable_blueprints/spb_fire_explosion.tres",
    "SPB Smoke Explosion" : "res://special_effects/particles/scalable_blueprints/spb_smoke_explosion.tres",
    "SPB Poison, Bubble32" : "res://special_effects/particles/scalable_blueprints/spb_poison_bubbles.tres",
    "SPB Red Hit, Cross64" : "res://special_effects/particles/scalable_blueprints/spb_hit_cross.tres",
    "SPB Red Hit, DiagonalA64" : "res://special_effects/particles/scalable_blueprints/spb_hit_diag_a.tres",
    "SPB Red Hit, DiagonalB64" : "res://special_effects/particles/scalable_blueprints/spb_hit_diag_b.tres",
    "SPB Red Hit, Horizontal64" : "res://special_effects/particles/scalable_blueprints/spb_hit_horizontal.tres",
    "SPB Red Hit, Vertical64" : "res://special_effects/particles/scalable_blueprints/spb_hit_vertical.tres",
    "SPB Tropical Sample Helix" : "res://special_effects/particles/scalable_blueprints/spb_tropical_sample_helix.tres",
}

# Prebuilt particle scenes
var PARTICLE_SCENES = {
    "Red-Blue Fusil Helix" : "res://special_effects/particles/complete_systems/ParticleDNA.tscn",
}

# Status Conditions
var STATUS_CONDITIONS = {
    "Adrenaline" : "res://status/conditions/Adrenaline.tscn",
    "On Fire" : "res://status/conditions/OnFire.tscn",
}
