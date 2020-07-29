# Set this as a tool so that we see the trees change in the editor
tool
extends StaticBody

# How big is this rock?
enum ROCK_SIZE {
    small, medium, large
}

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export(ROCK_SIZE) var _rock_size = ROCK_SIZE.medium setget set_rock_size

# Called when the node enters the scene tree for the first time.
func _ready():
    # Immediately set the tree type using our preset tree type and light level
    _rock_refresh()

func _rock_refresh():
    # Disable and hide all the collision models - we'll give ourselves a clean
    # slate.
    # Small
    $CollisionSmall.disabled = true
    $CollisionSmall.visible = false
    # Medium
    $CollisionMedium.disabled = true
    $CollisionMedium.visible = false
    # Large
    $CollisionLarge.disabled = true
    $CollisionLarge.visible = false
    
    
    # Set the collision status and get
    match _rock_size:
        ROCK_SIZE.small:
            $CollisionSmall.disabled = false
            $CollisionSmall.visible = true
        ROCK_SIZE.medium:
            $CollisionMedium.disabled = false
            $CollisionMedium.visible = true
        ROCK_SIZE.large:
            $CollisionLarge.disabled = false
            $CollisionLarge.visible = true

func set_rock_size(new_rock_size):
    _rock_size = new_rock_size
    _rock_refresh()
