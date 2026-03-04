extends Node3D

# --- CONFIGURATION ---
@export_group("Settings")
@export var min_angle : float = 0.0
@export var max_angle : float = 90.0
## Door Locking System
@export var door_lock : bool = false;
## How heavy the door feels. Lower = Heavier lag.
@export var weight : float = 5.0 
## How much force to slam the door shut/open?
@export var inertia_dampening : float = 2.0 
## WHICH ROOM TO DISABLE/ENABLE?
@export var holder_room: NodePath
var room_node: Node = null
@export var open_angle := 5.0
@export var close_angle := 1.0
## Item Key If door is locked
@export var required_item_id: String = "Rusty key"
@export var unlock_sound: AudioStreamPlayer3D
#door type of unlock
enum UnlockType { KEY, PHOTO, NONE }
@export var unlock_type := UnlockType.KEY
@export var sequence_event_name : String = "DOOR_PHOTO_HALLWAY"


@export_group("Audio")
@onready var audio_player: AudioStreamPlayer3D = $SFX_Open
## Minimum pitch (slow movement)
@export var min_pitch : float = 0.6 
## Maximum pitch (fast movement)
@export var max_pitch : float = 1.2 
@onready var forse_close: AudioStreamPlayer3D = $"../Door8/ForseClose"

# --- AUTOCLOSE VARIABLES ---
@export_group("Auto Close")
@export var slow_close_force := 5.0
@export var fast_close_force := 25.0
@export var fast_close_delay := 3.0

var release_time := 0.0


# --- INTERNAL VARIABLES ---
@onready var hinge: Node3D = $Hinge

var current_angle : float = 0.0
var target_angle : float = 0.0
var door_velocity : float = 0.0
var is_being_dragged : bool = false
#state
var is_door_open : bool

func _ready() -> void:
	# Initialize rotation
	if holder_room != NodePath("") and has_node(holder_room):
		room_node = get_node(holder_room)
	current_angle = hinge.rotation_degrees.y
	target_angle = current_angle
	
	# 🔑 INITIAL DOOR STATE SYNC
	is_door_open = current_angle > open_angle

	if room_node:
		room_node.door_open = is_door_open
		room_node.evaluate_state()

func start_drag(player_node):
	is_being_dragged = true
	# Start playing audio silently, we will modulate volume based on speed
	if !audio_player.playing:
		audio_player.play()
		audio_player.volume_db = -80

func end_drag():
	is_being_dragged = false
	release_time = Time.get_ticks_msec() / 1000.0


# Called by the Player script when mouse moves
func handle_drag(mouse_delta : Vector2):
	if door_lock:
		return;
	# We use X axis mouse movement. 
	# If you want dragging UP/DOWN to open the door, use mouse_delta.y
	# We multiply by sensitivity (ex: 200) to convert tiny mouse pixels to degrees
	var drag_force = mouse_delta.x * 200.0
	
	# Determine direction based on where player is standing? 
	# For now, let's assume dragging Right adds angle, Left removes it.
	target_angle += drag_force
	target_angle = clamp(target_angle, min_angle, max_angle)

func _physics_process(delta: float) -> void:
	if door_lock:
		return;
	# 1. PHYSICS INTERPOLATION (The AAA Feel)
	# Instead of setting rotation directly, we move "current" towards "target"
	# This creates that slight delay/weight feel.

	
	var smooth_speed = weight * delta
	
	# Calculate how fast the door is ACTUALLY moving this frame
	var previous_angle = current_angle
	current_angle = lerp(current_angle, target_angle, smooth_speed)
	
	# Calculate angular velocity for audio/physics
	var velocity_frame = (current_angle - previous_angle) / delta
	
	# Apply rotation to the Hinge (Assuming Y axis is up)
	hinge.rotation_degrees.z = current_angle
	
	# DOOR OPENS
	if is_door_open == false and current_angle > open_angle:
		is_door_open = true
		print("DOOR STATE: OPEN")

		if room_node:
			room_node.door_open = true
			room_node.evaluate_state()


	# DOOR CLOSES
	if is_door_open == true and current_angle < close_angle:
		is_door_open = false
		print("DOOR STATE: CLOSED")

		if room_node:
			print("IN-Room-Node-closed")
			room_node.door_open = false
			print("room_node_closed",room_node.door_open)
			room_node.evaluate_state()


	if !is_being_dragged:
		var now := Time.get_ticks_msec() / 1000.0
		var elapsed := now - release_time
		var force := slow_close_force
		if elapsed > fast_close_delay:
			force = fast_close_force
		target_angle = move_toward(target_angle, min_angle, force * delta)	

	# 3. DYNAMIC AUDIO
	process_audio(velocity_frame)

func process_audio(velocity : float):
	var abs_vel = abs(velocity)
	
	# If moving very slowly, fade out sound
	if abs_vel < 1.0:
		audio_player.volume_db = move_toward(audio_player.volume_db, -80.0, 2.0)
	else:
		# Map velocity to volume (Max volume 0dB, Min volume -20dB)
		var target_vol = linear_to_db(clamp(abs_vel / 50.0, 0.0, 1.0))
		audio_player.volume_db = move_toward(audio_player.volume_db, target_vol, 5.0)
		
		# Map velocity to pitch
		var target_pitch = lerp(min_pitch, max_pitch, clamp(abs_vel / 100.0, 0.0, 1.0))
		audio_player.pitch_scale = move_toward(audio_player.pitch_scale, target_pitch, 0.1)

# Utility for math conversion
func linear_to_db(lin):
	return 20.0 * log(max(lin, 0.0001)) / log(10.0)


func try_use_item(item_data: Dictionary) -> bool:
	if item_data.is_empty():
		print("❌ No item selected")
		return false
	
	print("Trying to use:", item_data["id"], "on door")
	
	if item_data["id"] == required_item_id:
		door_lock = false
		if unlock_sound:
			print("sound played")
			unlock_sound.play()
			
		target_angle = clamp(current_angle + 13, min_angle, max_angle)
		print("✅ Door Unlocked")
		return true
	else:
		print("❌ Wrong item for this door")
		return false

func on_photo_taken():
	if unlock_type != UnlockType.PHOTO:
		return
	
	if !door_lock:
		return


	print("📸 Photo triggered door!")

	GameManager.request_event(sequence_event_name, self)

func force_open_fast():
	door_lock = false
	audio_player.play()
	target_angle = clamp(current_angle + 90.0, min_angle, max_angle)

func force_close_fast():
	await get_tree().create_timer(0.4).timeout
	target_angle = clamp(current_angle - 85.0, min_angle, max_angle)
	await get_tree().create_timer(1).timeout
	forse_close.play()
