extends Node2D
## Manages the game world: creates the TileSet, generates terrain, and
## paints tiles onto the TileMapLayer.
##
## KEY GODOT CONCEPTS:
## - TileMapLayer: A node that efficiently renders a grid of tiles from a
##   TileSet. In Godot 4.3+, each layer is its own node (replacing the old
##   multi-layer TileMap node). Great for tile-based games.
## - TileSet: A resource that defines what tiles are available — their textures,
##   collision shapes, and metadata. We build ours in code using an atlas.
## - TileSetAtlasSource: Defines tiles as regions within a single texture atlas.
##   Each tile is identified by its grid position in the atlas (e.g., (0,0) for
##   the first tile, (1,0) for the second, etc.).

const TILE_SIZE := 32
const WORLD_WIDTH := 64
const WORLD_HEIGHT := 64

## Tile type IDs — must match WorldGenerator constants and atlas column indices.
const TILE_GRASS := 0
const TILE_DIRT := 1
const TILE_STONE := 2
const TILE_WATER := 3

## Reference to the TileMapLayer child node where we paint terrain.
@onready var terrain_layer: TileMapLayer = $TerrainLayer

## Stores the tile type for every cell [x][y]. We keep this around so other
## systems (mining, placement) can query what's at a given position.
var world_data: Array = []


func _ready() -> void:
	_setup_tileset()
	_generate_world()


func _setup_tileset() -> void:
	## Build a TileSet entirely in code so we don't need external image files.
	## We create a small texture atlas (4 tiles in a row) with colored squares.
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# --- Create the atlas texture ---
	var num_tiles := 4
	var atlas_img := Image.create(
		TILE_SIZE * num_tiles, TILE_SIZE, false, Image.FORMAT_RGBA8
	)

	# Define the color palette for each terrain type
	var colors: Array[Color] = [
		Color(0.30, 0.65, 0.20),   # Grass — medium green
		Color(0.55, 0.36, 0.16),   # Dirt  — earthy brown
		Color(0.50, 0.50, 0.50),   # Stone — neutral gray
		Color(0.20, 0.40, 0.80),   # Water — deep blue
	]

	# Paint each tile in the atlas
	for tile_index in range(num_tiles):
		_paint_tile(atlas_img, tile_index, colors[tile_index])

	var atlas_texture := ImageTexture.create_from_image(atlas_img)

	# --- Set up the TileSetAtlasSource ---
	var source := TileSetAtlasSource.new()
	source.texture = atlas_texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Register each tile in the atlas. The atlas coordinate (i, 0) means
	# "column i, row 0" in the atlas grid.
	for i in range(num_tiles):
		source.create_tile(Vector2i(i, 0))

	# Add this source to the tileset with ID 0.
	# When placing tiles, we'll reference source_id=0.
	tileset.add_source(source, 0)

	# Assign the completed tileset to our TileMapLayer
	terrain_layer.tile_set = tileset


func _paint_tile(img: Image, tile_index: int, base_color: Color) -> void:
	## Paint a single tile region in the atlas image.
	## Adds subtle pixel variation and a thin border for visual clarity.
	var x_offset := tile_index * TILE_SIZE
	var border_color := base_color.darkened(0.25)

	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			var px := x_offset + x

			# 1px border on all edges so individual tiles are visible
			if x == 0 or x == TILE_SIZE - 1 or y == 0 or y == TILE_SIZE - 1:
				img.set_pixel(px, y, border_color)
			else:
				# Add very subtle per-pixel variation for a textured look.
				# sin-based hash gives deterministic "noise" from coordinates.
				var hash_val := sin(float(x) * 12.9898 + float(y) * 78.233) * 43758.5453
				var variation := (hash_val - floorf(hash_val) - 0.5) * 0.08
				var color := Color(
					clampf(base_color.r + variation, 0.0, 1.0),
					clampf(base_color.g + variation, 0.0, 1.0),
					clampf(base_color.b + variation, 0.0, 1.0),
				)
				img.set_pixel(px, y, color)


func _generate_world() -> void:
	## Use WorldGenerator to create terrain data, then paint it onto the tilemap.
	var generator := WorldGenerator.new(WORLD_WIDTH, WORLD_HEIGHT)
	world_data = generator.generate()

	for x in range(WORLD_WIDTH):
		for y in range(WORLD_HEIGHT):
			var tile_type: int = world_data[x][y]
			# set_cell() places a tile on the TileMapLayer:
			#   arg 1: grid coordinates (which cell)
			#   arg 2: source ID (which TileSetSource — we only have 0)
			#   arg 3: atlas coordinates (which tile within that source)
			terrain_layer.set_cell(
				Vector2i(x, y),
				0,
				Vector2i(tile_type, 0)
			)


## --- Public API for other systems (used in later phases) ---

func get_tile_type(grid_pos: Vector2i) -> int:
	## Returns the tile type at the given grid position, or -1 if out of bounds.
	if grid_pos.x < 0 or grid_pos.x >= WORLD_WIDTH:
		return -1
	if grid_pos.y < 0 or grid_pos.y >= WORLD_HEIGHT:
		return -1
	return world_data[grid_pos.x][grid_pos.y]


func world_to_grid(world_pos: Vector2) -> Vector2i:
	## Convert a world-space pixel position to a tile grid coordinate.
	## Useful for finding which tile the mouse or player is on.
	return Vector2i(
		int(world_pos.x) / TILE_SIZE,
		int(world_pos.y) / TILE_SIZE
	)
