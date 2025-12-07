extends Control



func _on_start_pressed() -> void:
	print("Start Pressed")
	get_tree().change_scene_to_file("res://world.tscn")

func _on_exit_pressed() -> void:
	print("Exit Pressed")
	get_tree().quit()
