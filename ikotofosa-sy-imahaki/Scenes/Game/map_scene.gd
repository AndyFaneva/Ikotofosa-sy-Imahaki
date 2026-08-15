extends Node


# ============================================================
# RÉFÉRENCES
# ============================================================

@onready var map_container: Node2D = %MapContainer
@onready var info_label: Label = %Label
@onready var load_button: Button = %Charger
@onready var quit_button: Button = %Quitter
@onready var file_dialog: FileDialog = %OpenFileDialog


# ============================================================
# GRILLE
# ============================================================

var grid: Array = []


# ============================================================
# CONFIGURATION
# ============================================================

var TILE_SIZE: int = 64

const BORDER_SIZE: int = 1

const BORDER_COLOR := Color(
	0.02,
	0.02,
	0.02
)

const DEFAULT_MAP_PATH := (
	"res://data/maps/612.txt"
)


# ============================================================
# TEXTURES
# ============================================================

const FLOOR_TEXTURE := preload(
	"res://assets/sprites/sol_vide.png"
)

const BORDER_TOP_TEXTURE := preload(
	"res://assets/sprites/sol_haut.png"
)

const BORDER_BOTTOM_TEXTURE := preload(
	"res://assets/sprites/sol_bas.png"
)

const HOLE_TEXTURE := preload(
	"res://assets/sprites/trou.png"
)

const CUT_TREE_TEXTURE := preload(
	"res://assets/sprites/arbrecoupe.png"
)


# ============================================================
# EXCAVATEUR
# ============================================================

const EXCAVATOR_SCENE := preload(
	"res://Scenes/Agents/Bot/Exclavator/excavator.tscn"
)


# ============================================================
# GRAPPLER
# ============================================================

const GRAPPLER_SCENE := preload(
	"res://Scenes/Agents/Bot/Grapleur/Grappleur.tscn"
)


# ============================================================
# AUTRES OBJETS
# ============================================================

const OBJECT_SPRITES := {

	"#": preload(
		"res://assets/sprites/rocher.png"
	),

	"t": preload(
		"res://assets/sprites/arbre.png"
	),

	"*": preload(
		"res://assets/sprites/coffre.png"
	),

	"+": preload(
		"res://assets/sprites/gemme.png"
	),

	"@": preload(
		"res://assets/sprites/bush.png"
	),

	"F": preload(
		"res://assets/sprites/perso_f.png"
	),

	"M": preload(
		"res://assets/sprites/perso_m.png"
	),

	"G": preload(
		"res://assets/sprites/grappler.png"
	)
}


# ============================================================
# INFORMATIONS CARTE
# ============================================================

var map_width: int = 0
var map_height: int = 0
var level_time: int = 0


# ============================================================
# MACHINES
# ============================================================

var excavators: Array[Node] = []

var grapplers: Array[Node] = []


# ============================================================
# INITIALISATION
# ============================================================

func _ready() -> void:

	#AudioManager.play_game_music()
	
	RenderingServer.set_default_clear_color(
		Color.BLACK
	)


	# ========================================================
	# BOUTON CHARGER
	# ========================================================

	load_button.pressed.connect(
		_on_load_button_pressed
	)


	# ========================================================
	# BOUTON QUITTER
	# ========================================================

	quit_button.pressed.connect(
		_on_quit_button_pressed
	)


	# ========================================================
	# FILE DIALOG
	# ========================================================

	file_dialog.file_mode = (
		FileDialog.FILE_MODE_OPEN_FILE
	)

	file_dialog.add_filter(
		"*.txt",
		"Fichiers Carte (*.txt)"
	)

	file_dialog.file_selected.connect(
		generate_map_from_file
	)


	# ========================================================
	# CHARGER LA CARTE
	# ========================================================

	generate_map_from_file(
		DEFAULT_MAP_PATH
	)


# ============================================================
# VÉRIFIER QU'UN NODE EST UNE MACHINE
# ============================================================

