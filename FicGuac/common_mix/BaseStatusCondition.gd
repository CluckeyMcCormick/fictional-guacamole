extends Node

# Each status condition has any number of modifiers, each of which behave in a
# different way. The modifiers are described as arrays/lists, where each element
# is a different value. These Modifier Field Indicies (MFIs) are the indicies to
# access those different values.
# The target field is the string name of the field we're targeting. Using a
# string allows us to dynamically apply the modifiers.
const MFI_TARGET = 0
# The operation field determines what kind of operation we're performing with
# the modifier. Check the StatOp enum for more.
const MFI_OP = 1
# The modifier field is the actual modifying value. This should be an int or a
# float of some sort.
const MFI_MODI = 2

# This enum defines the different types of stat operations that each
# modification can do. That way, we know how to modify the stats in question.
enum StatOp {
    # This is just a flat modification: +10, -7, etc.
    FLAT_MOD,
    # This adds a scaled version of the base value back as a modification - i.e
    # 1.5 or -0.7 or 200.
    ADD_SCALE_MOD
}

# The modifiers for this status condition. This is a series of arrays where the
# indicies correspond to the MOD_FIELD index constants above. Since this is the
# base, it goes blank.
var modifiers = []

# How long does this status effect last for? <= 0 means never-ending. Note that
# this doesn't mean the status effect can't be reversed by other means, just
# that it doesn't naturally go away.
export(int) var lifetime = -1

# We also support damage over time for our different status effects.
# How much damage is inflicted at the DOT interval?
export(int) var dot_damage = 0
# How frequently do we deal damage via our damage over time? <= 0 means no DOT
export(int) var dot_interval = -1

# What's the icon we use to represent this status effect?
export(Texture) var icon

