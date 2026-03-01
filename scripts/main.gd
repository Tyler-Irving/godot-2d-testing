extends Node2D
## Main scene script — wires up references between game systems.
##
## This is the "composition root" of the game. It connects the Player to the
## World so they can communicate. In Godot, sibling nodes can't easily find
## each other, so the parent scene is responsible for passing references.

@onready var world: Node2D = $World
@onready var player: CharacterBody2D = $Player


func _ready() -> void:
	# Give the player a reference to the world so it can query tiles,
	# place blocks, and show the cursor.
	player.world = world
