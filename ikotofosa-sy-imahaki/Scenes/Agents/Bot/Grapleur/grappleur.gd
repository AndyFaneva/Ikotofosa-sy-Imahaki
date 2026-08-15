extends Node2D


# ============================================================
# GRAPPLER
# ============================================================
#
# COMPORTEMENT :
#
# 1. Avance tout droit dans sa direction.
#
# 2. Si la case devant est libre :
#       -> MOVE
#
# 3. Si la case devant contient un arbre "t" :
#       -> CUT
#       -> l'arbre est supprimé de la carte
#       -> le Grappler continue tout droit
#
# 4. Si la case devant contient un rocher "#"
#    ou la bordure :
#       -> tourne à droite
#
# 5. Le comportement recommence indéfiniment.
#
# ============================================================


# ============================================================
# ANIMATION
# ============================================================

@onready var animated_sprite: AnimatedSprite2D = (
	$AnimatedSprite2D
)


# ============================================================
# CONFIGURATION
# ============================================================

@export var speed: float = 100.0

# Temps utilisé pour couper un arbre.
# Mets 0.0 si tu veux une coupe instantanée.
@export var cut_pause_time: float = 0.5


# ============================================================
# DIRECTIONS
# ============================================================
#
# 0 = HAUT
# 1 = DROITE
# 2 = BAS
# 3 = GAUCHE
#
# Le Grappler tourne dans le sens horaire.
#
# HAUT -> DROITE
# DROITE -> BAS
# BAS -> GAUCHE
# GAUCHE -> HAUT
#
# ============================================================

var direction_index: int = 0


# ============================================================
# POSITION
# ============================================================

# Position actuelle dans la grille.
var grid_position := Vector2i.ZERO


# Case vers laquelle on se déplace.
var target_grid_position := Vector2i.ZERO


# Position pixel cible.
var target_position := Vector2.ZERO


# Taille d'une case.
var tile_size: float = 64.0


# ============================================================
# ÉTAT DU DÉPLACEMENT
# ============================================================

var moving: bool = false


# ============================================================
# ÉTAT DE COUPE
# ============================================================

var cutting: bool = false

var cut_timer: float = 0.0

# Case de l'arbre actuellement coupé.
var cut_cell := Vector2i.ZERO


# ============================================================
# RÉFÉRENCE VERS LA MAP
# ============================================================

var map_reference: Node = null


# ============================================================
# SIGNAL
# ============================================================

signal cut_requested(cell: Vector2i)


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	play_animation("idle")


# ============================================================
# CONFIGURATION DE LA MAP
# ============================================================

func setup_map(map_node: Node) -> void:

	map_reference = map_node


# ============================================================
# DÉMARRER L'IA
# ============================================================

func start_ai() -> void:

	moving = false

	cutting = false

	cut_timer = 0.0


# ============================================================
# CONFIGURATION DE LA TAILLE
# ============================================================

func setup_for_tile_size(
	new_tile_size: float
) -> void:

	tile_size = new_tile_size


	if animated_sprite == null:
		return


	if animated_sprite.sprite_frames == null:
		return


	var texture := (
		animated_sprite.sprite_frames.get_frame_texture(
			"idle",
			0
		)
	)


	if texture == null:
		return


	var texture_size := texture.get_size()


	if (
		texture_size.x <= 0.0
		or texture_size.y <= 0.0
	):
		return


	animated_sprite.scale = Vector2(
		tile_size / texture_size.x,
		tile_size / texture_size.y
	)


# ============================================================
# POSITION INITIALE
# ============================================================

func setup_position(
	start_grid_position: Vector2i
) -> void:

	grid_position = start_grid_position

	target_grid_position = grid_position

	position = grid_to_world(
		grid_position
	)


# ============================================================
# GRILLE -> MONDE
# ============================================================

func grid_to_world(
	cell: Vector2i
) -> Vector2:

	# La map possède une bordure d'une case.
	#
	# Case réelle 0,0 :
	#
	# position = 1,1 dans MapContainer

	return Vector2(
		(cell.x + 1) * tile_size
		+ tile_size / 2.0,

		(cell.y + 1) * tile_size
		+ tile_size / 2.0
	)


# ============================================================
# DIRECTION
# ============================================================

func get_direction() -> Vector2i:

	match direction_index:

		0:
			return Vector2i.UP

		1:
			return Vector2i.RIGHT

		2:
			return Vector2i.DOWN

		3:
			return Vector2i.LEFT

	return Vector2i.UP


# ============================================================
# TOURNER À DROITE
# ============================================================

func turn_right() -> void:

	# Rotation horaire.
	direction_index += 1

	if direction_index > 3:
		direction_index = 0

	update_animation_direction()


# ============================================================
# ANIMATION DE DIRECTION
# ============================================================

func update_animation_direction() -> void:

	match direction_index:

		0:
			play_animation("walk-up")

		1:
			play_animation("walk-right")

		2:
			play_animation("walk-down")

		3:
			play_animation("walk-left")


# ============================================================
# JOUER UNE ANIMATION
# ============================================================

func play_animation(
	animation_name: String
) -> void:

	if animated_sprite == null:
		return


	if animated_sprite.sprite_frames == null:
		return


	if not animated_sprite.sprite_frames.has_animation(
		animation_name
	):
		return


	if animated_sprite.animation != animation_name:

		animated_sprite.play(
			animation_name
		)


