extends TileMap


#---------------------#
#  PUBLIC VARIABLES   #
#---------------------#

# Setting the tilemap layer that the player can dig from 
@export var dig_layer: int = 5

# Different tilesource layers the player can dig on 
@export var diggable_layer_ids: Array[int] = [1,0]   # IDs of tiles that can be dug

# Variables needed for Replacement tile
@export var replacement_tile_source: int = 1          
@export var replacement_tile_coords: Vector2i = Vector2i(50, 17)   

# Variables for the Fossil Tile
@export var fossil_tile_source: int = 0
@export var fossil_tile_coords: Vector2i = Vector2i(0,0)

# Array to Hold the Fossil Locations
var fossil_locations : Array = []

# Fossil Manager Reference 
@onready var fossil_manager = FossilManager


#---------------#
#  READY FUNC   #
#---------------#
func _ready():
	# Load fossil positions for the current level
	fossil_manager.load_fossil_locations(1)
	fossil_locations = fossil_manager.fossil_locations
	print("Loaded fossil positions:", fossil_locations)


#---------------#
#  INPUT FUNC   #
#---------------#
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		dig_tile()


#---------------#
#   DIG FUNC    #
#---------------#
func dig_tile():
	var mouse_pos = get_global_mouse_position()
	var map_coords = local_to_map(to_local(mouse_pos))
	
	# Debugging
	print("Clicked TileMap cell:", map_coords)

	var tile_id = get_cell_source_id(dig_layer, map_coords)
	if tile_id == -1 or tile_id not in diggable_layer_ids:
		print("No diggable tile here")
		return

	# Check for fossils
	var fossil_index = get_fossil_index(map_coords)
	if fossil_index != -1:
		print("FOSSIL FOUND at:", map_coords)
		_dig_fossil_tile(map_coords, fossil_index)
	else:
		_dig_normal_tile(map_coords)


#-----------------------#
#  FOSSIL SEARCH FUNC   #
#-----------------------#
# Returns the index of the fossil in the fossil_locations array or -1
func get_fossil_index(tile_pos: Vector2i) -> int:
	for i in range(fossil_locations.size()):
		var f_pos = fossil_locations[i]["pos"]
		if f_pos.x == tile_pos.x and f_pos.y == tile_pos.y:
			return i
	return -1
	
# Function when a Fossil is Found
func _dig_fossil_tile(map_coords: Vector2i, fossil_index: int):
	set_cell(dig_layer, map_coords, fossil_tile_source, fossil_tile_coords)
	
	# Removing Fossils From Array
	fossil_locations.remove_at(fossil_index)
	
	# Debugging / Fossil Verification
	print("Fossil dug! Remaining fossils:", fossil_locations.size())
	
	# TODO: Fossil Found Verification Ex. Popup Menu

# Function when a NO Fossil is Found
func _dig_normal_tile(map_coords: Vector2i):
	set_cell(dig_layer, map_coords, replacement_tile_source, replacement_tile_coords)
	
	# Debugging
	print("Normal dig at:", map_coords)
