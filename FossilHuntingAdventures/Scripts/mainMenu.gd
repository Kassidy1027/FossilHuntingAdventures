extends Control

# Will Launch the First Level of the Game
func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/level_1.tscn")
	
	

func _on_objectives_pressed() -> void:
	$Objectives.visible = not $Objectives.visible


# Will Exit the Game
func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_button_pressed() -> void:
	$Objectives.visible = not $Objectives.visible
