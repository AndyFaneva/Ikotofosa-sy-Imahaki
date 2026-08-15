extends Node

## Autoload (Singleton) — état global de la partie, accessible partout
## dans le projet via GameManager.xxx sans avoir à passer de référence.

## Chemin du fichier map.txt choisi (par le menu ou par le bouton "Charger")
var selected_map_path: String = ""

## Compteurs de score (à alimenter au fur et à mesure du développement)
var collected_stones: int = 0
var hidden_chests: int = 0
