extends Node


# ============================================================
# AUDIO MANAGER
# ============================================================
#
# Gère :
#
# - musique du menu
# - musique du jeu
# - son hover bouton
# - son clic bouton
#
# À ajouter en Autoload.
#
# ============================================================


# ============================================================
# MUSIQUES
# ============================================================

const MENU_MUSIC := preload(
	"res://assets/Audio/Music/menu_music.mp3"
)

const GAME_MUSIC := preload(
	"res://assets/Audio/Music/game_music.mp3"
)


# ============================================================
# SONS INTERFACE
# ============================================================

const BUTTON_HOVER_SOUND := preload(
	"res://assets/Audio/UI/button_hover.mp3"
)

const BUTTON_CLICK_SOUND := preload(
	"res://assets/Audio/UI/button_click.mp3"
)


# ============================================================
# PLAYERS
# ============================================================

var music_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer


# ============================================================
# INITIALISATION
# ============================================================

func _ready() -> void:

	# ========================================================
	# PLAYER MUSIQUE
	# ========================================================

	music_player = AudioStreamPlayer.new()

	music_player.name = "MusicPlayer"

	music_player.bus = "Music"

	add_child(
		music_player
	)


	# ========================================================
	# PLAYER INTERFACE
	# ========================================================

	ui_player = AudioStreamPlayer.new()

	ui_player.name = "UIPlayer"

	ui_player.bus = "UI"

	add_child(
		ui_player
	)


# ============================================================
# MUSIQUE MENU
# ============================================================

func play_menu_music() -> void:

	if music_player == null:
		return

	if music_player.stream == MENU_MUSIC:
		if music_player.playing:
			return

	music_player.stream = MENU_MUSIC

	music_player.play()


# ============================================================
# MUSIQUE JEU
# ============================================================

func play_game_music() -> void:

	if music_player == null:
		return

	if music_player.stream == GAME_MUSIC:
		if music_player.playing:
			return

	music_player.stream = GAME_MUSIC

	music_player.play()


# ============================================================
# ARRÊTER LA MUSIQUE
# ============================================================

func stop_music() -> void:

	if music_player == null:
		return

	music_player.stop()


# ============================================================
# SON HOVER
# ============================================================

func play_button_hover() -> void:

	if ui_player == null:
		return

	ui_player.stream = BUTTON_HOVER_SOUND

	ui_player.play()


# ============================================================
# SON CLIC
# ============================================================

func play_button_click() -> void:

	if ui_player == null:
		return

	ui_player.stream = BUTTON_CLICK_SOUND

	ui_player.play()


# ============================================================
# CONFIGURER UN BOUTON
# ============================================================
#
# Cette fonction permet de connecter automatiquement :
#
# - mouse_entered -> hover
# - pressed -> clic
#
# ============================================================

func setup_button(
	button: Button
) -> void:

	if button == null:
		return


	# ========================================================
	# HOVER
	# ========================================================

	if not button.mouse_entered.is_connected(
		_on_button_hover
	):

		button.mouse_entered.connect(
			_on_button_hover
	)


	# ========================================================
	# CLIC
	# ========================================================

	if not button.pressed.is_connected(
		_on_button_pressed
	):

		button.pressed.connect(
			_on_button_pressed
	)


# ============================================================
# SIGNAL HOVER
# ============================================================

func _on_button_hover() -> void:

	play_button_hover()


# ============================================================
# SIGNAL CLIC
# ============================================================

func _on_button_pressed() -> void:

	play_button_click()
