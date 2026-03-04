extends CharacterBody3D

# --- CONFIGURATION ---
@export_group("Movement")
@export var speed_walk : float = 2.5
@export var speed_run : float = 4.5
@export var jump_force : float = 2
@export var gravity : float = 9.8
@export var acceleration : float = 8.0
@export var deceleration : float = 10.0
@export var bob_frequency : float = 8.0
@export var bob_amplitude : float = 0.03
@export var idle_sway_frequency : float = 1.5
@export var idle_sway_amplitude : float = 0.01
@onready var footstep_cloth: AudioStreamPlayer3D = $audio/FootstepCloth
var bob_time : float = 0.0
var original_head_position : Vector3
var idle_time : float = 0.0
var mouse_moving_timer : float = 0.0
var step_impact_offset: float = 0.0

@export_group("Camera")
@export var mouse_sensitivity : float = 0.002
@export var mouse_interact_sensitivity : float = 0.0005 # Slower when opening doors

@export_group("Interaction")
@export var interaction_range : float = 2.5
var locked_target : Node = null

#---AUDIO---
@export_group("Audio")
#NEW CLEAN
@onready var footstep_concrete: AudioStreamPlayer3D = $audio/FootstepConcrete
@onready var footstep_hallway: AudioStreamPlayer3D = $audio/FootstepHallway
@onready var footstep_wood: AudioStreamPlayer3D = $audio/FootstepWood
@export var step_distance : float = 0.8
@onready var super_heavy_breath: AudioStreamPlayer3D = $audio/super_heavy_breath
@onready var calm_breath: AudioStreamPlayer3D = $audio/calm_breath
@onready var jumscare_1: AudioStreamPlayer3D = $"audio/jumscare-1"
@onready var rain_loop: AudioStreamPlayer3D = $audio/RainLoop
@onready var heart_beat: AudioStreamPlayer3D = $"audio/heart-beat"

var breath_stress : float = 0.0  # 0 = calm, 1 = exhausted
var step_accumulator : float = 0.0
var next_step_time : float = 0.35

@export_group("Trauma")

var trauma: float = 0.0
@export var trauma_decay: float = 0.9
@export var max_shake_rotation: float = 4.0 # degrees
@export var shake_noise_speed: float = 20.0
var shake_offset: Vector3 = Vector3.ZERO
var shake_time: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var shake_initial_strength: float = 0.0

@export_group("PLAYER FREEZE")
# --- PLAYER FREEZE ---
var freeze_timer: float = 0.0
var is_frozen: bool = false

# --- FOV PUNCH ---
var fov_punch_strength: float = 0.0
var fov_punch_duration: float = 0.0
var fov_punch_timer: float = 0.0
var base_fov: float = 0.0

# --- NODES ---
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/RayCast3D
@onready var reticle = get_tree().get_first_node_in_group("reticle")
@onready var interact_text: RichTextLabel = $"HUD/interact-text"
@onready var ground_ray: RayCast3D = $GroundRay
var input_locked := false
var new_text := ""

# --- STATE ---
var mouse_captured : bool = false
# The object we are currently dragging
var current_interactable : Node = null 
var current_pickup : Node = null

#effect
@onready var vignette: ColorRect = $ui/CanvasLayer/Vignette

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true
	original_head_position = head.position
	base_fov = camera.fov
	rain_loop.play();
	heart_beat.play();
	
