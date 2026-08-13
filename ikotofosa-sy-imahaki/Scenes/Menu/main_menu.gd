extends Control

const MAP_SCENE_PATH = "res://Scenes/Game/map_scene.tscn"
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file(MAP_SCENE_PATH)

func _on_button_3_pressed() -> void:
	get_tree().quit()
