extends Node

var db: SQLite

#---------------#
#   DB FILES    #
#---------------#
const TEMP_DB := "res://Database/template.db"
const USER_DB := "user://data.db"

#---------------#
#   DB TABLES   #
#---------------#
var fossilTable := {
	"fossilID": {"data_type":"int", "primary_key":true, "not_null":true, "auto_increment":true},
	"fossilName": {"data_type":"text", "not_null":true, "unique":true},
	"fossilRarity": {"data_type":"text", "not_null":true}
}

var levelTable := {
	"levelID": {"data_type":"int", "primary_key":true, "not_null":true, "auto_increment":true},
	"levelName": {"data_type":"text", "not_null":true, "unique":true},
	"levelFossilCount": {"data_type":"int", "not_null":true}
}

# Holds fossil positions for each level
var fossil_locations: Array = []

#---------------#
#  READY FUNC   #
#---------------#
func _ready():
	# Functions to Initalize the Database
	ensure_db_exists()
	open_db()
	create_tables()
	insert_data()
	
	load_fossil_locations(1)  

	# Debugging
	# print("FossilManager initialized successfully!")
	# print(db.select_rows("Levels", "levelID = 1", ["*"]))
	# print(db.select_rows("Fossils", "fossilID = 1", ["*"]))
	# print(db.select_rows("LevelFossils", "levelFossilsID = 1", ["*"]))



#---------------#
#    DB FUNCS   #
#---------------#
func ensure_db_exists():
	if not FileAccess.file_exists(USER_DB):
		# Debugging
		# print("Database missing → Copying template...")
		
		# Copying Database
		var bytes := FileAccess.get_file_as_bytes(TEMP_DB)
		var w := FileAccess.open(USER_DB, FileAccess.WRITE)
		w.store_buffer(bytes)
		w.close()
		
		# Debugging
		# print("Template database copied.")


# Opens SQLite and turns on foreign keys
func open_db():
	# Opening the Database
	db = SQLite.new()
	db.path = USER_DB
	db.open_db()

	# Turning on Foreign Keys
	db.query("PRAGMA foreign_keys = ON;")
	
	# Debugging
	# print("Database opened: ", USER_DB)


# Function to Create the Tables in the Database 
func create_tables():
	db.create_table("Fossils", fossilTable)
	db.create_table("Levels", levelTable)
	
	# Dropping the Old Table to Create the New One for LevelFossils
	db.query("DROP TABLE IF EXISTS LevelFossils;")
	
	# Custom LevelFossils table with foreign keys
	var level_fossils_sql := """
	CREATE TABLE IF NOT EXISTS LevelFossils (
		levelFossilsID INTEGER PRIMARY KEY AUTOINCREMENT,
		levelID INTEGER NOT NULL,
		fossilID INTEGER NOT NULL,
		tileX INTEGER NOT NULL,
		tileY INTEGER NOT NULL,
		FOREIGN KEY(levelID) REFERENCES Levels(levelID) ON DELETE CASCADE ON UPDATE CASCADE,
		FOREIGN KEY(fossilID) REFERENCES Fossils(fossilID) ON DELETE CASCADE ON UPDATE CASCADE
	);
	"""

	if not db.query(level_fossils_sql):
		push_error("Failed to create LevelFossils: %s" % db.get_last_error_message())

	# Debugging
	# print("Tables created or validated.")


# Function to Insert the Data Into the Database 
func insert_data():
	# Insert Fossils into Database
	var fossil_rows = db.select_rows("Fossils", "", ["fossilID","fossilName"])
	var fossil_ids = {} # FossilName -> fossilID mapping

	# Fossil Data and Insertion
	if fossil_rows.size() == 0:
		var fossils_to_insert = [
			{"fossilName":"Amber","fossilRarity":"Common"},
			{"fossilName":"Trilobite","fossilRarity":"Uncommon"},
			{"fossilName":"Placoderms","fossilRarity":"Rare"},
			{"fossilName":"Dunkleosteus","fossilRarity":"Common"},
			{"fossilName":"Sand Dollar","fossilRarity":"Common"},
			{"fossilName":"Perfect Amber","fossilRarity":"Legendary"},
			{"fossilName":"Ammonite Mollusksr","fossilRarity":"Common"}
		]
		for f in fossils_to_insert:
			db.insert_row("Fossils", f)
		
		# Re-fetch fossils
		fossil_rows = db.select_rows("Fossils", "", ["fossilID","fossilName"])

	for row in fossil_rows:
		var name_key = ""
		for k in row.keys():
			if k.to_lower() == "fossilname":
				name_key = k
				break
		if name_key != "":
			fossil_ids[row[name_key].strip_edges()] = int(row["fossilID"])


	# Insert Levels Into Database
	var level_rows = db.select_rows("Levels", "", ["levelID","levelName"])
	var level_ids = {} # LevelName -> levelID mapping

	# Level Data and Insertion
	if level_rows.size() == 0:
		db.insert_row("Levels", {"levelName":"Tutorial","levelFossilCount":4})
		db.insert_row("Levels", {"levelName":"3-Island","levelFossilCount":5})
		# Re-fetch levels
		level_rows = db.select_rows("Levels", "", ["levelID","levelName"])

	for row in level_rows:
		var name_key = ""
		for k in row.keys():
			if k.to_lower() == "levelname":
				name_key = k
				break
		if name_key != "":
			level_ids[row[name_key].strip_edges()] = int(row["levelID"])


	# Insert LevelFossils Into Database
	var level_fossils_rows = db.select_rows("LevelFossils", "", ["levelFossilsID"])
	
	# Level 1 Fossil Locations
	if level_fossils_rows.size() == 0:
		var level_fossils_to_insert = [
			{"levelName":"Tutorial","fossilName":"Amber","tileX":4,"tileY":6},
			{"levelName":"Tutorial","fossilName":"Trilobite","tileX":2,"tileY":10},
			{"levelName":"Tutorial","fossilName":"Placoderms","tileX":19,"tileY":6},
			{"levelName":"Tutorial","fossilName":"Dunkleosteus","tileX":25,"tileY":8}
		]

		for lf in level_fossils_to_insert:
			var lvl_name = lf["levelName"].strip_edges()
			var f_name = lf["fossilName"].strip_edges()

			if not level_ids.has(lvl_name):
				push_error("Level name not found in database: %s" % lvl_name)
				continue
			if not fossil_ids.has(f_name):
				push_error("Fossil name not found in database: %s" % f_name)
				continue

			db.insert_row("LevelFossils", {
				"levelID": level_ids[lvl_name],
				"fossilID": fossil_ids[f_name],
				"tileX": lf["tileX"],
				"tileY": lf["tileY"]
			})
			
	# Debugging
	 # print("Default data ready.")
	

#--------------------------#
#    FOSSIL LOADING FUNC   #
#--------------------------#
func load_fossil_locations(level_id: int) -> void:
	# Clearing the Array
	fossil_locations.clear()
	
	# Going through and Inserting Fossil Locations
	var rows = db.select_rows("LevelFossils", "levelID=%d" % level_id, ["tileX","tileY","fossilID"])
	for row in rows:
		var pos = Vector2i(int(row["tileX"]), int(row["tileY"]))
		fossil_locations.append({"pos": pos, "fossilID": int(row["fossilID"])})