func is_machine(node: Node) -> bool:

	if not is_instance_valid(node):
		return false

	if excavators.has(node):
		return true

	if grapplers.has(node):
		return true

	return false


# ============================================================
# OBTENIR TOUTES LES MACHINES
# ============================================================

func get_all_machines() -> Array[Node]:

	var machines: Array[Node] = []

	# ========================================================
	# EXCAVATEURS
	# ========================================================

	for excavator in excavators:

		if not is_instance_valid(excavator):
			continue

		machines.append(excavator)


	# ========================================================
	# GRAPPLERS
	# ========================================================

	for grappler in grapplers:

		if not is_instance_valid(grappler):
			continue

		machines.append(grappler)


	return machines


# ============================================================
# VÉRIFIER SI UNE MACHINE OCCUPE UNE CELLULE
# ============================================================
#
# IMPORTANT :
#
# Une machine peut être :
#
# - sur sa position actuelle
#
# OU
#
# - en train d'aller vers une cellule cible.
#
# La cellule cible est donc considérée comme RÉSERVÉE.
#
# Cela empêche :
#
# G -> G
# X -> X
# G -> X
# X -> G
#
# de se retrouver dans la même cellule.
#
# ============================================================

func is_machine_occupying_cell(
	cell: Vector2i,
	ignored_machine: Node = null
) -> bool:

	var machines := get_all_machines()


	for machine in machines:

		if not is_instance_valid(machine):
			continue


		if machine == ignored_machine:
			continue


		if not "grid_position" in machine:
			continue


		# ====================================================
		# POSITION ACTUELLE
		# ====================================================

		if machine.grid_position == cell:

			return true


		# ====================================================
		# POSITION CIBLE
		# ====================================================
		#
		# Très important :
		#
		# si la machine est déjà en mouvement,
		# sa cible est réservée.
		#
		# ====================================================

		if "moving" in machine:

			if machine.moving:

				if "target_grid_position" in machine:

					if (
						machine.target_grid_position
						== cell
					):

						return true


	return false


# ============================================================
# COLLISION MACHINE
# ============================================================
#
# Retourne TRUE si la cellule appartient à :
#
# - un autre Excavateur
# - un autre Grappler
# - la cible réservée d'une autre machine
#
# ============================================================

func check_machine_collision(
	current_machine: Node,
	next_cell: Vector2i
) -> bool:

	return is_machine_occupying_cell(
		next_cell,
		current_machine
	)


# ============================================================
# CELLULE DANS LES LIMITES
# ============================================================

func is_cell_inside_map(
	cell: Vector2i
) -> bool:

	if cell.x < 0:
		return false

	if cell.x >= map_width:
		return false

	if cell.y < 0:
		return false

	if cell.y >= map_height:
		return false

	if cell.y >= grid.size():
		return false

	if cell.x >= grid[cell.y].size():
		return false

	return true


# ============================================================
# COLLISION D'UNE CASE
# ============================================================
#
# Les machines ne sont PAS stockées comme obstacles dans
# grid. Leur collision est gérée séparément.
#
# Les machines peuvent donc marcher sur :
#
# .  sol
# *  coffre
# +  gemme
# @  buisson
# o  trou
# t_coupe arbre coupé
#
# Les seuls obstacles naturels ici sont :
#
# #  rocher
# t  arbre
#
# ============================================================

func is_cell_free(
	cell: Vector2i
) -> bool:

	# ========================================================
	# LIMITES
	# ========================================================

	if not is_cell_inside_map(cell):

		return false


	# ========================================================
	# SYMBOLE
	# ========================================================

	var symbol: String = str(
		grid[cell.y][cell.x]
	)


	# ========================================================
	# ROCHER
	# ========================================================

	if symbol == "#":

		return false


	# ========================================================
	# ARBRE
	# ========================================================

	if symbol == "t":

		return false


	# ========================================================
	# TOUT LE RESTE EST TRAVERSABLE
	# ========================================================

	return true


