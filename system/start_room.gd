extends Node3D

@export var content_path: NodePath
@onready var content: Node3D = get_node(content_path)

var door_open := true
var player_inside := false
var is_enabled := false
var is_ready := false   # 🔑 important

func _ready():
	if content_path != NodePath("") and has_node(content_path):
		content = get_node(content_path)
	else:
		push_error("CONTENT NODE NOT FOUND in " + name)
	is_enabled = content.visible
	is_ready = true
	evaluate_state()  # safe now
	
func evaluate_state():
	if !is_ready:
		return
	print("EVAL:", name, "door_open:", door_open, "player_inside:", player_inside)
	if !player_inside and !door_open:
		disable_room()
	else:
		enable_room()


func enable_room():
	if content == null:
		print("ERROR: content is null in", name)
		return
	if is_enabled:
		return
	is_enabled = true
	content.visible = true
	content.set_physics_process(true)
	content.set_process(true)
	for child in content.get_children():
		if child is CollisionShape3D:
			child.disabled = false
	print("ROOM ENABLED:", name)

func disable_room():
	if content == null:
		print("ERROR: content is null in", name)
		return
	if !is_enabled:
		return
	is_enabled = false
	content.visible = false
	content.set_physics_process(false)
	content.set_process(false)
	for child in content.get_children():
		if child is CollisionShape3D:
			child.disabled = true
	print("ROOM DISABLED:", name)


# --- Area3D ONLY SETS STATE ---
func _on_area_3d_body_entered(body):
		if body.is_in_group("player"):
			player_inside = true;
			evaluate_state()

func _on_area_3d_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
		evaluate_state()
