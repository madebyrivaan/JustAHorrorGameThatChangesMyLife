extends CanvasLayer

var manual_active := false
var idle_timer := 0.0

@export var auto_delay := 1.5   # seconds after last mouse move
@onready var item_holder: Node3D = $Control/SubViewportContainer/SubViewport/InspectionWorld/ItemHolder

@onready var name_text: RichTextLabel = $"Control/Control/Control/description&name/panel-object-guide/name"
@onready var description_text: RichTextLabel = $"Control/Control/Control/description&name/panel-object-guide/description"

func CreateContent(item:Node3D):
	name_text.text = item.item_id;
	description_text.text = item.item_des;
	
func spawn_preview(preview_scene: PackedScene , item : Node3D):
	for c in item_holder.get_children():
		c.queue_free()
	if preview_scene == null:
		push_error("❌ preview_scene is NULL. Assign it in item Inspector.")
		return
	print("DEBUG preview_scene =", preview_scene)
	if item.item_id == null and item.item_des == null:
		return
	CreateContent(item)
	
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
		item_holder.rotate_y(-event.relative.x * 0.01)
		item_holder.rotate_x(-event.relative.y * 0.01)

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
		item_holder.rotation.y += delta * 0.5
		item_holder.rotation.x = sin(Time.get_ticks_msec() * 0.001) * 0.2