# ============================================================
# DÉPLACEMENT EXCAVATEUR
# ============================================================
#
# Règles :
#
# 1. avance tout droit
#
# 2. rocher / arbre / bordure :
#    tourne à gauche
#
# 3. autre machine :
#    tourne à gauche
#
# Les collisions concernent :
#
# X + X
# X + G
# G + X
# G + G
#
# ============================================================

func excavator_try_move(
	excavator: Node
) -> void:

	if not is_instance_valid(excavator):

		return


	if not excavator.has_method(
		"get_direction"
	):

		return


	if not "grid_position" in excavator:

		return


	# ========================================================
	# NE PAS BOUGER SI DÉJÀ EN MOUVEMENT
	# ========================================================

	if "moving" in excavator:

		if excavator.moving:

			return


	# ========================================================
	# POSITION
	# ========================================================

	var current_cell: Vector2i = (
		excavator.grid_position
	)


	# ========================================================
	# DIRECTION
	# ========================================================

	var direction: Vector2i = (
		excavator.get_direction()
	)


	# ========================================================
	# CASE CIBLE
	# ========================================================

	var next_cell: Vector2i = (
		current_cell + direction
	)


	# ========================================================
	# COLLISION MACHINE
	# ========================================================

	if check_machine_collision(
		excavator,
		next_cell
	):

		if excavator.has_method(
			"turn_left"
		):

			excavator.turn_left()

		return


	# ========================================================
	# CASE LIBRE
	# ========================================================

	if is_cell_free(
		next_cell
	):

		if excavator.has_method(
			"start_move"
		):

			excavator.start_move(
				next_cell
			)

		return


	# ========================================================
	# OBSTACLE
	# ========================================================

	if excavator.has_method(
		"turn_left"
	):

		excavator.turn_left()


# ============================================================
# DÉPLACEMENT GRAPPLER
# ============================================================
#
# Règles :
#
# 1. avance tout droit
#
# 2. arbre :
#    coupe l'arbre
#
# 3. rocher / bordure :
#    tourne à droite
#
# 4. autre machine :
#    tourne à droite
#
# ============================================================

func grappler_try_move(
	grappler: Node
) -> void:

	if not is_instance_valid(grappler):

		return


	if not grappler.has_method(
		"get_direction"
	):

		return


	if not "grid_position" in grappler:

		return


	# ========================================================
	# NE PAS BOUGER SI DÉJÀ EN MOUVEMENT
	# ========================================================

	if "moving" in grappler:

		if grappler.moving:

			return


	# ========================================================
	# POSITION
	# ========================================================

	var current_cell: Vector2i = (
		grappler.grid_position
	)


	# ========================================================
	# DIRECTION
	# ========================================================

	var direction: Vector2i = (
		grappler.get_direction()
	)


	# ========================================================
	# CASE CIBLE
	# ========================================================

	var next_cell: Vector2i = (
		current_cell + direction
	)


	# ========================================================
	# BORDURE
	# ========================================================

	if not is_cell_inside_map(
		next_cell
	):

		if grappler.has_method(
			"turn_right"
		):

			grappler.turn_right()

		return


	# ========================================================
	# COLLISION MACHINE
	# ========================================================
	#
	# Ceci bloque :
	#
	# G contre G
	# G contre X
	# X contre G
	# X contre X
	#
	# ========================================================

	if check_machine_collision(
		grappler,
		next_cell
	):

		if grappler.has_method(
			"turn_right"
		):

			grappler.turn_right()

		return


	# ========================================================
	# SYMBOLE
	# ========================================================

	var symbol: String = str(
		grid[next_cell.y][next_cell.x]
	)


	# ========================================================
	# ARBRE
	# ========================================================

	if symbol == "t":

		cut_tree(
			next_cell
		)

		return


	# ========================================================
	# CASE LIBRE
	# ========================================================

	if is_cell_free(
		next_cell
	):

		if grappler.has_method(
			"start_move"
		):

			grappler.start_move(
				next_cell
			)

		return


	# ========================================================
	# OBSTACLE
	# ========================================================

	if grappler.has_method(
		"turn_right"
	):

		grappler.turn_right()


