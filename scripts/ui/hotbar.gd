extends Control
## Hotbar UI — displays 5 block slots at the bottom of the screen.
##
## KEY GODOT CONCEPTS:
## - Control: The base class for all UI nodes. Unlike Node2D, Controls use a
##   layout system with anchors and offsets for responsive positioning.
## - Anchors: Values from 0.0 to 1.0 defining where a Control is positioned
##   relative to its parent. (0.5, 1.0) = bottom center of parent.
## - StyleBoxFlat: A drawable style for UI panels — lets you set background
##   color, border, and corner radius in code.
## - HBoxContainer: A container that arranges children in a horizontal row.

const SLOT_SIZE := 52
const SLOT_MARGIN := 4
const SLOT_COUNT := 5

## Colors for each block type (must match world.gd palette).
var block_colors := {
	1: Color(0.55, 0.36, 0.16),   # Dirt
	2: Color(0.50, 0.50, 0.50),   # Stone
	4: Color(0.65, 0.50, 0.30),   # Wood
	5: Color(0.85, 0.78, 0.45),   # Sand
}

var block_names := {
	1: "Dirt",
	2: "Stone",
	4: "Wood",
	5: "Sand",
}

var slot_panels: Array[Panel] = []


func _ready() -> void:
	# Let mouse events pass through the root Control to the game world.
	# Only the individual slot Panels will block clicks.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_hotbar()
	InventoryManager.selection_changed.connect(_on_selection_changed)
	_update_selection()


func _build_hotbar() -> void:
	## Create the hotbar layout: an HBoxContainer with 5 Panel slots.
	var total_width := SLOT_COUNT * (SLOT_SIZE + SLOT_MARGIN) - SLOT_MARGIN

	# Anchor to bottom-center of the viewport
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -total_width / 2.0
	offset_right = total_width / 2.0
	offset_top = -(SLOT_SIZE + 20)
	offset_bottom = -10

	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", SLOT_MARGIN)
	add_child(container)

	for i in range(SLOT_COUNT):
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		# Panels block mouse events so clicks don't pass to the game world
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		container.add_child(panel)
		slot_panels.append(panel)

		var block_type: int = InventoryManager.slot_block_types[i]

		# Block color preview square
		if block_type >= 0 and block_colors.has(block_type):
			var icon := ColorRect.new()
			icon.position = Vector2(10, 6)
			icon.size = Vector2(SLOT_SIZE - 20, SLOT_SIZE - 24)
			icon.color = block_colors[block_type]
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(icon)

		# Keyboard shortcut number (top-left corner)
		var key_label := Label.new()
		key_label.text = str(i + 1)
		key_label.position = Vector2(3, 1)
		key_label.add_theme_font_size_override("font_size", 11)
		key_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(key_label)

		# Block name label (bottom)
		if block_type >= 0 and block_names.has(block_type):
			var name_label := Label.new()
			name_label.text = block_names[block_type]
			name_label.position = Vector2(3, SLOT_SIZE - 16)
			name_label.add_theme_font_size_override("font_size", 9)
			name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(name_label)


func _unhandled_input(event: InputEvent) -> void:
	## Handle number keys 1-5 to switch hotbar slots.
	## _unhandled_input is used so other UI elements get first priority.
	if event is InputEventKey and event.pressed and not event.is_echo():
		# KEY_1 through KEY_5 are 49-53 (ASCII values of '1'-'5')
		if event.keycode >= KEY_1 and event.keycode <= KEY_5:
			InventoryManager.select_slot(event.keycode - KEY_1)
			get_viewport().set_input_as_handled()


func _on_selection_changed(_slot_index: int) -> void:
	_update_selection()


func _update_selection() -> void:
	## Update visual styles to highlight the selected slot.
	for i in range(SLOT_COUNT):
		var panel := slot_panels[i]
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(4)

		if i == InventoryManager.selected_slot:
			# Selected slot: bright yellow border
			style.bg_color = Color(0.22, 0.22, 0.22, 0.9)
			style.border_color = Color(1.0, 0.95, 0.3)
			style.set_border_width_all(3)
		else:
			# Unselected: dim border
			style.bg_color = Color(0.12, 0.12, 0.12, 0.75)
			style.border_color = Color(0.35, 0.35, 0.35, 0.6)
			style.set_border_width_all(1)

		panel.add_theme_stylebox_override("panel", style)
