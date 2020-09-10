# Set this as a tool so that we see the trees change in the editor
tool
extends StaticBody

# What type of tree is this?
enum TREE_TYPE {
    elm, pine, oak
}

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export(TREE_TYPE) var _tree_type = TREE_TYPE.elm setget set_tree_type

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
    
    var sprite_string = ""
    
    # Set the collision status and get
    match _tree_type:
        TREE_TYPE.elm:
            $CollisionElm.disabled = false
            $CollisionElm.visible = true
            sprite_string = "elm"
        TREE_TYPE.pine:
            $CollisionPine.disabled = false
            $CollisionPine.visible = true
            sprite_string = "pine"
            
    $Sprite.animation = sprite_string

func set_tree_type(new_tree_type):
    _tree_type = new_tree_type
    _tree_refresh()