# ============================================================
# COUPER UN ARBRE
# ============================================================

func cut_tree(
	cell: Vector2i
) -> void:

	if not is_cell_inside_map(
		cell
	):

		return


	var symbol: String = str(
		grid[cell.y][cell.x]
	)


	if symbol != "t":

		return


	# ========================================================
	# MODIFIER LA GRILLE
	# ========================================================

	grid[cell.y][cell.x] = "t_coupe"


	# ========================================================
	# MODIFIER LE VISUEL
	# ========================================================

	replace_tree_visual(
		cell
	)


# ============================================================
# REMPLACER L'ARBRE PAR ARBRE COUPÉ
# ============================================================

func replace_tree_visual(
	cell: Vector2i
) -> void:

	var tree_position := Vector2(

		(cell.x + BORDER_SIZE)
		* TILE_SIZE,

		(cell.y + BORDER_SIZE)
		* TILE_SIZE
	)


	# ========================================================
	# SUPPRIMER ARBRE
	# ========================================================

	for child in map_container.get_children():

		if not child is Sprite2D:

			continue


		var sprite := (
			child as Sprite2D
		)


		if sprite.texture != OBJECT_SPRITES["t"]:

			continue


		if sprite.position.distance_to(
			tree_position
		) < 1.0:

			sprite.queue_free()

			break


	# ========================================================
	# ARBRE COUPÉ
	# ========================================================

	var cut_tree_sprite := Sprite2D.new()

	cut_tree_sprite.texture = (
		CUT_TREE_TEXTURE
	)

	cut_tree_sprite.centered = false

	cut_tree_sprite.position = tree_position

	cut_tree_sprite.z_index = 1


	if CUT_TREE_TEXTURE.get_width() > 0:

		cut_tree_sprite.scale = Vector2(

			float(TILE_SIZE)
			/ CUT_TREE_TEXTURE.get_width(),

			float(TILE_SIZE)
			/ CUT_TREE_TEXTURE.get_height()
		)


	map_container.add_child(
		cut_tree_sprite
	)


# ============================================================
# CREUSER UNE CASE
# ============================================================
#
# Si la cellule contient :
#
# .  -> devient trou
# *  -> coffre disparaît + trou
# +  -> gemme disparaît + trou
# @  -> buisson disparaît + trou
#
# Le rocher et l'arbre ne peuvent pas être creusés.
#
# ============================================================

func dig_cell(
	cell: Vector2i
) -> void:

	if not is_cell_inside_map(
		cell
	):

		return


	var current_symbol: String = str(
		grid[cell.y][cell.x]
	)


	# ========================================================
	# ROCHER
	# ========================================================

	if current_symbol == "#":

		return


	# ========================================================
	# ARBRE
	# ========================================================

	if current_symbol == "t":

		return


	# ========================================================
	# DÉJÀ UN TROU
	# ========================================================

	if current_symbol == "o":

		return


	# ========================================================
	# SUPPRIMER LE VISUEL D'OBJET
	# ========================================================
	#
	# Cela supprime notamment :
	#
	# * coffre
	# + gemme
	# @ buisson
	#
	# ========================================================

	if (
		current_symbol == "*"
		or current_symbol == "+"
		or current_symbol == "@"
	):

		remove_object_visual(
			cell,
			current_symbol
		)


	# ========================================================
	# CRÉER LE TROU
	# ========================================================

	grid[cell.y][cell.x] = "o"


	# ========================================================
	# AFFICHER LE TROU
	# ========================================================

	update_hole_visual(
		cell
	)


# ============================================================
# SUPPRIMER LE VISUEL D'UN OBJET
# ============================================================

