extends Node

var active_sequence : bool = false
var sequence_cooldown : float = 5.0
var last_sequence_time : float = -1000.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

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
	print("🔥 Running DOOR_PHOTO_HALLWAY sequence")

	# Force open
	source.force_open_fast()

	await get_tree().create_timer(0.5).timeout

	print("👻 Shadow ran in hallway")
