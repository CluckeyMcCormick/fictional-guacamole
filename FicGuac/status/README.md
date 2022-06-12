# Status
This directory is for resources, scenes, and scripts associated with object/motion AI status - health, being on fire, etc. It's something that doesn't quite belong to the Motion AI, nor do it belong to objects. It's really a category all it's own.

## Directories

### Conditions
Home directory for status conditions, which are nodes derived from the `BaseStatusCondition` node.

## CommonStatsCore
The *CommonStatsCore* is the core *status* component for our damage-taking physics objects. This includes *Motion AI*, but also *Items*, or possibly even *Props* or *Scenery*. It is the singular reference point for status (i.e. health points). It was designed as a *core* becuase it was originally meant for use purely with *Motion AI*. However, I realized that a whole lot more than just *Motion AI* needed to take damage, and we'd need a common way to handle that EVERYWHERE.

However, because it needs to be common to everything, this node is purposefully very vague - it's meant to be inherited by other scenes so that we can create more specific status cores as needed.

Also, we call it a *stats* core because the *status* concept extends to what we would commonly call a character's stats - stuff like move speed, for example.

This core divides the stats into "base" stats - what the stats should be initially - and the "current" or "effective" status.

### Configurables
##### Base HP
The base hitpoints for the object. This currently acts as both the default amount of health and a cap. Note that this is an `int` value!

##### Damage Floats
Controls whether we spawn *damage floats* whenever this core takes damage. *Damage floats* are little floating pieces of text, implemented via the `FloatAwayText` scene. It helps us gauge how much damage was done, and where the damage was done.

### (Public) Variables
##### `curr_hp`
The current hitpoints for the object. This is not modified by buffs or debuffs; it is just a measure of health. This can be modified directly but it is recommended that you use the provided functions.

##### `dead`
A boolean value indicating whether the core is currently dead or not. This should not be altered directly.

### Functions

##### `add_status_effect`
Takes in a `BaseStatusCondition`-derived/inherited class and applies it to the core.

##### `remove_status_effect`
Takes in a string and removes the corresponding status effect. The string should correspond to a `BaseStatusCondition`'s `keyname` field, which is how we track the ongoing status conditions.

##### `clear_status_effects`
Removes all the status effects from this core.

##### `take_damage`
Takes in an amount of damage and a damage type, dealing the specified amount of damage to the core (allowing for different resistances, of course). Emits the `object_died` signal if the core bottoms out on hitpoints. Also spawns *Damage Floats* if that's enabled.

The resulting `curr_hp` value is clamped between 0 and *Base HP*.

This should always be used when dealing damage to the core.

The damage will not be dealt if the core is already dead.

##### `heal_damage`
Takes in an amount of damage to heal, healing the core for that amount. This does not spawn *Damage Floats*.

The resulting `curr_hp` value is clamped between 0 and *Base HP*.

No damage will be healed if the core is already dead.

This should always be used when healing damage on the core.

### Signals
##### `object_died`
Emitted when the hitpoints reach zero - in other words, when we die.

## BaseStatusCondition
Sometimes, you have to modify some of the stats temporarily, or apply damage at a fixed interval, or so-on-and-so-on. That's where status effects come in! All status effects are separate scenes, and this class is the base class/scene that they all derive from. This base class defines the structure of the status conditions, while the actual content is defined in the derived status condition scenes.

Each status condition has both a series of modifiers and scalable particle effects. Preconstructed particle effects can also be added into derived status condition scenes - the status condition is a spatial node centered on the status core. You can thus translate, scale, and rotate the preconstructed particle effect as you see fit.

### Configurables

#### Limited Lifespan
Does this condition have a limited lifespan - i.e. does it persist for a fixed amount of time before naturally dissipating? Defaults to true.

If true, the lifetime is specified by the "wait time" field on the `LifetimeTimer` node - this timer is automatically started once the condition enters the scene. Once the timer expires, the `condition_expired` signal fires.

The "wait time" field should be adjusted appropriately on the `LifetimeTimer` in each deriving scene.

#### Damage Over Time
Does this condition deal damage over time - i.e. does the condition deal a fixed amount of damage at fixed intervals for the duration of it's existence?

If true, the damage interval is specified by the "wait time" field on the `DamageIntervalTimer` node - this timer is automatically started once the condition enters the scene, and restarted once it completes. Every time the timer expires, the `dot_damaged` signal is fired.

The "wait time" field should be adjusted appropriately on the `DamageIntervalTimer` in each deriving scene.

#### DOT Damage
This variable is the damage applied at every damage-over-time (DOT) interval. Ideally an *int* of some kind.

