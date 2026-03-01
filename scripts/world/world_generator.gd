class_name WorldGenerator
extends RefCounted
## Procedural world generator using Godot's FastNoiseLite.
##
## KEY GODOT CONCEPTS:
## - class_name: Registers this script as a globally available type. Any other
##   script can use `WorldGenerator.new()` without needing to preload the file.
## - RefCounted: A lightweight base class for objects that don't need to be in
##   the scene tree. It auto-frees when nothing references it.
## - FastNoiseLite: Godot's built-in noise generator. Unlike rand(), noise
##   produces smooth, continuous values — nearby coordinates get similar values,
##   which creates natural-looking terrain clusters instead of random checkerboards.

## Tile type constants — used as IDs throughout the project.
## These match the atlas column index in the TileSet (see world.gd).
const TILE_GRASS := 0
const TILE_DIRT := 1
const TILE_STONE := 2
const TILE_WATER := 3

var world_width: int
var world_height: int
var noise: FastNoiseLite


func _init(width: int, height: int, world_seed: int = -1) -> void:
	world_width = width
	world_height = height
	_setup_noise(world_seed)


func _setup_noise(world_seed: int) -> void:
	noise = FastNoiseLite.new()

	# Simplex noise produces smooth, natural-looking patterns.
	# Unlike pure random values, neighboring coordinates get similar values,
	# which creates organic-looking blobs and clusters.
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	# Frequency controls the "zoom level" of the noise:
	#   Lower (0.01) = huge landmasses, very smooth transitions
	#   Higher (0.1)  = small scattered patches, more chaotic
	# 0.04 gives nice medium-sized terrain regions.
	noise.frequency = 0.04

	# Fractal settings add detail on top of the base pattern.
	# octaves=3 layers three noise patterns at different scales.
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3

	if world_seed >= 0:
		noise.seed = world_seed
	else:
		# randi() gives a random integer each run, so every world is unique
		noise.seed = randi()


func generate() -> Array:
	## Returns a 2D array [x][y] of tile type IDs.
	var tiles: Array = []
	for x in range(world_width):
		var column: Array = []
		for y in range(world_height):
			column.append(_get_tile_type(x, y))
		tiles.append(column)

	# Ensure the spawn area (center of world) is always walkable
	_clear_spawn_area(tiles)

	return tiles


func _get_tile_type(x: int, y: int) -> int:
	## Map a noise value to a terrain type.
	## FastNoiseLite.get_noise_2d() returns values roughly in [-1.0, 1.0].
	## We carve that range into bands, each assigned to a tile type.
	var value := noise.get_noise_2d(float(x), float(y))

	if value < -0.25:
		return TILE_WATER    # Low areas become water (~20% of map)
	elif value < 0.0:
		return TILE_DIRT     # Low-mid areas are dirt (~25%)
	elif value < 0.35:
		return TILE_GRASS    # Mid areas are grass (~35%, most common)
	else:
		return TILE_STONE    # High areas are stone (~20%)


func _clear_spawn_area(tiles: Array) -> void:
	## Make a small patch at the world center always grass,
	## so the player never spawns in water or on stone.
	var cx := world_width / 2
	var cy := world_height / 2
	for x in range(cx - 3, cx + 4):
		for y in range(cy - 3, cy + 4):
			if x >= 0 and x < world_width and y >= 0 and y < world_height:
				tiles[x][y] = TILE_GRASS