func remove_object_visual(
	cell: Vector2i,
	symbol: String
) -> void:

	if not OBJECT_SPRITES.has(symbol):

		return


	var object_position := Vector2(

		(cell.x + BORDER_SIZE)
		* TILE_SIZE,

		(cell.y + BORDER_SIZE)
		* TILE_SIZE
	)


	var object_texture: Texture2D = (
		OBJECT_SPRITES[symbol]
	)


	for child in map_container.get_children():

		if not child is Sprite2D:

			continue


		var sprite := (
			child as Sprite2D
		)


		if sprite.texture != object_texture:

			continue


		if sprite.position.distance_to(
			object_position
		) < 1.0:

			sprite.queue_free()


# ============================================================
# AFFICHER UN TROU
# ============================================================

func update_hole_visual(
	cell: Vector2i
) -> void:

	var pos := Vector2(

		(cell.x + BORDER_SIZE)
		* TILE_SIZE,

		(cell.y + BORDER_SIZE)
		* TILE_SIZE
	)


	var hole_sprite := Sprite2D.new()

	hole_sprite.texture = (
		HOLE_TEXTURE
	)

	hole_sprite.centered = false

	hole_sprite.position = pos

	hole_sprite.z_index = 1


	if HOLE_TEXTURE.get_width() > 0:

		hole_sprite.scale = Vector2(

			float(TILE_SIZE)
			/ HOLE_TEXTURE.get_width(),

			float(TILE_SIZE)
			/ HOLE_TEXTURE.get_height()
		)


	map_container.add_child(
		hole_sprite
	)


# ============================================================
# BOUTON CHARGER
# ============================================================

func _on_load_button_pressed() -> void:
	AudioManager.play_button_click()

	file_dialog.popup_centered(
		Vector2i(650, 450)
	)


# ============================================================
# BOUTON QUITTER
# ============================================================

func _on_quit_button_pressed() -> void:
	#AudioManager.play_button_click()

	get_tree().change_scene_to_file(
		"res://Scenes/Menu/MainMenu.tscn"
	)


# ============================================================
# CALCUL TAILLE CASE
# ============================================================

func calculate_tile_size() -> void:

	var viewport_size := (
		get_viewport()
		.get_visible_rect()
		.size
	)


	var total_columns := (
		map_width
		+ BORDER_SIZE * 2
	)


	var total_rows := (
		map_height
		+ BORDER_SIZE * 2
	)


	var tile_width := (
		viewport_size.x
		/ total_columns
	)


	var tile_height := (
		viewport_size.y
		/ total_rows
	)


	TILE_SIZE = int(
		min(
			tile_width,
			tile_height
		)
	)


	TILE_SIZE = max(
		TILE_SIZE,
		1
	)


# ============================================================
# CHARGEMENT DE LA CARTE
# ============================================================

func generate_map_from_file(
	path: String
) -> void:

	# ========================================================
	# FICHIER EXISTE ?
	# ========================================================

	if not FileAccess.file_exists(
		path
	):

		info_label.text = (
			"Fichier introuvable : "
			+ path
		)

		return


	# ========================================================
	# SUPPRIMER ANCIENNE CARTE
	# ========================================================

	for child in map_container.get_children():

		child.queue_free()


	# ========================================================
	# VIDER LES LISTES DE MACHINES
	# ========================================================

	excavators.clear()

	grapplers.clear()


	# ========================================================
	# OUVRIR LE FICHIER
	# ========================================================

	var file := FileAccess.open(
		path,
		FileAccess.READ
	)


	if file == null:

		info_label.text = (
			"Impossible d'ouvrir : "
			+ path
		)

		return


	# ========================================================
	# EN-TÊTE
	# ========================================================

	var header_line := (
		file.get_line()
		.strip_edges()
	)


	var header_values: Array = []


	for part in header_line.split(
		" ",
		false
	):

		if part.is_valid_int():

			header_values.append(
				part.to_int()
			)


	if header_values.size() < 3:

		info_label.text = (
			"⚠️ En-tête invalide"
		)

		file.close()

		return


	# ========================================================
	# INFORMATIONS
	# ========================================================

	map_height = header_values[0]

	map_width = header_values[1]

	level_time = header_values[2]


	info_label.text = (
		"Carte %dx%d | Temps : %ds"
		% [
			map_width,
			map_height,
			level_time
		]
	)


	# ========================================================
	# LIRE LA GRILLE
	# ========================================================

	grid.clear()


	for y in range(
		map_height
	):

		var row: Array = []


		if file.eof_reached():

			for x in range(
				map_width
			):

				row.append(".")


		else:

			var line := (
				file.get_line()
			)


			for x in range(
				map_width
			):

				if x < line.length():

					row.append(
						line[x]
					)

				else:

					row.append(".")


		grid.append(
			row
		)


	file.close()


	# ========================================================
	# CALCUL TAILLE
	# ========================================================

	calculate_tile_size()


	# ========================================================
	# DESSIN BORDURE
	# ========================================================

	draw_border()


	# ========================================================
	# DESSIN CARTE
	# ========================================================

	draw_floor_and_objects()


	# ========================================================
	# CENTRER
	# ========================================================

	center_map()


