extends Node

var active_sequence : bool = false
var sequence_cooldown : float = 5.0
var last_sequence_time : float = -1000.0



func _ready() -> void:
	pass
func conditions_met(event_name:String) -> bool:
	# For prototype always allow
	return true


func evaluate_event(event_name:String, source):
	if active_sequence:
		return

	var now = Time.get_ticks_msec() / 1000.0
	if now - last_sequence_time < sequence_cooldown:
		return

	if !conditions_met(event_name):
		return

	await run_sequence(event_name, source)

func run_sequence(event_name:String, source):
	active_sequence = true

	match event_name:
		"DOOR_PHOTO_HALLWAY":
			await play_door_shadow_sequence(source)

	active_sequence = false
	last_sequence_time = Time.get_ticks_msec() / 1000.0
	GameManager.mark_sequence_done(event_name)


func play_door_shadow_sequence(source):
	source.force_open_fast()
	source.force_close_fast()
	var scene = get_tree().current_scene
	var black_shadow = scene.get_node("coridoor/gameplay/GhostStart/black_shadow")

	black_shadow.visible = true
	black_shadow.start_run()