func _unhandled_input(event: InputEvent) -> void:
	if input_locked:
		return
	if mouse_captured and event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event.is_action_pressed("interact") and current_pickup:
		if current_pickup.has_method("interact"):
			current_pickup.interact(self)
		current_pickup = null

	#if Inventory.has_item("camera"):
	if event.is_action_pressed("camera_key"):
		head.set_camera_state(true)

	if event.is_action_released("camera_key"):
		head.set_camera_state(false)

		
	if Input.is_action_pressed("camera_key") and Input.is_action_just_pressed("camera_click"):
		head.flash()
		
	if event is InputEventMouseButton:
		# Capture mouse if we clicked back into window
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if !mouse_captured:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				mouse_captured = true
				return
			
			# Start Interaction
			try_begin_interaction()
		
		# Release Interaction
		if event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
			end_interaction()

	# MOUSE MOTION
	if event is InputEventMouseMotion and mouse_captured:
		mouse_moving_timer = 0.2
		if current_interactable:
			# Pass the mouse movement TO THE DOOR instead of the camera
			# We multiply by a lower sensitivity to give it "weight"
			current_interactable.handle_drag(event.relative * mouse_interact_sensitivity)
		else:
			# Normal Camera Look
			rotate_y(-event.relative.x * mouse_sensitivity)
			head.rotate_x(-event.relative.y * mouse_sensitivity)
			
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))


			
func _physics_process(delta: float) -> void:
	#update camera shake
	update_camera_shake(delta)
	update_fov_punch(delta)
	# Handle freeze timer
	if is_frozen:
		freeze_timer -= delta
	
		velocity = Vector3.ZERO
		move_and_slide()
	
		if freeze_timer <= 0.0:
			is_frozen = false
	
		return
		
	if input_locked:
		reticle.set_interactable(false)
		current_interactable = null
		velocity = Vector3.ZERO
		move_and_slide()
		return

	new_text = ""
	current_pickup = null
	
	if ray.is_colliding():
		var hit = ray.get_collider()
		var node = hit

		while node:
			# PICKUP
			if node.has_method("interact"):
				new_text = "Press E To Pick Up"
				current_pickup = node
				break

			# DOOR
			if node.is_in_group("doors"):
				if node.door_lock:
					new_text = "It's locked , Press Tab To use items"
					locked_target = node
				else:
					new_text = "Hold Mouse To Open"
					locked_target = null
				break

			node = node.get_parent()

	interact_text.text = new_text
	
	# --- RETICLE INTERACTION CHECK ---
	if reticle:
		if ray.is_colliding():
			var hit = ray.get_collider()
			var node = hit
			var found := false

			while node:
				if node.is_in_group("doors"):
					found = true
					break
				node = node.get_parent()


			reticle.set_interactable(found)
		else:
			reticle.set_interactable(false)

	if current_interactable != null:
		velocity = Vector3.ZERO
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force

	# Movement
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var speed = speed_run if Input.is_action_pressed("sprint") else speed_walk

	var target_velocity = direction * speed

	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	if direction == Vector3.ZERO:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta)
	
	move_and_slide()


	var horizontal_speed = Vector3(velocity.x, 0, velocity.z).length()
	update_breath_state(delta, horizontal_speed)
# Decrease mouse timer
	mouse_moving_timer = max(mouse_moving_timer - delta, 0.0)

	if is_on_floor() and direction != Vector3.ZERO:
	# WALKING BOB
		var speed_ratio = clamp(horizontal_speed / speed_run, 0.0, 1.0)
		bob_time += delta * bob_frequency * (0.5 + speed_ratio)

		var bob_offset_y = sin(bob_time) * bob_amplitude
		var bob_offset_x = cos(bob_time * 0.5) * bob_amplitude * 0.5
		head.position.y = original_head_position.y + bob_offset_y
		head.position.x = original_head_position.x + bob_offset_x
		step_impact_offset = lerp(step_impact_offset, 0.0, 10 * delta)
		head.position.y += step_impact_offset
		
 	#audio
		step_accumulator += delta
		var current_step_distance = step_distance * randf_range(0.95, 1.05)
		if Input.is_action_pressed("sprint"):
			current_step_distance *= 0.7

		
		if step_accumulator >= next_step_time:
			step_accumulator = 0.0
	
		# Calculate next interval AFTER step
			next_step_time = randf_range(0.30, 0.45)
	
			if Input.is_action_pressed("sprint"):
				next_step_time *= 0.7

			step_impact_offset = -0.01
			play_smart_footstep(speed_ratio)

	
	elif is_on_floor() and horizontal_speed <= 0.1 and mouse_moving_timer <= 0.0:
		# IDLE SWAY
		idle_time += delta * idle_sway_frequency

		var idle_offset_y = sin(idle_time) * idle_sway_amplitude
		var idle_offset_x = cos(idle_time * 0.5) * idle_sway_amplitude * 0.5

		head.position.y = original_head_position.y + idle_offset_y
		head.position.x = original_head_position.x + idle_offset_x

	else:
		step_accumulator = 0.0
		head.position = head.position.lerp(original_head_position, 6 * delta)
	
	
