extends Control

## Diaporama d'intro : images + texte qui apparaît, fondu entre les slides.

@export var slides: Array[CutsceneSlide] = []
@export_file("*.tscn") var next_scene_path: String = ""
@export var fade_duration: float = 0.6

@onready var slide_image: TextureRect = %SlideImage
@onready var slide_text: Label = %SlideText
@onready var skip_button: Button = %SkipButton
@onready var continue_hint: Label = %ContinueHint

var current_index: int = 0
var is_transitioning: bool = false
var auto_advance_timer: Timer


func _ready() -> void:
	if slides.is_empty():
		slides = _build_default_backstory_slides()

	skip_button.pressed.connect(_on_skip_pressed)

	auto_advance_timer = Timer.new()
	auto_advance_timer.one_shot = true
	auto_advance_timer.timeout.connect(_advance_slide)
	add_child(auto_advance_timer)

	slide_image.modulate.a = 0.0
	slide_text.modulate.a = 0.0

	show_slide(0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_advance_slide()
	elif event is InputEventKey and event.pressed:
		_advance_slide()


func show_slide(index: int) -> void:
	if index >= slides.size():
		_on_cutscene_finished()
		return

	current_index = index
	var slide: CutsceneSlide = slides[index]

	slide_image.texture = slide.image
	slide_image.visible = slide.image != null
	slide_text.text = slide.text

	is_transitioning = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(slide_image, "modulate:a", 1.0, fade_duration)
	tween.tween_property(slide_text, "modulate:a", 1.0, fade_duration)
	tween.chain().tween_callback(func():
		is_transitioning = false
		auto_advance_timer.start(slide.duration)
	)


func _advance_slide() -> void:
	if is_transitioning:
		return

	auto_advance_timer.stop()
	is_transitioning = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(slide_image, "modulate:a", 0.0, fade_duration * 0.5)
	tween.tween_property(slide_text, "modulate:a", 0.0, fade_duration * 0.5)
	tween.chain().tween_callback(func():
		show_slide(current_index + 1)
	)


func _on_skip_pressed() -> void:
	_on_cutscene_finished()


## Appelée à la fin du diaporama (dernière slide ou "Passer").
## Pour l'instant ne fait rien d'autre qu'afficher un message dans la console
## puisqu'on ne touche à aucune autre scène.
func _on_cutscene_finished() -> void:
	print("Cinématique terminée.")
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)


func _build_default_backstory_slides() -> Array[CutsceneSlide]:

	var default_slides: Array[CutsceneSlide] = []


	# ========================================================
	# SLIDE 1
	# ========================================================

	var slide1 := CutsceneSlide.new()

	slide1.image = preload(
		"res://assets/cutscene/guerre.jpg"
	)

	slide1.text = (
		"La guerre contre les envahisseurs fait toujours "
		+ "rage dans le royaume dont le village d'Ikotofosa "
		+ "et Imahaki fait partie."
	)

	slide1.duration = 4.5

	default_slides.append(slide1)


	# ========================================================
	# SLIDE 2
	# ========================================================

	var slide2 := CutsceneSlide.new()

	slide2.image = preload(
		"res://assets/cutscene/roi.png"
	)

	slide2.text = (
		"Le roi leur a ordonné de collecter et de déplacer "
		+ "tous les trésors cachés par les ancêtres, "
		+ "en dernier recours."
	)

	slide2.duration = 4.5

	default_slides.append(slide2)


	# ========================================================
	# SLIDE 3
	# ========================================================

	var slide3 := CutsceneSlide.new()

	slide3.image = preload(
		"res://assets/cutscene/village.jpg"
	)

	slide3.text = (
		"Les deux amis ont réussi cette mission pour leur "
		+ "propre village. Maintenant, ils doivent faire de "
		+ "même pour toutes les autres villes du royaume."
	)

	slide3.duration = 4.5

	default_slides.append(slide3)


	# ========================================================
	# SLIDE 4
	# ========================================================

	var slide4 := CutsceneSlide.new()

	slide4.image = preload(
		"res://assets/cutscene/voyage.png"
	)

	slide4.text = (
		"Accompagnez les deux animaux les plus intelligents "
		+ "du royaume dans ce nouveau voyage..."
	)

	slide4.duration = 5.0

	default_slides.append(slide4)


	return default_slides

func _on_skip_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Game/map_scene.tscn")
