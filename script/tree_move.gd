extends Node3D

@export var base_sway_amount := 2.0
@export var base_sway_speed := 0.5
@export var max_distance := 28.0

var t := 0.0
var random_offset := 0.0

var sway_amount := 0.0
var sway_speed := 0.0

# wind smoothing
var current_gust := 1.0
var target_gust := 1.0
var gust_timer := 0.0
var rest_timer := 0.0

func _ready():
	random_offset = randf() * TAU

	sway_speed = base_sway_speed * randf_range(0.75, 1.25)
	sway_amount = base_sway_amount * randf_range(0.7, 1.2)

	gust_timer = randf_range(2.5, 6.0)
	rest_timer = randf_range(3.0, 6.0)

func _process(delta):
	var cam := get_viewport().get_camera_3d()
	if cam and global_position.distance_to(cam.global_position) > max_distance:
		return

	t += delta * sway_speed

	# timers
	gust_timer -= delta
	rest_timer -= delta

	# change target, NOT current
	if gust_timer <= 0.0:
		target_gust = randf_range(0.6, 1.3)
		gust_timer = randf_range(3.0, 6.0)

	if rest_timer <= 0.0:
		target_gust = randf_range(0.1, 0.4)
		rest_timer = randf_range(4.0, 7.0)

	# smooth blend (THIS FIXES GLITCH)
	current_gust = lerp(current_gust, target_gust, delta * 1.5)

	var sway = sin(t + random_offset) * sway_amount * current_gust
	var jitter = sin((t * 2.9) + random_offset) * 0.12

	rotation.z = deg_to_rad(sway + jitter)
