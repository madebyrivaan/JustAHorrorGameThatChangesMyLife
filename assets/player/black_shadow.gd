extends Node3D

@onready var player = get_tree().get_nodes_in_group("player")[0]
@onready var lighting = get_tree().get_nodes_in_group("lighting")[0]


func start_run(source):
	source.force_open_fast()
	source.Auto_close_disabled(15)
	
	player.freeze_player(1.2)

	# ---------- STEP 1 (far) ----------
	visible = true
	await get_tree().create_timer(0.12).timeout
	lighting.force_thunder(true)
	visible = false

	await get_tree().create_timer(0.25).timeout
	player.playJumscare1()

	# ---------- STEP 2 ----------
	position.z = 1
	rotation_degrees.z = 5
	player.add_shake(1.5,0.3)
	visible = true
	await get_tree().create_timer(0.12).timeout
	visible = false

	await get_tree().create_timer(0.22).timeout


	# ---------- STEP 3 ----------
	position.z += 1.0

	rotation_degrees.z = -5

	visible = true
	player.add_shake(1.5,0.3)
	await get_tree().create_timer(0.10).timeout
	source.break_door()
	visible = false
	

	player.AdjustRainSound()
	player.AfterVoiceEffect()
	player.trigger_peripheral_collapse()
