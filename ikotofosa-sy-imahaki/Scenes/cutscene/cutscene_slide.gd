class_name CutsceneSlide
extends Resource

## Une slide du diaporama d'intro : une image (optionnelle) + un texte
## narratif + le temps d'affichage avant de passer à la suivante.

@export var image: Texture2D
@export_multiline var text: String = ""
@export var duration: float = 4.0
