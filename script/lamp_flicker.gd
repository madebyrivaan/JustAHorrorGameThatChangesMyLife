extends Node3D

@export var base_energy := 6.0
@export var min_energy := 2.0
@export var flicker_speed := 1.5

@export var fast_flicker := false   # 👻 ghost AI se toggle hoga
@export var max_distance := 30.0

# collect all lights automatically
@onready var lights: Array[Light3D] = []

var current_energy := 0.0
var target_energy := 0.0
var change_timer := 0.0

func _ready():
	# auto-detect all Light3D children (Spot + Omni)
	for child in get_children():
		if child is Light3D:
			lights.append(child)

	current_energy = base_energy
	target_energy = base_energy
	change_timer = randf_range(1.5, 4.0)

func _process(delta):
	var cam := get_viewport().get_camera_3d()
	if cam and global_position.distance_to(cam.global_position) > max_distance:
		return

	change_timer -= delta

	# decide when to change intensity
	if change_timer <= 0.0:
		if fast_flicker:
			# aggressive / panic flicker
			target_energy = randf_range(0.0, base_energy)
			change_timer = randf_range(0.05, 0.2)
		else:
			# normal unsettling flicker
			target_energy = randf_range(min_energy, base_energy)
			change_timer = randf_range(1.0, 3.5)

	# smooth transition (NO SNAP)
	current_energy = lerp(current_energy, target_energy, delta * flicker_speed)

	# apply to ALL lights
	for l in lights:
		l.light_energy = current_energy
