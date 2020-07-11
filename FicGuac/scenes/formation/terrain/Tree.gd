extends StaticBody

enum TREE_TYPE {
    elm, pine, oak
}

enum LIGHT_LEVEL {
    light, dark
}

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export(TREE_TYPE) var _tree_type = TREE_TYPE.elm
export(LIGHT_LEVEL) var _light_level = LIGHT_LEVEL.light

# Called when the node enters the scene tree for the first time.
func _ready():
    # Immediately set the tree type using our preset tree type and light level
    set_tree_type(self._tree_type, self._light_level)

func set_tree_type(new_tree_type, new_light_level):
    # Disable all the collision models - we'll give ourselves a clean slate.
    $CollisionElm.disabled = true
    $CollisionPine.disabled = true
    $CollisionOak.disabled = true
    
    var sprite_string = ""
    
    # Get the appropriate light level for our animation
    match new_light_level:
        LIGHT_LEVEL.light:
            sprite_string = "_light"
        LIGHT_LEVEL.dark:
            sprite_string = "_dark"
    
    # Set the collision status and get
    match new_tree_type:
        TREE_TYPE.elm:
            $CollisionElm.disabled = false
            sprite_string = "elm" + sprite_string
        TREE_TYPE.pine:
            $CollisionPine.disabled = false
            sprite_string = "pine" + sprite_string
        TREE_TYPE.oak:
            $CollisionOak.disabled = false
            sprite_string = "oak" + sprite_string
    
    $Sprite.animation = sprite_string
