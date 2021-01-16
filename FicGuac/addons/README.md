# Addons
Any *Godot* addons - other people's code and assets distributed through the *Godot Asset Library* - go here.

### Godot Navigation Lite
As of this writing, the current version of Godot doesn't support dynamic navigation meshes (i.e. navigate meshes that can be baked in-game). This is very bad for a procedurally generated game, like ours.

This library, by **Miloš Lukić**, solves that issue by providing a navigation mesh that can be baked on the fly as we add or remove obstacles. It works... pretty well. I've noticed that it kind of struggles with the peaked roofs of buildings. Other than that, I'm happy with it.

However, it doesn't support Mac OS, which severely limits the platforms we can target. It's also got limited obstacle avoidance. In recognition of this, we'll probably remove it whenever Godot 4.0 comes out, since that version will support dynamic navigation meshes natively.

### XSM Extended State Machine
This library, created by **Etienne Blanc**, provides us with a solid foundation for making a state machine in Godot. It provides a pretty solid basis and, better yet, it's written entirely in GDScript - that means it should be compatible with all platforms and with Godot 4.0.

My only problem with this library is that there's only one update method - `_on_update(_delta)`. This is actually wrapped in the `_physics_process` call, meaning it's always a Physics update. I'm not a fan of that because it doesn't allow us to make use of the parallel `_process` call. Simpler, I know, but not exactly better. I may modify this plugin so that we have update functions for both physics and regular processes.

Looking at the example it looks like the solution is to spread the functionality across multiple state updates, since those run somewhat in parallel. We'll work with it, as it is, for now.