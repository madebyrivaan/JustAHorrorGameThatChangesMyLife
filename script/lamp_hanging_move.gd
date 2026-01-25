extends Node3D

@export var swing_amount := 6.0     # degrees (never > 8)
@export var swing_speed := 1.2
@export var max_distance := 25.0

var t := 0.0
var random_offset := 0.0

# smoothing
var current_swing := 0.0
var target_swing := 0.0

func _ready():
	random_offset = randf() * TAU
	swing_speed *= randf_range(0.8, 1.2)
	swing_amount *= randf_range(0.7, 1.1)

func _process(delta):
	var cam := get_viewport().get_camera_3d()
	if cam and global_position.distance_to(cam.global_position) > max_distance:
		return

	t += delta * swing_speed

	# pendulum motion (heavier than tree)
	target_swing = sin(t + random_offset) * swing_amount

	# smooth inertia (IMPORTANT)
	current_swing = lerp(current_swing, target_swing, delta * 2.0)

	rotation.x = deg_to_rad(current_swing)
