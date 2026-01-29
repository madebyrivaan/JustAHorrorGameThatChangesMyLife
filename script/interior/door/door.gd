extends Node3D

@onready var hinge: Node3D = $Hinge


@onready var creak := $SFX_Open

@export var auto_close_force := 7.0
var dragging := false
var door_angle := 0.0
var prev_mouse := Vector2.ZERO
@export var slow_close_force := 5.0
@export var fast_close_force := 20.0
@export var fast_close_delay := 3.5

var release_time := 0.0

@export var open_limit := 95.0
@export var close_limit := 0.0
@export var drag_speed := 0.08

# Premium feel
@export var edge_resistance := 0.4
@export var stop_snap := 2.0
@export var micro_shake := 0.15

func interact(player_pos):
	if dragging:
		return
	dragging = true
	prev_mouse = get_viewport().get_mouse_position()

func _process(delta):

	# DRAGGING
	if dragging and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):

		var motion := Input.get_last_mouse_velocity().x

		var edge: float = inverse_lerp(close_limit, open_limit, door_angle)
		var resistance: float = lerp(1.0, edge_resistance, abs(edge - 0.5) * 2.0)

		door_angle += -motion * drag_speed * delta * resistance
		door_angle = clamp(door_angle, close_limit, open_limit)

		var shake: float = sin(float(Time.get_ticks_msec()) * 0.02) * micro_shake
		hinge.rotation_degrees.z = -(door_angle + shake)

		if not creak.playing:
			creak.play()

	# RELEASE
	elif dragging:
		door_angle = snapped(door_angle, stop_snap)
		dragging = false
		release_time = Time.get_ticks_msec() / 1000.0
		creak.stop()

	# AUTO CLOSE (always runs)
	if not dragging and door_angle > close_limit:

		var now := Time.get_ticks_msec() / 1000.0
		var elapsed := now - release_time

		var force := slow_close_force
		if elapsed > fast_close_delay:
			force = fast_close_force

		door_angle = move_toward(door_angle, close_limit, force * delta)
		hinge.rotation_degrees.z = -door_angle