func try_begin_interaction():
	if input_locked:
		return

	if not ray.is_colliding():
		return

	var hit = ray.get_collider()
	var node = hit

	while node:
		if node.is_in_group("doors"):
				current_interactable = node
				node.start_drag(self)
				return
		node = node.get_parent()

func end_interaction():
	if current_interactable:
		current_interactable.end_drag()
		current_interactable = null
		
func set_input_locked(value: bool) -> void:
	input_locked = value


func play_smart_footstep(speed_ratio: float):
	if randf() < 0.15:
		await get_tree().create_timer(randf_range(0.03, 0.09)).timeout
	if not ground_ray.is_colliding():
		return

	var collider = ground_ray.get_collider()
	var player : AudioStreamPlayer3D = null

	if collider.is_in_group("wood"):
		player = footstep_wood
	elif collider.is_in_group("concrete"):
		player = footstep_concrete
	elif collider.is_in_group("hallway"):
		player = footstep_hallway

	if player == null:
		return

	# 🎭 1. Weighted behavior selection
	var roll = randf()

	# --- 65% → Silence ---
	if roll < 0.15:
		return

	# --- 25% → Slow / Heavy Step ---
	elif roll < 0.90:
		player.pitch_scale = randf_range(0.75, 0.9)
		player.volume_db = lerp(-9.0, -3.0, speed_ratio) + randf_range(-3.0, 1.0)

	# --- 10% → Fast / Sharp Step (anomaly) ---
	else:
		player.pitch_scale = randf_range(1.05, 1.2)
		player.volume_db = lerp(-1.0, 8.0, speed_ratio) + randf_range(-1.0, 2.0)

	# 🎧 Slight stereo / realism randomness
	player.unit_size = randf_range(0.9, 1.1)

	if player.playing:
		player.stop()

	player.play()

func update_breath_state(delta: float, horizontal_speed: float):

	# Increase stress while sprinting
	if Input.is_action_pressed("sprint") and horizontal_speed > 0.1:
		breath_stress = clamp(breath_stress + delta * 0.6, 0.0, 1.0)
	else:
		# Recover slowly
		breath_stress = clamp(breath_stress - delta * 0.3, 0.0, 1.0)

	# Blend volumes
	calm_breath.volume_db = lerp(-35.0, -18.0, 1.0 - breath_stress)
	super_heavy_breath.volume_db = lerp(-40.0, -6.0, breath_stress)

	# Slight pitch variation
	calm_breath.pitch_scale = lerp(0.95, 1.05, breath_stress)
	super_heavy_breath.pitch_scale = lerp(0.9, 1.1, breath_stress)

	# Make sure both are playing
	if not calm_breath.playing:
		calm_breath.play()

	if not super_heavy_breath.playing:
		super_heavy_breath.play()

func add_shake(strength: float, duration: float, custom_decay: float = -1.0):
	print("shaked called", strength , duration)
	trauma = clamp(strength, 0.0, 1.0)
	shake_initial_strength = trauma
	
	shake_duration = duration
	shake_timer = 0.0
	
	if custom_decay > 0.0:
		trauma_decay = custom_decay
	
	shake_time = 0.0
	
