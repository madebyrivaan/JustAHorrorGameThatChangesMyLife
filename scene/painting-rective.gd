extends CSGBox3D

@onready var player = get_tree().get_nodes_in_group("player")[0]


func on_photo_taken():
	print("painting-trigger")

	await get_tree().create_timer(0.05).timeout
	player.add_fov_punch(3, 1)

	await get_tree().create_timer(0.05).timeout
	player.add_shake(5 , 3)
	
	await get_tree().create_timer(0.05).timeout
	#player.freeze_player(0.4)
	player.trigger_peripheral_collapse()
	player.add_shake(0.2, 1)
	rotation_degrees.z += randf_range(-5, 5)
	position.y -= 0.05
	await get_tree().create_timer(0.05).timeout
	visible = false;
