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

@export_group("Audio")
@onready var audio_player: AudioStreamPlayer3D = $SFX_Open
## Minimum pitch (slow movement)
@export var min_pitch : float = 0.6 
## Maximum pitch (fast movement)
@export var max_pitch : float = 1.2 

# --- AUTOCLOSE VARIABLES ---
@export_group("Auto Close")
@export var slow_close_force := 5.0
@export var fast_close_force := 25.0
@export var fast_close_delay := 3.0

var release_time := 0.0
# --- INTERNAL VARIABLES ---
@onready var hinge: Node3D = $Hinge
@onready var Lock_sprite: Sprite3D = $Sprite3D

var current_angle : float = 0.0
var target_angle : float = 0.0
var door_velocity : float = 0.0
var is_being_dragged : bool = false

func _ready() -> void:
	# Initialize rotation
	current_angle = hinge.rotation_degrees.y
	target_angle = current_angle

func start_drag(player_node):
	if door_lock:
		Lock_sprite.visible = false;
		return;
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

	
	# 2. MOMENTUM (Optional Polish)
	# If released, the target angle stays where it is, 
	# effectively stopping the door with friction.
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
