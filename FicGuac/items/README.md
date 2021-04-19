# Items
Items are anything and everything the can be carried, hauled, consumed, stored, and equipped. And also furniture. For now.

Each item should be a `RigidBody3D`, and be derived from the `MasterItem` scene (see below).

Each item has two states: either *Physical* or *Visual*. In *Physical* mode, the item can be detected and reacts to physics - in other words, it behaves just as you would expect a physics object to behave. *Physical* mode is intended for when an object has been dropped and is free-floating out in the world.

In *Visual* mode, the item becomes static and no longer collides with anything. This is the intended mode for when an item is being held, equipped, or otherwise stored. When an item switches to *Visual* mode, it's layer and mask collisions are stored - they are restored once the item re-enters *Physical* mode.

The item always starts in *Physical* mode.

One other item of note - the closest thing *Godot* has to some sort of data tags or tagging system is the *group* system. Because of this, what an actor is able to do with an item is determined by it's relationships with the item's different groups. This is currently being fleshed out and will likely be subject to change.

## MasterItem
The *MasterItem* class defines the basic attributes and interface for all items in this project. The *MasterItem* is effectively just a shell. All items should be derived from this scene. This is critical for the game to function correctly - we confirm if an item is actually an item by checking if it is a *MasterItem*.

Any deriving scenes will need to add nodes for the visuals and collision model, as the *MasterItem* is literally just a shell.

This scene starts with an initial rotation of 45 degrees on the Y axis. With this rotation, flat sprite-based items should be perpendicular to the game's camera at spawn time. This isn't a specific requirement, so feel free to change this.

The only collision layer/mask requirement is that the object exist on the *Item* layer. This is critical for actually detecting items as items. The other layer/mask options can be experimented with.

### Configurables

##### Name Key
The item's unique name key. This is meant both as the item's display name - i.e. Bread or Cheese - but also as the key for identifying items of a type. In other words, this is the value that will be compared to see if two items are, in fact, the same type of item.

##### Max Carry Stack
When items are carried, they are carried by units in a stack. A stack can only contain one type of item (type being determined by the *Name Key* field). The amount of items that can be stacked depends on this configurable.

##### Is 3D
Is this item a three-dimensional item? By default, we consider items to be 2D. When 2D items are stacked, they are laid flat. This looks fine for 2D items, but would cause all kinds of clipping with 3D items. We need this configurable to distinguish between 2D items and 3D items, as 3D items require extra processing. 

##### Visualized Offset 3D
When this item is considered 3D and is visualized, this is the initial offset in the stack from wherever the "base" would be. In most instances, that's the origin of the *Item Management Core*. This is required because, otherwise, the 3D item could clip into whatever is holding the item.

##### Stack Space 3D
When this item is considered 3D and is visualized, and is then stacked, this is the offset between two 3D items in the stack. It's effectively the origin-to-origin offset of any two 3D items in the stack.

##### Visualized Rotation 3D
When this item is considered 3D and is visualized, it is set to this rotation. Again, this is so we can anticipate and deal with possible clipping incidents in the stack.

### (Public) Variables

##### `_item_state`
The current item state. Set to one of two constants (see below). Should be used in a read-only capacity; setting this variable could have unintended consequences.

### Constants

##### `ITEM_PHYSICAL`
Value used to indicate that the item is currently in the *Physical* mode.

##### `ITEM_VISUAL`
Value used to indicate that the item is currently in the *Visual* mode.

### Functions

##### `_to_visual_item`
Converts this item from *Physical* mode to *Visual* mode. Has no effect if the item was already in *Visual* mode. Returns the item.

##### `_to_physical_item`
Converts this item from *Visual* mode to *Physical* mode. Has no effect if the item was already in *Physical* mode. Returns the item.

Note that this doesn't remove the item from whatever circumstances it was in - i.e. whether it was held, or stacked, or contained, etc.

## Corpses
Contains different corpses for different creatures in the game.

## Food
Contains different food items. Contains sprites with different licenses, so be wary.

## Furniture
Different furniture items. Furniture needs to be crafted, transported, and installed. I also like the imagery of chairs being sent flying as a building explodes, which is the primary reason their counted as items - but I believe they'll eventually need to be moved into their own sort of category.

## Weapons
Contains different weapon items. 