func update_camera_shake(delta: float):

	head.rotation_degrees -= shake_offset
	shake_offset = Vector3.ZERO

	if trauma <= 0.0:
		return

	shake_time += delta * shake_noise_speed
	shake_timer += delta

	# Smooth fade based on duration
	var progress = clamp(shake_timer / shake_duration, 0.0, 1.0)
	var curve = 1.0 - pow(progress, 2.0)
	trauma = shake_initial_strength * curve

	var shake_amount = trauma * trauma

	var rot_x = sin(shake_time * 1.3) * max_shake_rotation * shake_amount
	var rot_y = sin(shake_time * 1.7 + 10.0) * max_shake_rotation * shake_amount
	var rot_z = sin(shake_time * 2.1 + 25.0) * max_shake_rotation * shake_amount * 0.5

	shake_offset = Vector3(rot_x, rot_y * 0.3, rot_z)
	head.rotation_degrees += shake_offset

func freeze_player(duration: float):
	is_frozen = true
	freeze_timer = duration

func add_fov_punch(strength: float, duration: float):
	fov_punch_strength = strength
	fov_punch_duration = duration
	fov_punch_timer = 0.0

func update_fov_punch(delta: float):

	if fov_punch_timer < fov_punch_duration:
		fov_punch_timer += delta
		
		var progress = clamp(fov_punch_timer / fov_punch_duration, 0.0, 1.0)
		
		# Fast peak then smooth return (AAA curve)
		var curve = sin(progress * PI)
		
		camera.fov = base_fov + fov_punch_strength * curve
	else:
		camera.fov = lerp(camera.fov, base_fov, 8.0 * delta)

func playJumscare1():
	jumscare_1.play()


var voice_tween : Tween

func AfterVoiceEffect():

	# Kill old tween if running
	if voice_tween:
		voice_tween.kill()

	voice_tween = create_tween()

	# --- BREATH PART ---
	super_heavy_breath.volume_db = -20
	super_heavy_breath.play()

	voice_tween.tween_property(super_heavy_breath, "volume_db", -6, 0.2)

	voice_tween.tween_interval(2.0)

	voice_tween.tween_property(super_heavy_breath, "volume_db", 10, 7)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)

	voice_tween.tween_property(super_heavy_breath, "volume_db", 0, 4.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	# --- HEARTBEAT SPIKE ---
	var spike_target = randf_range(6.0, 4.0)

	voice_tween.parallel().tween_property(heart_beat, "volume_db", spike_target, 0.15)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)
	voice_tween.tween_interval(7.0)
	voice_tween.tween_property(heart_beat, "volume_db", -8.0, 3.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	await voice_tween.finished
	super_heavy_breath.stop()
	
func AdjustRainSound():
	var tween = create_tween()
	
	# Immediately lower rain after jumpscare
	tween.tween_property(rain_loop, "volume_db", -40, 0.2)
	
	# Hold tension
	tween.tween_interval(2.0)
	
	# Slowly rise rain intensity
	tween.tween_property(rain_loop, "volume_db", 4, 7)\
	.set_trans(Tween.TRANS_EXPO)\
	.set_ease(Tween.EASE_OUT)
	
	# Then settle to ambience level
	var settle_target = randf_range(-22, -18)

	tween.tween_property(rain_loop, "volume_db", settle_target, 4.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

var vignette_tween : Tween

func trigger_peripheral_collapse():

	if vignette_tween:
		vignette_tween.kill()

	var mat = vignette.material
	vignette_tween = create_tween()
	vignette_tween.set_parallel(false)

	# 🔥 Shock phase (intensity + tighter collapse)
	vignette_tween.tween_property(
		mat,
		"shader_parameter/intensity",
		0.45,
		0.4
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	vignette_tween.parallel().tween_property(
		mat,
		"shader_parameter/softness",
		0.4,
		0.3
	)

	vignette_tween.parallel().tween_property(
		mat,
		"shader_parameter/roundness",
		0.5,
		0.3
	)

	# Slight release
	vignette_tween.tween_property(
		mat,
		"shader_parameter/intensity",
		0.3,
		0.12
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Fade back to normal
	vignette_tween.tween_property(
		mat,
		"shader_parameter/intensity",
		0.0,
		0.4
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	vignette_tween.parallel().tween_property(
		mat,
		"shader_parameter/softness",
		0.6,
		0.4
	)

	vignette_tween.parallel().tween_property(
		mat,
		"shader_parameter/roundness",
		1.2,
		0.4
	)