# ============================================================
# DESSIN DE LA BORDURE
# ============================================================

func draw_border() -> void:

	var total_width := (
		map_width
		+ BORDER_SIZE * 2
	)


	var total_height := (
		map_height
		+ BORDER_SIZE * 2
	)


	for y in range(
		total_height
	):

		for x in range(
			total_width
		):

			var inside := (

				x >= BORDER_SIZE

				and x < (
					BORDER_SIZE
					+ map_width
				)

				and y >= BORDER_SIZE

				and y < (
					BORDER_SIZE
					+ map_height
				)
			)


			if inside:

				continue


			# =================================================
			# CÔTÉS
			# =================================================

			if (
				x == 0
				or x == total_width - 1
			):

				var side := ColorRect.new()

				side.size = Vector2(
					TILE_SIZE,
					TILE_SIZE
				)

				side.position = Vector2(
					x * TILE_SIZE,
					y * TILE_SIZE
				)

				side.color = BORDER_COLOR

				side.z_index = 10

				map_container.add_child(
					side
				)

				continue


			# =================================================
			# HAUT
			# =================================================

			if y == 0:

				var top := Sprite2D.new()

				top.texture = (
					BORDER_TOP_TEXTURE
				)

				top.centered = false

				top.position = Vector2(
					x * TILE_SIZE,
					y * TILE_SIZE
				)

				top.scale = Vector2(

					float(TILE_SIZE)
					/ BORDER_TOP_TEXTURE.get_width(),

					float(TILE_SIZE)
					/ BORDER_TOP_TEXTURE.get_height()
				)

				top.z_index = 10

				map_container.add_child(
					top
				)

				continue


			# =================================================
			# BAS
			# =================================================

			if y == total_height - 1:

				var bottom := Sprite2D.new()

				bottom.texture = (
					BORDER_BOTTOM_TEXTURE
				)

				bottom.centered = false

				bottom.position = Vector2(
					x * TILE_SIZE,
					y * TILE_SIZE
				)

				bottom.scale = Vector2(

					float(TILE_SIZE)
					/ BORDER_BOTTOM_TEXTURE.get_width(),

					float(TILE_SIZE)
					/ BORDER_BOTTOM_TEXTURE.get_height()
				)

				bottom.z_index = 10

				map_container.add_child(
					bottom
				)


# ============================================================
# SOL + OBJETS + MACHINES
# ============================================================

