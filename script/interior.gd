extends Node3D

@onready var spawn_point: Marker3D = $SpawnPoint
@onready var blur_rect: ColorRect = $CanvasLayerBlur/BlurRect

func _ready():
	blur_rect.visible = false
	blur_rect.process_mode = Node.PROCESS_MODE_DISABLED
	spawn_player()
	

func _unhandled_input(event):

	if Input.is_action_just_pressed("ui_page_up"):
		var d = get_tree().get_first_node_in_group("doors")
		if d:
			print("Manual unlock test")
			d.try_use_item({
				"id": "Rusty key"
			})



func spawn_player():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	player.global_transform = spawn_point.global_transform

func enable_blur():
	blur_rect.process_mode = Node.PROCESS_MODE_INHERIT
	blur_rect.visible = true

func disable_blur():
	blur_rect.visible = false
	blur_rect.process_mode = Node.PROCESS_MODE_DISABLED
