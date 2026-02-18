extends CanvasLayer

var manual_active := false
var idle_timer := 0.0

@export var auto_delay := 1.5   # seconds after last mouse move
@onready var item_holder: Node3D = $Control/SubViewportContainer/SubViewport/InspectionWorld/ItemHolder

@onready var name_text: RichTextLabel = $"Control/Control/Control/description&name/panel-object-guide/name"
@onready var description_text: RichTextLabel = $"Control/Control/Control/description&name/panel-object-guide/description"
@onready var pivot: Node3D = $Control/SubViewportContainer/SubViewport/InspectionWorld/ItemHolder/pivot

func CreateContent(item:Node3D):
	name_text.text = item.item_id;
	description_text.text = item.item_des;
	
func spawn_preview(preview_scene: PackedScene , item : Node3D):
	for c in pivot.get_children():
		c.queue_free()
	pivot.rotation = Vector3.ZERO
	pivot.position = Vector3.ZERO

	if preview_scene == null:
		push_error("❌ preview_scene is NULL. Assign it in item Inspector.")
		return
	print("DEBUG preview_scene =", preview_scene)
	if item.item_id == null and item.item_des == null:
		return
	CreateContent(item)
	
	var preview = preview_scene.instantiate()
	pivot.add_child(preview)

	
	# 🔥 RESET EVERYTHING
	# Reset transform
	preview.transform = Transform3D.IDENTITY

	var mesh_instance : MeshInstance3D = null

	for child in preview.get_children():
		if child is MeshInstance3D:
			mesh_instance = child
			break

# If not found directly, search deeper
	if mesh_instance == null:
		mesh_instance = preview.find_child("", true, false) as MeshInstance3D

	if mesh_instance == null:
		push_error("❌ No MeshInstance3D found in preview scene.")
		return
	# Get mesh bounds
	var aabb = mesh_instance.get_aabb()
	var size = aabb.size
	var max_dim = max(size.x, size.y, size.z)

# Auto scale to fit nicely
	if max_dim > 0:
		var target_size = 1.5  # adjust if needed
		var scale_factor = target_size / max_dim
		preview.scale = Vector3.ONE * scale_factor

# Center the model inside pivot
	preview.position = -(aabb.position + size * 0.5)


func _unhandled_input(event):
	if !InspectionManager.inspecting:
		return
		
	#  ESC / Cancel
	if event.is_action_pressed("ui_cancel"):
		InspectionManager.cancel()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		InspectionManager.cancel()
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
		InspectionManager.pickup()

	if event is InputEventMouseMotion:
		manual_active = true
		idle_timer = 0.0
		pivot.rotate_y(-event.relative.x * 0.01)
		pivot.rotate_x(-event.relative.y * 0.01)

func _process(delta):
	if !InspectionManager.inspecting:
		return

	# Count idle time
	idle_timer += delta

	# After delay, allow auto rotate
	if idle_timer > auto_delay:
		manual_active = false

	# Auto rotate ONLY when not manually rotating
	if !manual_active:
		pivot.rotation.y += delta * 0.5
		pivot.rotation.x = sin(Time.get_ticks_msec() * 0.001) * 0.2