func draw_floor_and_objects() -> void:

	for y in range(
		map_height
	):

		for x in range(
			map_width
		):

			var symbol: String = str(
				grid[y][x]
			)


			# =================================================
			# POSITION
			# =================================================

			var pos := Vector2(

				(x + BORDER_SIZE)
				* TILE_SIZE,

				(y + BORDER_SIZE)
				* TILE_SIZE
			)


			# =================================================
			# SOL
			# =================================================

			var floor_sprite := Sprite2D.new()

			floor_sprite.texture = (
				FLOOR_TEXTURE
			)

			floor_sprite.centered = false

			floor_sprite.position = pos

			floor_sprite.z_index = 0

			floor_sprite.scale = Vector2(

				float(TILE_SIZE)
				/ FLOOR_TEXTURE.get_width(),

				float(TILE_SIZE)
				/ FLOOR_TEXTURE.get_height()
			)

			map_container.add_child(
				floor_sprite
			)


			# =================================================
			# EXCAVATEUR
			# =================================================

			if symbol == "X":

				var excavator := (
					EXCAVATOR_SCENE.instantiate()
				)


				map_container.add_child(
					excavator
				)


				excavator.z_index = 2


				# =================================================
				# SIGNAL
				# =================================================

				if excavator.has_signal(
					"dig_requested"
				):

					excavator.dig_requested.connect(
						dig_cell
					)


				# =================================================
				# TAILLE
				# =================================================

				if excavator.has_method(
					"setup_for_tile_size"
				):

					excavator.setup_for_tile_size(
						float(TILE_SIZE)
					)


				# =================================================
				# POSITION
				# =================================================

				if excavator.has_method(
					"setup_position"
				):

					excavator.setup_position(
						Vector2i(
							x,
							y
						)
					)


				# =================================================
				# MAP
				# =================================================

				if excavator.has_method(
					"setup_map"
				):

					excavator.setup_map(
						self
					)


				# =================================================
				# IA
				# =================================================

				if excavator.has_method(
					"start_ai"
				):

					excavator.start_ai()


				# =================================================
				# ENREGISTRER
				# =================================================

				excavators.append(
					excavator
				)


				continue


			# =================================================
			# GRAPPLER
			# =================================================

			if symbol == "G":

				var grappler := (
					GRAPPLER_SCENE.instantiate()
				)


				map_container.add_child(
					grappler
				)


				grappler.z_index = 2


				# =================================================
				# TAILLE
				# =================================================

				if grappler.has_method(
					"setup_for_tile_size"
				):

					grappler.setup_for_tile_size(
						float(TILE_SIZE)
					)


				# =================================================
				# POSITION
				# =================================================

				if grappler.has_method(
					"setup_position"
				):

					grappler.setup_position(
						Vector2i(
							x,
							y
						)
					)


				# =================================================
				# MAP
				# =================================================

				if grappler.has_method(
					"setup_map"
				):

					grappler.setup_map(
						self
					)


				# =================================================
				# IA
				# =================================================

				if grappler.has_method(
					"start_ai"
				):

					grappler.start_ai()


				# =================================================
				# ENREGISTRER
				# =================================================

				grapplers.append(
					grappler
				)


				continue


			# =================================================
			# AUTRES OBJETS
			# =================================================

			if OBJECT_SPRITES.has(
				symbol
			):

				var texture: Texture2D = (
					OBJECT_SPRITES[symbol]
				)


				var sprite := Sprite2D.new()

				sprite.texture = texture

				sprite.centered = false

				sprite.position = pos

				sprite.z_index = 1

				sprite.scale = Vector2(

					float(TILE_SIZE)
					/ texture.get_width(),

					float(TILE_SIZE)
					/ texture.get_height()
				)

				map_container.add_child(
					sprite
				)


# ============================================================
# CENTRER LA CARTE
# ============================================================

func center_map() -> void:

	var viewport_size := (
		get_viewport()
		.get_visible_rect()
		.size
	)


	var header_height := 80.0


	var available_height := (
		viewport_size.y
		- header_height
	)


	var total_pixel_size := Vector2(

		(
			map_width
			+ BORDER_SIZE * 2
		) * TILE_SIZE,

		(
			map_height
			+ BORDER_SIZE * 2
		) * TILE_SIZE
	)


	var map_x := (
		viewport_size.x
		- total_pixel_size.x
	) / 2.0


	var map_y := (
		header_height
		+ (
			available_height
			- total_pixel_size.y
		) / 2.0
	)


	map_container.position = Vector2(
		map_x,
		map_y
	)
