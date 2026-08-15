class_name MapData
extends RefCounted

## Représente les données brutes d'une carte, telles que lues depuis un
## fichier map.txt (format imposé par le GDD AlgoGames 2).
##
## Format attendu :
##   Ligne 1        : H W time_limit
##   Lignes 2..H+1  : W caractères ASCII (voir légende du GDD)

var height: int = 0
var width: int = 0
var time_limit: int = 0
var grid: Array = []

static func load_from_file(path: String) -> MapData:
	if not FileAccess.file_exists(path):
		push_error("MapData: fichier introuvable -> %s" % path)
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("MapData: impossible d'ouvrir le fichier -> %s" % path)
		return null

	var map_data := MapData.new()

	var header_line := file.get_line().strip_edges()
	var header_parts := header_line.split(" ", false)

	if header_parts.size() < 3:
		push_error("MapData: en-tête invalide, attendu 'H W time_limit' -> '%s'" % header_line)
		file.close()
		return null

	map_data.height = int(header_parts[0])
	map_data.width = int(header_parts[1])
	map_data.time_limit = int(header_parts[2])

	for y in range(map_data.height):
		if file.eof_reached():
			push_error("MapData: fichier trop court, ligne %d manquante" % y)
			break

		var line := file.get_line()
		var row: Array = []

		for x in range(map_data.width):
			if x < line.length():
				row.append(line[x])
			else:
				push_warning("MapData: ligne %d trop courte, complétée avec '.'" % y)
				row.append(".")

		map_data.grid.append(row)

	file.close()

	if not map_data.is_valid():
		push_error("MapData: la carte chargée est invalide")
		return null

	return map_data


func is_valid() -> bool:
	if height <= 0 or width <= 0:
		return false
	if grid.size() != height:
		return false
	for row in grid:
		if row.size() != width:
			return false
	return true


func get_char(x: int, y: int) -> String:
	if y < 0 or y >= height or x < 0 or x >= width:
		return "."
	return grid[y][x]


func print_map() -> void:
	print("Carte %dx%d - temps limite: %d" % [width, height, time_limit])
	for row in grid:
		var line := ""
		for c in row:
			line += c
		print(line)
