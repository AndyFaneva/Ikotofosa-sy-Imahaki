extends Control


# ============================================================
# SCÈNE DU JEU
# ============================================================

const MAP_SCENE_PATH := (
	"res://Scenes/Game/map_scene.tscn"
)


# ============================================================
# BOUTONS
# ============================================================

@onready var play_button: Button = $Jouer

@onready var quit_button: Button = $Quitter


# ============================================================
# INITIALISATION
# ============================================================

#func _ready() -> void:

	# ========================================================
	# MUSIQUE DU MENU
	# ========================================================

#	AudioManager.play_menu_music()


	# ========================================================
	# SONS DES BOUTONS
	# ========================================================

#	AudioManager.setup_button(
#		play_button
#	)

#	AudioManager.setup_button(
#		quit_button
#	)


# ============================================================
# BOUTON JOUER
# ============================================================

func _on_button_pressed() -> void:

	AudioManager.play_button_click()
	
	get_tree().change_scene_to_file(
		MAP_SCENE_PATH
	)


# ============================================================
# BOUTON QUITTER
# ============================================================

func _on_button_3_pressed() -> void:

	AudioManager.play_button_click()
	
	get_tree().quit()


func _on_jouer_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/cutscene/cutscene.tscn")


func _on_quitter_pressed() -> void:
	get_tree().quit()


func _on_charger_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Game/map_scene.tscn")
