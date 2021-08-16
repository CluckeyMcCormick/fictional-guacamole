tool
extends Spatial

# We preload all of the font-textures that we'll need
const mono6x10_black = preload("res://special_effects/text_spritesheets/6x10mono_95char.png")
const mono6x10_transparent = preload("res://special_effects/text_spritesheets/6x10mono_95char_transparent.png")
const mono6x11_debug = preload("res://special_effects/text_spritesheets/6x11mono_debug_95char.png")

# The constants control various aspects of our Sprite3D nodes we spawn. We do
# this to help ensure consistency.
# What's the pixel_size for each sprite? We make this constant because we'd
# prefer the Scale controls/transform are used instead.
const PIXEL_SIZE = .01
# How many frames are in our font texture, horizontally? We us 95 character font
# textures, hence 95.
const HFRAMES = 95
# How many frames are in our font texture, vertically? There's only one row, so
# it's just 1
const VFRAMES = 1

# This enum allows us to easily choose the font we want and configure around
# that particular font.
enum FontChoices {MONO6x10_BLACK, MONO6x10_TRANSPARENT, MONO6x11_DEBUG}

# This dictionary translates a character into an index in one of our 95
# character font sheets.
const char95_dictionary = {
    "!":0, "\"":1, "#":2, "$":3, "%":4,
    "&":5, "'":6, "(":7, ")":8, "*":9,
    
    "+":10, ",":11, "-":12, ".":13, "/":14,
    "0":15, "1":16, "2":17, "3":18, "4":19,
    
    "5":20, "6":21, "7":22, "8":23, "9":24,
    ":":25, ";":26, "<":27, "=":28, ">":29,
    
    "?":30, "@":31, "A":32, "B":33, "C":34,
    "D":35, "E":36, "F":37, "G":38, "H":39,
    
    "I":40, "J":41, "K":42, "L":43, "M":44,
    "N":45, "O":46, "P":47, "Q":48, "R":49,
    
    "S":50, "T":51, "U":52, "V":53, "W":54,
    "X":55, "Y":56, "Z":57, "[":58, "\\":59,
    
    "]":60, "^":61, "_":62, "`":63, "a":64,
    "b":65, "c":66, "d":67, "e":68, "f":69,
    
    "g":70, "h":71, "i":72, "j":73, "k":74,
    "l":75, "m":76, "n":77, "o":78, "p":79,
    
    "q":80, "r":81, "s":82, "t":83, "u":84,
    "v":85, "w":86, "x":87, "y":88, "z":89,
    
    "{":90, "|":91, "}":92, "~":93, " ":94
}

# What value are we trying to display?
export(String, MULTILINE) var display_string setget set_display_string
# What font are we using?
export(FontChoices) var font_choice setget set_font_choice

# These variables track different value used to space out characters
# appropriately for each font.
# What font texture are we using?
var font_texture = null
# How long is each character/cell in the current font set, in pixels?
var space_x = 6
# How tall is each character/cell in the current font set, in pixels?
var space_y = 10

# Called when the node enters the scene tree for the first time.
func _ready():
    update_display_string()

# This function asserts the correct values for our font variables (see above).
func assert_font():
    match font_choice:
        FontChoices.MONO6x10_BLACK:
            space_x = 6
            space_y = 10
            font_texture = mono6x10_black
            
        FontChoices.MONO6x10_TRANSPARENT:
            space_x = 6
            space_y = 10
            font_texture = mono6x10_transparent
            
        FontChoices.MONO6x11_DEBUG:
            space_x = 6
            space_y = 11
            font_texture = mono6x11_debug
            
        _:
            pass

func update_display_string():
    # First, ensure our variables are correct by asserting the font.
    assert_font()
    
    # Next, remove all of the Sprite3D children from the ChildManager node. This
    # ensures we get rid of all the characters that were floating around
    for child in self.get_children():
        # If this child isn't a sprite 3D, skip it
        if not child is Sprite3D:
            continue
        # Otherwise, it must be a Sprite3D. DESTROY IT!
        self.remove_child(child)
        child.queue_free()
    
    # We build the lines from the "upper-left", working our way down. These
    # variables are used to construct our "base" vector.
    var initial_x = 0
    var initial_y = 0
    
    # Now, split the string into lines, ignoring any empty lines
    var display_lines = display_string.split("\n", false)
    
    # We need to calculate our initial y starting place. First, let's
    # calculate the total size on y for the tex block
    initial_y = len(display_lines) * space_y * PIXEL_SIZE
    # Now divide it in half
    initial_y /= 2
    # Now shift it down by half of one character, since our sprites are centered
    initial_y -= (space_y * PIXEL_SIZE) / 2
     
    # Calculate the base position for where we start building out our lines.
    var base_pos = Vector3(0, initial_y, 0)
    
    for line in display_lines:
        # We set the initial x for each line, so we'll do what we did for y.
        # First, let's calculate the total size on x for this line
        initial_x = -len(line) * space_x * PIXEL_SIZE
        # Now divide it in half
        initial_x /= 2
        # Now shift it up by half of one character, since our sprites are centered
        initial_x += (space_x * PIXEL_SIZE) / 2
        
        # Now, set the value in our base vector
        base_pos.x = initial_x
        
        for i in len(line):
            # Make a new sprite
            var new_sprite = Sprite3D.new()
            
            # Stick it in the scene
            self.add_child(new_sprite)
            
            # Set the new sprite's texture to our font texture
            new_sprite.texture = font_texture
            
            # Make sure it's in the right place
            new_sprite.translation = base_pos
            new_sprite.translation += Vector3(space_x * PIXEL_SIZE, 0, 0) * i
            
            # Set our constant values
            new_sprite.hframes = HFRAMES
            new_sprite.vframes = VFRAMES
            new_sprite.pixel_size = PIXEL_SIZE
            
            # Set our frame using the current character
            new_sprite.frame = char95_dictionary[line[i]]
            # All done with this character, onto the next
        
        # Go down by one line
        base_pos -= Vector3(0, space_y * PIXEL_SIZE, 0)
    # All done!

func set_display_string(new_string):
    display_string = new_string
    update_display_string()

func set_font_choice(new_font):
    font_choice = new_font
    update_display_string()