# ============================================================
# DEMANDER UN DÉPLACEMENT
# ============================================================

func start_move(
	next_cell: Vector2i
) -> void:

	# Impossible de bouger pendant la coupe.
	if cutting:
		return


	# Impossible de lancer un deuxième déplacement.
	if moving:
		return


	target_grid_position = next_cell

	target_position = grid_to_world(
		next_cell
	)

	moving = true

	update_animation_direction()


# ============================================================
# FIN DU DÉPLACEMENT
# ============================================================

func finish_move() -> void:

	grid_position = target_grid_position

	position = target_position

	moving = false


	# Continuer à avancer.
	# La décision suivante sera prise
	# au prochain _process().
	update_animation_direction()


# ============================================================
# VÉRIFIER LA CASE DEVANT
# ============================================================

func check_next_cell() -> void:

	if map_reference == null:
		return


	var direction := get_direction()

	var next_cell := (
		grid_position + direction
	)


	# ========================================================
	# SÉCURITÉ
	# ========================================================

	if not map_reference.has_method(
		"get_cell_symbol"
	):

		# Si la map ne possède pas encore
		# cette fonction, utiliser directement
		# sa grille.
		check_next_cell_from_grid(
			next_cell
		)

		return


	var symbol: String = (
		map_reference.get_cell_symbol(
			next_cell
		)
	)


	handle_cell(
		next_cell,
		symbol
	)


# ============================================================
# VÉRIFICATION DIRECTE DE LA GRILLE
# ============================================================

func check_next_cell_from_grid(
	next_cell: Vector2i
) -> void:

	if map_reference == null:
		return


	# --------------------------------------------------------
	# Hors carte
	# --------------------------------------------------------

	if not "map_width" in map_reference:
		return

	if not "map_height" in map_reference:
		return

	if next_cell.x < 0:
		turn_right()
		return

	if next_cell.x >= map_reference.map_width:
		turn_right()
		return

	if next_cell.y < 0:
		turn_right()
		return

	if next_cell.y >= map_reference.map_height:
		turn_right()
		return


	# --------------------------------------------------------
	# Sécurité grille
	# --------------------------------------------------------

	if next_cell.y >= map_reference.grid.size():
		turn_right()
		return

	if next_cell.x >= (
		map_reference.grid[next_cell.y].size()
	):
		turn_right()
		return


	# --------------------------------------------------------
	# Symbole
	# --------------------------------------------------------

	var symbol: String = str(
		map_reference.grid[
			next_cell.y
		][
			next_cell.x
		]
	)


	handle_cell(
		next_cell,
		symbol
	)


# ============================================================
# TRAITER LA CASE
# ============================================================

func handle_cell(
	next_cell: Vector2i,
	symbol: String
) -> void:

	# ========================================================
	# ARBRE
	# ========================================================

	if symbol == "t":

		cut_tree(
			next_cell
		)

		return


	# ========================================================
	# ROCHER
	# ========================================================

	if symbol == "#":

		turn_right()

		return
		
	if symbol == "o":

		turn_right()

		return
		
	if symbol == "X":

		turn_right()

		return


	# ========================================================
	# CASE LIBRE
	# ========================================================

	start_move(
		next_cell
	)


# ============================================================
# COUPER UN ARBRE
# ============================================================

func cut_tree(
	cell: Vector2i
) -> void:

	if cutting:
		return


	if map_reference == null:
		return


	cutting = true

	cut_cell = cell

	moving = false


	# ========================================================
	# ANIMATION DE COUPE
	# ========================================================

	play_animation("cut")


	# ========================================================
	# INFORMER LA MAP
	# ========================================================

	if map_reference.has_method(
		"cut_tree"
	):

		map_reference.cut_tree(
			cell
		)

	else:

		# Fallback :
		# modifier directement la grille.

		if (
			cell.y >= 0
			and cell.y < map_reference.grid.size()
			and cell.x >= 0
			and cell.x < map_reference.grid[cell.y].size()
		):

			if str(
				map_reference.grid[
					cell.y
				][
					cell.x
				]
			) == "t":

				map_reference.grid[
					cell.y
				][
					cell.x
				] = "."


	# Signal.
	cut_requested.emit(
		cell
	)


	# ========================================================
	# TEMPS DE COUPE
	# ========================================================

	cut_timer = cut_pause_time


# ============================================================
# FIN DE LA COUPE
# ============================================================

func finish_cut() -> void:

	cutting = false

	cut_timer = 0.0


	# ========================================================
	# APRÈS AVOIR COUPÉ
	# ========================================================
	#
	# L'arbre a disparu.
	# La case est maintenant libre.
	#
	# Le Grappler doit donc continuer
	# dans la même direction.
	# ========================================================

	update_animation_direction()


# ============================================================
# PROCESS
# ============================================================

func _process(delta: float) -> void:

	# ========================================================
	# COUPE
	# ========================================================

	if cutting:

		cut_timer -= delta


		if cut_timer <= 0.0:

			finish_cut()


		return


	# ========================================================
	# DÉPLACEMENT
	# ========================================================

	if moving:

		position = position.move_toward(
			target_position,
			speed * delta
		)


		# ----------------------------------------------------
		# ARRIVÉE
		# ----------------------------------------------------

		if position.distance_to(
			target_position
		) < 0.5:

			finish_move()


		return


	# ========================================================
	# DÉCISION IA
	# ========================================================

	check_next_cell()
