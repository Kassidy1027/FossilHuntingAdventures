extends TileMap


#--------------#
#  VARIABLES   #
#--------------#

# Setting the tilemap layer that the player can dig from 
var dig_layer: int = 5

# Different tilesource layers the player can dig on 
var diggable_layer_ids: Array[int] = [1,0]   # IDs of tiles that can be dug

# Variables needed for Replacement tile
var replacement_tile_source: int = 1          
var replacement_tile_coords: Vector2i = Vector2i(50, 17)   

# Variables for the Fossil Tile
var fossil_tile_source: int = 0
var fossil_tile_coords: Vector2i = Vector2i(0,0)

# Array to Hold the Fossil Locations
var fossil_locations : Array = []

# Fossil Manager Reference 
@onready var fossil_manager = FossilManager

# Variables for Cooldown Functionality 
var can_dig: bool = true
var dig_cooldown_timer: float = 5.0

# Variables for Dig Range Limitation
@export var dig_range: float = 2.0
@export var player: Node2D


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
	
	# Checking Dig Cooldown Boolean
	if not can_dig:
		print("Dig is on Cooldown!")
		return

	# Getting Mouse Position for Digging
	var mouse_pos = get_global_mouse_position()
	var map_coords = local_to_map(to_local(mouse_pos))

	# Checking if the Player is Within Range
	if not in_range(map_coords):
		print("Tile too far away! Out of digging range.")
		return

	
	# Calling the Dig Cooldown Function 
	start_dig_cooldown()
	
	# Debugging
	# print("Clicked TileMap cell:", map_coords)

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


# Functionn for Digging Cooldown to Prevent Spam Digs
func start_dig_cooldown():
	can_dig = false
	
	# Setting a Timer to Pause Digging
	await get_tree().create_timer(dig_cooldown_timer).timeout
	can_dig = true
	
	# Debugging
	print("Dig Cooldown Ended. Proceed Digging. ")


func in_range(tile_coords: Vector2i) -> bool:
	# Convert tile coords to world position of the tile's center
	# Converting Tile Coords to a World Position in Relation to Center of Tile
	var tile_world_pos = map_to_local(tile_coords)
	var tile_global_world_pos = to_global(tile_world_pos)

	# Measuring the Distance from the Player
	var distance = player.global_position.distance_to(tile_global_world_pos)

	# Getting the Tile Size and Returning the Distance from the Player 
	var tile_size = tile_set.tile_size.x  
	return distance <= dig_range * tile_size
	
