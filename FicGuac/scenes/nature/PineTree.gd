# Set this as a tool so that we see the trees change in the editor
tool
extends StaticBody

# What type of tree is this?
enum TREE_TYPE {
    pine_a, pine_b, pine_c
}

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export(TREE_TYPE) var _tree_type = TREE_TYPE.pine_a setget set_tree_type

# Called when the node enters the scene tree for the first time.
func _ready():
    # Immediately set the tree type using our preset tree type and light level
    _tree_refresh()

func _tree_refresh():
    var sprite_string = ""
    
    # Set the collision status and get
    match _tree_type:
        TREE_TYPE.pine_a:
            sprite_string = "pine_fc_a"
        TREE_TYPE.pine_b:
            sprite_string = "pine_fc_b"
        TREE_TYPE.pine_c:
            sprite_string = "pine_fc_c"
            
    $Sprite.animation = sprite_string

func set_tree_type(new_tree_type):
    _tree_type = new_tree_type
    _tree_refresh()
