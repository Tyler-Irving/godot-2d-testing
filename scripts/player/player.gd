extends CharacterBody2D
## Player controller — handles movement and camera.
##
## KEY GODOT CONCEPTS:
## - CharacterBody2D: A physics body designed for player-controlled characters.
##   It has built-in collision detection and a `velocity` property.
## - _physics_process(): Called every physics frame (default 60fps). Use this
##   for movement so speed is consistent regardless of rendering framerate.
## - @export: Makes a variable editable in the Godot Inspector panel, so you
##   can tweak values without changing code.
## - @onready: Initializes the variable after the node enters the scene tree.
##   It's shorthand for assigning in _ready(). Use it to grab child node refs.

## Movement speed in pixels per second. Exported so you can tweak in the editor.
@export var speed: float = 200.0

## References to child nodes. The $ syntax is shorthand for get_node().
## $Sprite2D is the same as get_node("Sprite2D").
@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	_create_player_sprite()


func _create_player_sprite() -> void:
	## Build a simple 32x32 colored square as the player's visual.
	## We use Godot's Image class to create pixel data, then convert
	## it to an ImageTexture that Sprite2D can display.
	var size := 32
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)

	# Bright coral/red so the player stands out against the terrain
	var body_color := Color(0.85, 0.25, 0.25)
	var outline_color := Color(0.55, 0.12, 0.12)

	for x in range(size):
		for y in range(size):
			# 2px outline on all edges for visibility
			if x < 2 or x >= size - 2 or y < 2 or y >= size - 2:
				img.set_pixel(x, y, outline_color)
			else:
				img.set_pixel(x, y, body_color)

	# Add a small "eye" detail so you can tell which way is "up"
	# (two white dots near the top)
	for dx in [10, 20]:
		for dy in [8, 9]:
			img.set_pixel(dx, dy, Color.WHITE)

	sprite.texture = ImageTexture.create_from_image(img)


func _physics_process(_delta: float) -> void:
	## Input.get_axis() returns a value from -1.0 to 1.0 based on the two
	## opposing actions. If "move_left" is pressed it returns -1, if
	## "move_right" is pressed it returns 1, if neither or both: 0.
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	# Normalize so diagonal movement isn't ~41% faster than cardinal.
	# Without this, pressing W+D gives Vector2(1,−1) with length 1.414.
	if direction.length() > 0.0:
		direction = direction.normalized()

	# `velocity` is a built-in CharacterBody2D property (Vector2).
	velocity = direction * speed

	# move_and_slide() moves the body by `velocity`, automatically handling
	# collisions by "sliding" along surfaces. It also adjusts velocity based
	# on collisions so the character doesn't clip through walls.
	move_and_slide()
