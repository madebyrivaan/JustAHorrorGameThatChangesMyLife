extends Control

# --- SETTINGS ---
@export_group("Visuals")
@export var radius : float = 4.0
@export var thickness : float = 1.5
@export var reticle_color : Color = Color.WHITE
@export var opacity : float = 0.8

@export_group("Options")
@export var show_center_dot : bool = false
@export var segments : int = 32

# --- INTERACTION FEEL ---
@export_group("Interaction")
@export var interact_radius_boost := 3.0   # how much bigger when usable
@export var grow_speed := 10.0             # how fast it grows/shrinks

var base_radius : float
var target_radius : float

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	base_radius = radius
	target_radius = radius

func set_interactable(active: bool):
	if active:
		target_radius = base_radius + interact_radius_boost
	else:
		target_radius = base_radius

func _process(delta):
	# Smooth resize
	radius = lerp(radius, target_radius, grow_speed * delta)
	queue_redraw()

func _draw():
	draw_arc(Vector2.ZERO, radius + 1.0, 0, TAU, segments, Color(0, 0, 0, 0.5), thickness + 2.0)
	draw_arc(Vector2.ZERO, radius, 0, TAU, segments, reticle_color, thickness)

	if show_center_dot:
		draw_circle(Vector2.ZERO, 1.0, reticle_color)
