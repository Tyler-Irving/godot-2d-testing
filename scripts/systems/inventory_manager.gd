extends Node
## Global inventory manager — autoload singleton.
##
## KEY GODOT CONCEPTS:
## - Autoload: A scene or script registered in Project Settings → Autoload.
##   Godot automatically instantiates it when the game starts and adds it to
##   the scene tree root. It persists across scene changes and is globally
##   accessible by name (e.g., InventoryManager.selected_slot).
## - Signals: Custom events that objects can emit. Other objects "connect" to
##   signals to react when they fire. This decouples systems — the emitter
##   doesn't need to know who's listening.
##
## For Phase 2: tracks which hotbar slot is selected and what block type
## each slot holds. Blocks are unlimited (no counts yet — that's Phase 3).

## Emitted when the player switches hotbar slots.
## Other nodes (like the Hotbar UI) connect to this to update their display.
signal selection_changed(slot_index: int)

const SLOT_COUNT := 5

## Currently selected hotbar slot (0-based index).
var selected_slot: int = 0

## What block type each slot holds. -1 means empty.
## Block type IDs match the TileSet atlas columns in world.gd.
## Phase 2: unlimited supply, no counts tracked yet.
var slot_block_types: Array[int] = [1, 2, 4, 5, -1]
# Slot 0 = Dirt (tile 1)
# Slot 1 = Stone (tile 2)
# Slot 2 = Wood (tile 4)
# Slot 3 = Sand (tile 5)
# Slot 4 = empty


func select_slot(index: int) -> void:
	if index < 0 or index >= SLOT_COUNT:
		return
	if index == selected_slot:
		return
	selected_slot = index
	selection_changed.emit(selected_slot)


func get_selected_block_type() -> int:
	## Returns the tile type ID of the currently selected slot, or -1 if empty.
	return slot_block_types[selected_slot]
