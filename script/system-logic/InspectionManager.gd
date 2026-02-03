extends Node

var inspecting := false
var original_item : Node3D
var inspection_scene : Node

func start_inspection(item:Node3D, preview_scene:PackedScene):
	if inspecting:
		return
	original_item = item
	if original_item.has_method("freeze_for_inspection"):
		original_item.freeze_for_inspection()

	inspecting = true
	original_item = item

	# Blur world
	get_tree().call_group("player", "set_input_locked", true)
	get_tree().call_group("world_env", "enable_blur", true)

	# Dark overlay
	get_tree().call_group("inspection_ui", "show_overlay", true)

	# Load inspection scene
	inspection_scene = preload("res://system/inspector/inspection_scene.tscn").instantiate()
	get_tree().current_scene.add_child(inspection_scene)

	inspection_scene.spawn_preview(preview_scene)


func pickup():
	Inventory.add_item(original_item.item_id)
	original_item.queue_free()
	close()

func cancel():
	close()

func close():
	inspecting = false

	get_tree().call_group("world_env", "enable_blur", false)
	get_tree().call_group("inspection_ui", "show_overlay", false)
	get_tree().call_group("player", "set_input_locked", false)
	if inspection_scene:
		inspection_scene.queue_free()

	original_item = null
