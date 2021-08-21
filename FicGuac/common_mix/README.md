# Common Mix
This directory is for things that are common across scenes and scripts across multiple categories but didn't cleanly fit into their own category - it is a mix of common things, hence "Common Mix".

This phenomenon happens a lot with our different physics classes - our structures, actors, and items all behave differently and are stored in different directories but typically need common code.

## CommonStatsCore
The *CommonStatsCore* is the core *status* component for our damage-taking physics objects. This includes *Motion AI*, but also *Items*. It is the singular reference point for status (i.e. health points).

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


