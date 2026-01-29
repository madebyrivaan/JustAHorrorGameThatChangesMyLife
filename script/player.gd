extends CharacterBody3D

# --- CONFIGURATION ---
@export_group("Movement")
@export var speed_walk : float = 2.5
@export var speed_run : float = 4.5
@export var jump_force : float = 4.0
@export var gravity : float = 9.8

@export_group("Camera")
@export var mouse_sensitivity : float = 0.002
@export var mouse_interact_sensitivity : float = 0.0005 # Slower when opening doors

@export_group("Interaction")
@export var interaction_range : float = 2.5

# --- NODES ---
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/RayCast3D
@onready var reticle = get_tree().get_first_node_in_group("reticle")

# --- STATE ---
var mouse_captured : bool = false
# The object we are currently dragging
var current_interactable : Node = null 

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func _unhandled_input(event: InputEvent) -> void:
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
	# If we are dragging a door, FREEZE movement completely
	# --- RETICLE INTERACTION CHECK ---
	if reticle:
		if ray.is_colliding():
			var hit = ray.get_collider()
			var node = hit
			var found := false

			while node:
				if node.has_method("start_drag"):
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

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func try_begin_interaction():
	if ray.is_colliding():
		var hit = ray.get_collider()
		# Look for the physics body's parent or the node itself
		var node = hit
		while node:
			if node.has_method("start_drag"):
				
				current_interactable = node
				current_interactable.start_drag(self)
				return
			node = node.get_parent()

func end_interaction():
	if current_interactable:
		current_interactable.end_drag()
		current_interactable = null
