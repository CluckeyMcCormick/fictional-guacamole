# Set this as a tool so that we see the trees change in the editor
tool
extends StaticBody

# What type of tree is this?
enum TREE_TYPE {
    elm, pine, oak
}

# What's the light level of this tree?
enum LIGHT_LEVEL {
    light, dark
}

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export(TREE_TYPE) var _tree_type = TREE_TYPE.elm setget set_tree_type
export(LIGHT_LEVEL) var _light_level = LIGHT_LEVEL.light setget set_light_level

# Called when the node enters the scene tree for the first time.
func _ready():
    # Immediately set the tree type using our preset tree type and light level
    _tree_refresh()

func _tree_refresh():
    # Disable and hide all the collision models - we'll give ourselves a clean
    # slate.
    # ELM
    $CollisionElm.disabled = true
    $CollisionElm.visible = false
    # PINE
    $CollisionPine.disabled = true
    $CollisionPine.visible = false
    # OAK
    $CollisionOak.disabled = true
    $CollisionOak.visible = false
    
    var sprite_string = ""
    
    # Get the appropriate light level for our animation
    match _light_level:
        LIGHT_LEVEL.light:
            sprite_string = "_light"
        LIGHT_LEVEL.dark:
            sprite_string = "_dark"
    
    # Set the collision status and get
    match _tree_type:
        TREE_TYPE.elm:
            $CollisionElm.disabled = false
            $CollisionElm.visible = true
            sprite_string = "elm" + sprite_string
        TREE_TYPE.pine:
            $CollisionPine.disabled = false
            $CollisionPine.visible = true
            sprite_string = "pine" + sprite_string
        TREE_TYPE.oak:
            $CollisionOak.disabled = false
            $CollisionOak.visible = true
            sprite_string = "oak" + sprite_string
    
    $Sprite.animation = sprite_string

func set_tree_type(new_tree_type):
    _tree_type = new_tree_type
    _tree_refresh()

func set_light_level(new_light_level):
    _light_level = new_light_level
    _tree_refresh()
