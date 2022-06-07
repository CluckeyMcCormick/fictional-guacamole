extends Spatial

# Preload the Scalable Particle Emitter (SPE)
const SPE = preload("res://special_effects/particles/ScalableParticleEmitter.tscn")

# Our global manifest node that holds all of the tests paths in a dictionary.
onready var MANIFEST = get_node("/root/Manifest")

const START_VALUE = -3.5
const END_VALUE = 4
const INCREMENT = 1

const SPIN_TIME = 30

# Our current position for placing particle effects
var x = START_VALUE
var y = 0.5
var z = START_VALUE

var particle_list = []
var particle_index = 0
var scale_vector = Vector3.ZERO

var spe_particles = 0
var spe_systems = 0
var prebuilt_systems = 0

# Called when the node enters the scene tree for the first time.
func _ready():
    # We need to update the Item List using our particle blueprints
    for mat_name in MANIFEST.PARTICLE_BLUEPRINTS.keys():
        $GUI/ItemList.add_item(mat_name)
    # We also need to update the Item List using our prebuilt particle scenes 
    for mat_name in MANIFEST.PARTICLE_SCENES.keys():
        $GUI/ItemList.add_item(mat_name)

func _on_Go_pressed():
    var selected
    var scalar
    var temp
    
    spe_particles = 0
    spe_systems = 0
    prebuilt_systems = 0
    
    particle_list = []
    
    x = START_VALUE
    y = 0.5
    z = START_VALUE
    
    selected = $GUI/ItemList.get_selected_items()
    if selected.empty():
        print("Nothing selected!")
        return
    
    scalar = Vector3(
        float($GUI/Scale/X.text),
        float($GUI/Scale/Y.text), 
        float($GUI/Scale/Z.text)
    )
    
    if scalar == Vector3.ZERO:
        print("Invalid scale vector: ", scalar)
        return
    
    scale_vector = scalar
    for index in selected:
        temp = $GUI/ItemList.get_item_text(index)
        if temp in MANIFEST.PARTICLE_BLUEPRINTS:
            particle_list.append( load(MANIFEST.PARTICLE_BLUEPRINTS[temp]) )
        elif temp in MANIFEST.PARTICLE_SCENES:
            particle_list.append( load(MANIFEST.PARTICLE_SCENES[temp]) )
    
    particle_index = 0
    
    $GUI/Controls/Go.disabled = true
    $GUI/Controls/Stop.disabled = false
    
    $Timer.start()

func _on_Timer_timeout():
    var new_node
    
    if particle_list[particle_index] is ScalableParticleBlueprint:
        new_node = SPE.instance()
        $MeshInstance/ParticleMount.add_child(new_node)
        new_node.translation = Vector3(x, y, z)
        
        new_node.set_blueprint(particle_list[particle_index])
        new_node.scale_emitter(scale_vector)
        # Just for this test, we ignore "one shot" particle materials.
        new_node.one_shot = false
        
        spe_particles += new_node.amount
        spe_systems += 1
        $GUI/Stats/ParticleCount.text = str(spe_particles)
        $GUI/Stats/SystemsCount.text = str(spe_systems)
        $GUI/Stats/ParticleAverage.text = str(
            float(spe_particles) / float(spe_systems)
        )
    else:
        new_node = particle_list[particle_index].instance()
        $MeshInstance/ParticleMount.add_child(new_node)
        new_node.translation = Vector3(x, y, z)
        
        # Increment the count of prebuilt systems and update the GUI
        prebuilt_systems += 1
        $GUI/Stats/PrebuiltCount.text = str(prebuilt_systems)
    
    x += INCREMENT
    
    particle_index = (particle_index + 1) % len(particle_list)
    
    if x > END_VALUE:
        x = START_VALUE
        z += INCREMENT
        
    if z > END_VALUE:
        $Timer.stop()
        _on_Tween_tween_completed(null, ":translation:x")

func _on_Tween_tween_completed(object, key):
    #print(object, "|<-->|", str(key))
    
    # Clean all the tweens
    $Tween.remove_all()
    
    # Reset the platform
    $MeshInstance.translation = Vector3(0, -1, 0)

    # Now we need to do different TWEENS based on the tween we just completed.
    match str(key):
        ":translation:x":
            $Tween.interpolate_property(
                $MeshInstance, "translation:z", -25, 25, SPIN_TIME
            )
        ":translation:z":
            $Tween.interpolate_property(
                $MeshInstance, "rotation_degrees:y", 0, 360, SPIN_TIME
            )
        ":rotation_degrees:y":
            $Tween.interpolate_property(
                $MeshInstance, "translation:x", -25, 25, SPIN_TIME
            )
        _:
            print("Bad +-> ", str(key))
    $Tween.start()

func _on_Stop_pressed():
    $Timer.stop()
    $Tween.stop_all()
    $Tween.remove_all()
    
    # Reset the platform
    $MeshInstance.translation = Vector3(0, -1, 0)
    $MeshInstance.rotation_degrees = Vector3.ZERO
    
    # Remove the particle effects
    for particle in $MeshInstance/ParticleMount.get_children():
        $MeshInstance/ParticleMount.remove_child(particle)

    # Reset the stats
    spe_particles = 0
    spe_systems = 0
    prebuilt_systems = 0
    
    $GUI/Stats/ParticleCount.text = str(spe_particles)
    $GUI/Stats/SystemsCount.text = str(spe_systems)
    $GUI/Stats/ParticleAverage.text = str(0)
    $GUI/Stats/PrebuiltCount.text = str(prebuilt_systems)
    
    $GUI/Controls/Go.disabled = false
    $GUI/Controls/Stop.disabled = true