#### Icon
The icon used to represent this status effect. Though currently unused, we may use it for some sort of health-bar or other status-display.

#### Keyname
When we add a status condition to the `CommonStatsCore` (or a deriving scene), we register status effect using a unique name. We also remove the status effect using this unique name. This should be unique against all status effects in the game.

#### Human Name
This is the name of the status effect that is displayed to the player - i.e. *On Fire* or *Pox Ridden* or something.

### Functions
Now, if it were up to me, the `BaseStatusCondition` wouldn't have any functions. But there's one problem - we need a consistent way to get a status' modifiers and particles. Godot doesn't let us overwrite a variable declared in a parent scene/class outside of a function, so we can't do this with variables. Instead, we need to define these variables per-status-effect and return them through some common functions.

##### `get_modifiers`
Returns an array of `StatMod` objects (see below) - these are the actual modifiers to be applied.

##### `get_scalable_particles`
Returns an array of particle effects for this status effect. These must be loaded `ScalableParticleBlueprint` resources. If you wish to use a preconstructed particle effect, do not add it to this array - add it as a child of the deriving scene's node.

### Signals
##### `condition_expired`
Emitted when the `LifetimeTimer` expires/finishes/runs out of time. Indicates that the status effect has run it's course and should be removed. Emits with the corresponding status effect.

##### `dot_damaged`
Emitted when the `DamageIntervalTimer` expires/finishes/runs out of time. Indicates that the status effect is dealing damage. Emits with the corresponding status effect and the damage value (which will be *DOT Damage*).

## StatMod
An individual `StatMod` instance defines a single modification against a stat. The different types of `StatMod` classes have different behaviors - i.e. they modify values using different calculations. This is the base `StatMod` class, and defines a modifier that just adds a given value to stat. This value is not interpreted in any extra way, it's just straight-added.

### (Public) Variables

#### `target_var`
The string name of the field we're targeting. In other words, it's the actual field that is BEING dynamically modified. Using a string allows us to dynamically apply the modifiers - for example, we can check if a status core actually has a variable before applying the status effect. This means the game won't crash, even if an invalid side effect gets on an object.

#### `mod_value`
This is the actual modification value - the -.25 or +23 or whatever you need it to be. This should be an int or a float of some sort.

#### `_applied_value`
This modification value that was applied to the `target_var` - we use this to keep track of what value was last applied to a stat. Ergo, it's recommended that you don't mess with this.

### Functions

#### `_init`
This is what gets called when building the class - i.e. when calling `StatModFlat.new()`. It takes two arguments, which are basically just pass-throughs to what I outlined above:

1. `targ_var`: value for `target_var`.
1. `mod`: value for `mod_value`.

#### `apply`
This function takes in a `CommonStatsCore` (or derivative/inheriting class) and a *scalar*. It applies the stat change to the core (unapplying any previous changes). The *scalar* is there if, for whatever reason, the `mod_value` needs to be scaled - this is intended for stacking status effects.

#### `unapply`
This function takes in a `CommonStatsCore` (or derivative/inheriting class) and removes the previously applied stat change. Keep in mind that this is tracked as dumbly as possible - the modifier just assumes the given core had the change applied and reverses it. Defaults the `_applied_value` to 0.

## StatModBaseScale
This `StatMod`-derived class adds to a target stat the product of a given value and another (not necessarily different) base stat. For example, if the target stat is `max_hits`, and the base stat is `hit_potential`, and the modifier is `.10`, then the result would be `max_hits += hit_potential * .10`. This is meant for percentage gains, like 23% gain or loss to some stat. Again, it could be the same stat for both base and target, though this is discouraged.

### (Public) Variables
In addition to the variables inherited from `StatMod`, this class has the following variables.

#### `base_var`
The string name of the field we derive scale-based calculations from. This two-field system exists to ensure modifiers are not stacked; or rather, that they are only stacked in the appropriate way. If we used only one field for scaling operations, then applying this mod ahead of or after a `StatModBaseScale` would have two completely different results. 

### Functions
In addition to the functions inherited from `StatMod`, this class has the following functions.

#### `_init`
This overwrites the `StatMod` class' `_init` function. This is what gets called when building the class - i.e. when calling `StatModBaseScale.new()`. It takes three arguments, which are basically just pass-throughs to what I outlined above:

1. `targ_var`: value for `target_var`.
1. `base`: value for `base_var`.
1. `mod`: value for `mod_value`.

#### `apply`
This function overwrites the `StatMod` class' `apply` function. The only thing notable here is the redefined stat modifying algorithm.