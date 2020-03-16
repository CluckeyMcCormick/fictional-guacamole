extends Node2D

# The default faction name
const DEFAULT_TEAM_NAME = "FACTION NAME UNINITIALIZED"

# Factions that are hostile with this faction
var hostile = {}

# Factions that are friendly with this faction
var friendly = {}

# The faction's team name. Ideally, this should be both human-readable and
# unique - it basically serves as the factions UUID.
var team_name = DEFAULT_TEAM_NAME

# Make the given faction hostile - not a mutual action
func make_hostile(faction):
    friendly.erase(faction.team_name)
    hostile[faction.team_name] = faction

# Check if the given faction is hostile
func is_hostile(faction):
    return hostile.has(faction.team_name)
    
# Make the given faction neutral - not a mutual action 
func make_neutral(faction):
    friendly.erase(faction.team_name)
    hostile.erase(faction.team_name)
    
# Check if the given faction is neutral
func is_neutral(faction):
    return hostile.has(faction.team_name)

# Make the given faction friendly - not a mutual action 
func make_friendly(faction):
    hostile.erase(faction.team_name)
    friendly[faction.team_name] = faction

# Check if the given faction is friendly
func is_friendly(faction):
    return hostile.has(faction.team_name) or self == faction