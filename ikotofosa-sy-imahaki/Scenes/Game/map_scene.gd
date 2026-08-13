extends Node

# ============================================================
# RÉFÉRENCES — noms uniques (%) définis dans la scène
# ============================================================
@onready var map_container: Node2D = %MapContainer
@onready var info_label: Label = %Label
@onready var load_button: Button = %Charger
@onready var quit_button: Button = %Quitter
@onready var file_dialog: FileDialog = %OpenFileDialog

const TILE_SIZE: int = 32

# Bordure "zone non explorée" tout autour de la carte jouable
const BORDER_SIZE: int = 1
const BORDER_COLOR := Color(0.02, 0.02, 0.02)

# --- Couche 1 : le sol, toujours opaque, dessiné en dessous de tout ---
const FLOOR_TEXTURE := preload("res://assets/sprites/sol_vide.png")

# --- Couche 2 : les objets posés sur le sol (transparence autour = normal) ---
const OBJECT_SPRITES := {
	"#": preload("res://assets/sprites/rocher.png"),
	"t": preload("res://assets/sprites/arbre.png"),
	"o": preload("res://assets/sprites/trou.png"),
	"*": preload("res://assets/sprites/coffre.png"),
	"+": preload("res://assets/sprites/gemme.png"),
	"@": preload("res://assets/sprites/bush.png"),
	"F": preload("res://assets/sprites/perso_f.png"),
	"M": preload("res://assets/sprites/perso_m.png"),
	"X": preload("res://assets/sprites/excavatrice.png"),
	"G": preload("res://assets/sprites/grappler.png"),
	# "." n'est pas ici : c'est le sol lui-même, pas un objet posé dessus
}

const DEFAULT_MAP_PATH := "res://data/maps/sample_map.txt"

var map_width: int = 0
var map_height: int = 0
var level_time: int = 0


func _ready() -> void:
	load_button.pressed.connect(_on_load_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter("*.txt", "Fichiers Carte (*.txt)")
	file_dialog.file_selected.connect(generate_map_from_file)

	generate_map_from_file(DEFAULT_MAP_PATH)


func _on_load_button_pressed() -> void:
	file_dialog.popup_centered(Vector2i(650, 450))


func _on_quit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menu/MainMenu.tscn")


# ============================================================
# CHARGEMENT + PARSING DU FICHIER
# ============================================================
func generate_map_from_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		info_label.text = "Fichier introuvable : " + path
		return

	# Vider la carte précédente (sol, objets, bordure)
	for child in map_container.get_children():
		child.queue_free()

	var file := FileAccess.open(path, FileAccess.READ)

	# --- Ligne 1 : H W time_limit ---
	var header_line := file.get_line().strip_edges()
	var header_values: Array = []
	for part in header_line.split(" ", false):
		if part.is_valid_int():
			header_values.append(part.to_int())

	if header_values.size() < 3:
		info_label.text = "⚠️ En-tête invalide (attendu: H W temps)"
		file.close()
		return

	map_height = header_values[0]
	map_width = header_values[1]
	level_time = header_values[2]
	info_label.text = "Carte %dx%d | Temps: %ds" % [map_width, map_height, level_time]

	# --- Lecture de la grille ---
	var grid: Array = []
	var y := 0
	while not file.eof_reached() and y < map_height:
		var line := file.get_line()
		var row: Array = []
		for x in range(map_width):
			row.append(line[x] if x < line.length() else ".")
		grid.append(row)
		y += 1

	file.close()

	# --- Rendu : bordure, puis sol, puis objets ---
	draw_border()
	draw_floor_and_objects(grid)
	center_map()


# ============================================================
# RENDU
# ============================================================

## Dessine la bordure noire tout autour de la zone jouable.
func draw_border() -> void:
	var total_width := map_width + BORDER_SIZE * 2
	var total_height := map_height + BORDER_SIZE * 2

	for y in range(total_height):
		for x in range(total_width):
			var is_inside_map: bool = (
				x >= BORDER_SIZE and x < BORDER_SIZE + map_width
				and y >= BORDER_SIZE and y < BORDER_SIZE + map_height
			)
			if is_inside_map:
				continue

			var border_tile := ColorRect.new()
			border_tile.size = Vector2(TILE_SIZE, TILE_SIZE)
			border_tile.color = BORDER_COLOR
			border_tile.position = Vector2(
				(x - BORDER_SIZE) * TILE_SIZE,
				(y - BORDER_SIZE) * TILE_SIZE
			)
			map_container.add_child(border_tile)


## Dessine le sol (opaque) puis les objets par-dessus, case par case.
func draw_floor_and_objects(grid: Array) -> void:
	for y in range(map_height):
		for x in range(map_width):
			var symbol: String = grid[y][x]
			var pos := Vector2(x * TILE_SIZE, y * TILE_SIZE)

			# Couche 1 : le sol, toujours présent, toujours en dessous
			var floor_sprite := Sprite2D.new()
			floor_sprite.texture = FLOOR_TEXTURE
			floor_sprite.centered = false
			floor_sprite.position = pos
			floor_sprite.z_index = 0
			map_container.add_child(floor_sprite)

			# Couche 2 : l'objet posé dessus, s'il y en a un
			if OBJECT_SPRITES.has(symbol):
				var object_sprite := Sprite2D.new()
				object_sprite.texture = OBJECT_SPRITES[symbol]
				object_sprite.centered = false
				object_sprite.position = pos
				object_sprite.z_index = 1
				map_container.add_child(object_sprite)


## Centre le conteneur (carte + bordure) au milieu de l'écran.
func center_map() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var total_pixel_size := Vector2(
		(map_width + BORDER_SIZE * 2) * TILE_SIZE,
		(map_height + BORDER_SIZE * 2) * TILE_SIZE
	)
	map_container.position = (viewport_size - total_pixel_size) / 2
