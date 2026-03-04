extends Node3D

@export var life_time : float = 2.0
@onready var anim: AnimationPlayer = $human/AnimationPlayer
@onready var player = get_tree().get_nodes_in_group("player")[0]
@onready var lighting = get_tree().get_nodes_in_group("lighting")[0]


func start_run():
	visible = true
	
	# 0.00s
	player.freeze_player(0.4)

	await get_tree().create_timer(0.05).timeout
	player.add_fov_punch(3, 1)

	await get_tree().create_timer(0.05).timeout
	player.add_shake(5.0 , 2.0)

	await get_tree().create_timer(0.05).timeout
	anim.play("mixamo_com")

	await get_tree().create_timer(0.08).timeout
	player.playJumscare1()

	await get_tree().create_timer(0.12).timeout
	lighting.force_thunder(true)
	
	await get_tree().create_timer(0.12).timeout
	player.AdjustRainSound()
	player.AfterVoiceEffect()
	await get_tree().create_timer(0.05).timeout
	player.trigger_peripheral_collapse()
	await get_tree().create_timer(life_time).timeout
	visible = false
	player.add_shake(0.2, 1)
