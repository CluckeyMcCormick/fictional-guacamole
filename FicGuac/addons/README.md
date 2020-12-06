# Addons
Any *Godot* addons - other people's code and assets distributed through the *Godot Asset Library* - go here.

### Godot Navigation Lite
As of this writing, the current version of Godot doesn't support dynamic navigation meshes (i.e. navigate meshes that can be baked in-game). This is very bad for a procedurally generated game, like ours.

This library, by **Miloš Lukić**, solves that issue by providing a navigation mesh that can be baked on the fly as we add or remove obstacles. It works... pretty well. I've noticed that it kind of struggles with the peaked roofs of buildings. Other than that, I'm happy with it.

However, it doesn't support Mac OS, which severely limits the platforms we can target. It's also got limited obstacle avoidance. In recognition of this, we'll probably remove it whenever Godot 4.0 comes out, since that version will support dynamic navigation meshes natively.