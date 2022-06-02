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

Each status condition has both a series of modifiers and scalable particle effects. Preconstructed particle effects can also be added into derived status condition scenes - the status condition is a spatial node centered on the status core. You can thus translate the preconstructed particle effect as you see fit.

### Inner Classes
The `BaseStatusCondition` has some inner classes that are integral to how we define status conditions:

#### StatOp
This is an `enum` that's actually a bit tricky to explain. See there's all sorts of stat modifications - for example, a stat could go up by a flat +10, or it could go up by 10%. That's two different sorts of operations on a single stat. This `enum` exists to differentiate between these *stat operation* types (hence `StatOp`).

The current values for this `enum` are:

- `FLAT_MOD`
    + This modifier just adds a given value to stat. This value is not interpreted in any extra way, it's just straight-added.
- `ADD_SCALE_MOD`
    + This modifier adds to a target stat the product of a given value and another (not necessarily different) base stat. For example, if the target stat is `max_hits`, the base stat is `hit_potential` and the modifier is `.10`, then the result would be `max_hits += hit_potential * .10`. This is meant for percentage gains, like 23% gain or loss to some stat. Again, it could be the same stat for both base and target, though this is discouraged.

#### StatMod
This is a custom inner class used to define a single modification against a stat. There are fields for base-and-target stats, in case calculating the modification is derived from a base stat (i.e. `StatOp.ADD_SCALE_MOD` operations).

##### (Public) Variables

###### `target_var`
The string name of the field we're targeting. In other words, it's the actual field that is BEING dynamically modified. Using a string allows us to dynamically apply the modifiers - for example, we can check if a status core actually has a variable before applying the status effect. This means the game won't crash, even if an invalid side effect gets on an object.

###### `scale_base_var`
The string name of the field we derive scale-based calculations from; this is the field that gets used by `StatOp.ADD_SCALE_MOD` type operations. It is effectively ignored for `StatOp.FLAT_MOD` type operations, and can be left blank for those modifiers.

###### `operation`
This determines what kind of operation we're performing with the modifier. Needs to be a `StatOp` value. Check the `StatOp` `enum` for more.

###### `mod_value`
This is the actual modification value - the -.25 or +23 or whatever you need it to be. This should be an int or a float of some sort.

##### Functions

###### `_init`
This is what gets called when building the class - i.e. when calling `StatMod.new()`. It takes five arguments, which are basically just pass-throughs to what I outlined above:

1. `targ_var`: value for `target_var`.
1. `scale_var`: value for `scale_base_var`.
1. `op`: value for `operation`.
1. `mod`: value for `mod_value`.

### Configurables

#### Lifetime
The time, in seconds, that this status effect lasts for. A negative value, or zero value, means never-ending. Note that this doesn't mean the status effect can't be reversed by other means, just that it doesn't naturally go away.

#### DOT Damage
This variable is the damage applied every time the damage-over-time (DOT) interval (see below) occurs.  

#### DOT Interval
This is the frequency, in seconds, that the damage-over-time (DOT) occurs. In other words, every `dot_interval` seconds, the status effect inflicts `dot_damage` damage.

#### Icon
The icon used to represent this status effect. Though currently unused, we may use it for some sort of health-bar or other status-display.

#### Keyname
When we add a status condition to the `CommonStatsCore` (or a deriving scene), we register status effect using a unique name. We also remove the status effect using this unique name. This should be unique against all status effects in the game.

#### Human Name
This is the name of the status effect that is displayed to the player - i.e. *On Fire* or *Pox Ridden* or something.

### Functions
Now, if it were up to me, the `BaseStatusCondition` wouldn't have any functions. But there's one problem - we need a consistent way to get a status' modifiers and particles. Godot doesn't let us overwrite a variable declared in a parent scene/class outside of a function, so we can't do this with variables. Instead, we need to define these variables per-status-effect and return them through some common functions.

##### `get_modifiers`
Returns an array of `StatMod` objects - these are the actual modifiers to be applied.

##### `get_scalable_particles`
Returns an array of particle effects for this status effect. These must be loaded `ScalableParticleBlueprint` resources. If you wish to use a preconstructed particle effect, do not add it to this array - add it as a child of the deriving scene's node.