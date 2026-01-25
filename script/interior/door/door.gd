extends Node3D


@onready var auto_close_timer: Timer = $auto_close_timer
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var door_mesh: MeshInstance3D = $house_door
@onready var sfx_open: AudioStreamPlayer3D = $SFX_Open
@onready var sfx_close: AudioStreamPlayer3D = $SFX_Close

var door_busy := false
var is_open := false
var last_open_dir := 1   # 1 = forward (+X animation), -1 = backward (-X animation)
const AUTO_CLOSE_TIME := 4.5   # seconds (change for horror pacing)

const SIDE_THRESHOLD := 0.18
const DOT_FALLBACK_THRESHOLD := 0.15

func _ready():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		auto_close_timer.one_shot = true
		auto_close_timer.timeout.connect(_on_auto_close_timeout)
	if is_open:
		_close_door()
		return
		
func _play_sfx(player: AudioStreamPlayer3D):
	player.pitch_scale = randf_range(0.92, 1.05)
	player.volume_db = randf_range(-0.4, 6)
	player.play()


func interact(player_pos: Vector3) -> void:
	print("self",self)
	print("DOOR SIGNAL RECEIVED")

	# toggle close if already open
	if door_busy:
		print("DOOR BUSY – interaction ignored")
		return

	# 🔥 EXPLICIT DIRECTION USING MARKER
	var forward_dir = ( $Forward.global_position - global_position ).normalized()
	var to_player = ( player_pos - global_position ).normalized()

	var dot = forward_dir.dot(to_player)
	print("DOT:", dot)

	if dot > 0:
		# player is in FRONT of door
		anim.play("open_backward")
		last_open_dir = -1
		print("OPEN: backward (player in front)")
	else:
		# player is BEHIND door
		anim.play("open_forward")
		last_open_dir = 1
		print("OPEN: forward (player behind)")
	_play_sfx(sfx_open)
# 🔥 CUT OPEN SOUND AFTER ANIMATION
	await get_tree().create_timer(1.3).timeout
	sfx_open.stop()
	
	is_open = true
	door_busy = true   # 🔒 lock interaction
	auto_close_timer.start(AUTO_CLOSE_TIME)
	print("AUTO CLOSE TIMER STARTED")

func _close_door():
	if is_open:
		if last_open_dir == 1:
			anim.play("close_forward")
		else:
			anim.play("close_backward")
		_play_sfx(sfx_close)
	
	is_open = false
	await get_tree().create_timer(1.1).timeout
	door_busy = false   # 🔓 unlock interaction
	auto_close_timer.stop()

	print("DOOR CLOSED & UNLOCKED")
	
func _on_auto_close_timeout():
	print("AUTO CLOSE TRIGGERED")
	_close_door()
