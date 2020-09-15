# Set this as a tool so that we see the trees change in the editor
tool
extends Spatial

# What type of tree is this?
enum TREE_TYPE {
    pine_a, pine_b, pine_c
}

# Preload our selections for the (T)ree (M)aterials
const TM_PINE_A = preload("res://assets/nature/trees/mat_ztree01_fc_a.tres")
const TM_PINE_B = preload("res://assets/nature/trees/mat_ztree01_fc_b.tres")
const TM_PINE_C = preload("res://assets/nature/trees/mat_ztree01_fc_c.tres")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export(TREE_TYPE) var _tree_type = TREE_TYPE.pine_a setget set_tree_type

# Called when the node enters the scene tree for the first time.
func _ready():
    # Immediately set the tree type using our preset tree type and light level
    _tree_refresh()

func _tree_refresh():
    var material = null
    
    if not get_node("Mesh"):
        return
    
    match _tree_type:
        TREE_TYPE.pine_a:
            material = TM_PINE_A
        TREE_TYPE.pine_b:
            material = TM_PINE_B
        TREE_TYPE.pine_c:
            material = TM_PINE_C
    
    $Mesh.set_surface_material(0, material)

func set_tree_type(new_tree_type):
    _tree_type = new_tree_type
    _tree_refresh()

func _on_VisibilityNotifier_screen_entered():
    $Mesh.visible = true

func _on_VisibilityNotifier_screen_exited():
    $Mesh.visible = false
