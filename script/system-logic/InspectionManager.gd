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
	get_tree().call_group("interior", "enable_blur")

	# Load inspection scene
	inspection_scene = preload("res://system/inspector/inspection_scene.tscn").instantiate()
	get_tree().current_scene.add_child(inspection_scene)

	inspection_scene.spawn_preview(preview_scene , item)


func pickup():
	if original_item == null:
		return
		
	var data = {
		"id": original_item.item_id,
		"description": original_item.item_des,
		"preview_scene": original_item.preview_scene
	}
	
	Inventory.add_item(data)
	original_item.on_picked()
	close()


func cancel():
	close()

func close():
	inspecting = false
	get_tree().call_group("interior", "disable_blur")
	get_tree().call_group("player", "set_input_locked", false)
	if inspection_scene:
		inspection_scene.queue_free()

	original_item = null
