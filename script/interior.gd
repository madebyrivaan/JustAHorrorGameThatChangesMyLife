extends Node3D

@onready var spawn_point: Marker3D = $SpawnPoint

func _ready():
	spawn_player()
	

func spawn_player():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	player.global_transform = spawn_point.global_transform
