extends CanvasLayer

@onready var item_holder := $SubViewportContainer/SubViewport/InspectionWorld/ItemHolder

func spawn_preview(preview_scene: PackedScene):
	if preview_scene == null:
		push_error("❌ preview_scene is NULL. Assign it in item Inspector.")
		return
	print("DEBUG preview_scene =", preview_scene)

	var preview = preview_scene.instantiate()
	item_holder.add_child(preview)
	
	# 🔥 RESET EVERYTHING
	preview.transform = Transform3D.IDENTITY
	preview.rotation = Vector3.ZERO   # ⭐ MOST IMPORTANT

	# Optional scale
	preview.scale = Vector3.ONE * 0.15
	# Reset transform for clean cinematic look
	preview.transform = Transform3D.IDENTITY

func _unhandled_input(event):
	if !InspectionManager.inspecting:
		return
		
	# 🔴 ESC / Cancel
	if event.is_action_pressed("ui_cancel"):
		InspectionManager.cancel()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		InspectionManager.cancel()

	if event is InputEventMouseMotion:
		item_holder.rotate_y(-event.relative.x * 0.01)
		item_holder.rotate_x(-event.relative.y * 0.01)
