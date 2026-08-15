extends Node2D


# ============================================================
# EXCAVATEUR
# ============================================================
#
# COMPORTEMENT :
#
# 1. Avance tout droit.
#
# 2. Si un rocher, un arbre ou la bordure bloque :
#    tourne à gauche.
#
# 3. Continue dans la nouvelle direction.
#
# 4. Après 5 déplacements :
#    - s'arrête
#    - creuse un trou
#    - attend 2 secondes
#
# 5. Reprend ensuite son chemin.
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

const STEPS_BEFORE_DIG: int = 5

const DIG_PAUSE_TIME: float = 2.0


# ============================================================
# DIRECTIONS
# ============================================================

# 0 = haut
# 1 = droite
# 2 = bas
# 3 = gauche

var direction_index: int = 0


# ============================================================
# VARIABLES
# ============================================================

# Taille d'une case.
var tile_size: float = 64.0


# Position dans la grille.
var grid_position := Vector2i.ZERO


# Case cible.
var target_grid_position := Vector2i.ZERO


# Position pixel cible.
var target_position := Vector2.ZERO


# Est-ce que l'excavateur se déplace ?
var moving: bool = false


# Nombre de déplacements effectués.
var steps: int = 0


# Est-ce qu'il est en train de creuser / attendre ?
var digging: bool = false


# Temps restant de pause.
var dig_timer: float = 0.0


# Référence vers MapScene.
var map_reference: Node = null


# ============================================================
# SIGNAL
# ============================================================

signal dig_requested(cell: Vector2i)


# ============================================================
# INITIALISATION
# ============================================================

func _ready() -> void:

	play_animation(
		"idle"
	)


# ============================================================
# CONFIGURATION MAP
# ============================================================

func setup_map(map_node: Node) -> void:

	map_reference = map_node


# ============================================================
# DÉMARRER L'IA
# ============================================================

func start_ai() -> void:

	# On s'assure que l'excavateur
	# n'est pas en train de creuser.

	digging = false

	dig_timer = 0.0

	moving = false


# ============================================================
# CONFIGURATION TAILLE
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
		animated_sprite.sprite_frames
		.get_frame_texture(
			"idle",
			0
		)
	)


	if texture == null:
		return


	var texture_size := (
		texture.get_size()
	)


	if (
		texture_size.x <= 0
		or texture_size.y <= 0
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

	grid_position = (
		start_grid_position
	)

	target_grid_position = (
		grid_position
	)


	position = (
		grid_to_world(
			grid_position
		)
	)


# ============================================================
# CASE -> POSITION PIXEL
# ============================================================

func grid_to_world(
	cell: Vector2i
) -> Vector2:

	# IMPORTANT :
	#
	# La carte possède une bordure d'une case.
	#
	# Donc :
	#
	# case 0,0
	# devient
	# position 1,1
	#
	# dans MapContainer.

	return Vector2(

		(
			cell.x + 1
		) * tile_size
		+ tile_size / 2.0,

		(
			cell.y + 1
		) * tile_size
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
# TOURNER À GAUCHE
# ============================================================

func turn_left() -> void:

	direction_index -= 1


	if direction_index < 0:

		direction_index = 3


	update_animation_direction()



# ============================================================
# ANIMATION DIRECTION
# ============================================================

func update_animation_direction() -> void:

	match direction_index:

		0:
			play_animation(
				"walk-up"
			)

		1:
			play_animation(
				"walk-right"
			)

		2:
			play_animation(
				"walk-down"
			)

		3:
			play_animation(
				"walk-left"
			)


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
# COMMENCER UN DÉPLACEMENT
# ============================================================

func start_move(
	next_cell: Vector2i
) -> void:

	# Sécurité :
	# impossible de commencer un mouvement
	# pendant la pause de creusement.

	if digging:
		return


	target_grid_position = (
		next_cell
	)


	target_position = (
		grid_to_world(
			next_cell
		)
	)


	moving = true


	update_animation_direction()


# ============================================================
# FIN DU DÉPLACEMENT
# ============================================================

func finish_move() -> void:

	grid_position = (
		target_grid_position
	)


	position = (
		target_position
	)


	moving = false


	# ========================================================
	# COMPTER LE PAS
	# ========================================================

	steps += 1


	# ========================================================
	# 5 PAS ?
	# ========================================================

	if steps >= STEPS_BEFORE_DIG:

		steps = 0

		begin_dig()


# ============================================================
# COMMENCER LE CREUSEMENT
# ============================================================

func begin_dig() -> void:

	# Bloquer les déplacements.
	digging = true


	# Arrêter le déplacement.
	moving = false


	# Animation de creusement.
	play_animation(
		"dig"
	)


	# ========================================================
	# DEMANDER À LA MAP DE CREUSER
	# ========================================================

	dig_requested.emit(
		grid_position
	)


	# ========================================================
	# PAUSE DE 2 SECONDES
	# ========================================================

	dig_timer = DIG_PAUSE_TIME


# ============================================================
# FIN DE LA PAUSE
# ============================================================

func finish_dig() -> void:

	digging = false

	dig_timer = 0.0


	# Reprendre l'animation de marche.
	update_animation_direction()


# ============================================================
# PROCESS
# ============================================================

func _process(delta: float) -> void:

	# ========================================================
	# PAUSE DE CREUSEMENT
	# ========================================================

	if digging:

		dig_timer -= delta


		if dig_timer <= 0.0:

			finish_dig()


		return


	# ========================================================
	# DÉPLACEMENT
	# ========================================================

	if not moving:

		# Demander à la map de décider
		# si la prochaine case est libre.

		if map_reference != null:

			if map_reference.has_method(
				"excavator_try_move"
			):

				map_reference.excavator_try_move(
					self
				)

		return


	# ========================================================
	# DÉPLACEMENT PHYSIQUE
	# ========================================================

	position = position.move_toward(

		target_position,

		speed * delta
	)


	# ========================================================
	# ARRIVÉE
	# ========================================================

	if position.distance_to(
		target_position
	) < 0.5:

		finish_move()
