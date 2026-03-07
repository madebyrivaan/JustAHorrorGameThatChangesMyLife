extends Node3D

@onready var camera_model: Node3D = $camera
@onready var initialize: AudioStreamPlayer3D = $camera/Sketchfab_model/audio/initialize
@onready var clicked: AudioStreamPlayer3D = $camera/Sketchfab_model/audio/clicked
@onready var anim: AnimationPlayer = $camera/Sketchfab_model/AnimationPlayer
@onready var camera_light: SpotLight3D = $camera/Sketchfab_model/SpotLight3D
var screen_material : ShaderMaterial
@onready var screen_mesh: MeshInstance3D = $camera/Sketchfab_model/ScreenMesh
@onready var main_cam: Camera3D = $Camera3D

var base_roll := 0.0
var breath_strength := 0.2
var breath_speed := 1.5
var normal_fov := 56.8
var camera_fov := 42.0
var breath_time := 0.0
var target_y := -0.3
var target_rot := 0.0
var target_fov := 56.8
var lowered_y := -0.3
var raised_y := 0.05

var raise_speed := 4.0
var lower_speed := 5.0

var is_camera_up := false
var can_flash := true   # prevents spam

func _ready():

	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D screen_tex;

uniform float distortion = 0.18;
uniform float vignette_strength = 0.75;
uniform float grain_strength = 0.12;
uniform float aberration = 0.004;

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898,78.233))) * 43758.5453);
}

void fragment(){

    vec2 uv = UV;

    // ---------- UV JITTER ----------
    float jitter = (rand(vec2(TIME, uv.y)) - 0.5) * 0.003;
    uv.x += jitter;

    // ---------- BARREL DISTORTION ----------
    vec2 centered = uv - 0.5;
    float dist = dot(centered, centered);
    uv += centered * dist * distortion;

    // ---------- CHROMATIC ABERRATION ----------
    vec2 offset = centered * aberration;

    vec3 col;
    col.r = texture(screen_tex, uv + offset).r;
    col.g = texture(screen_tex, uv).g;
    col.b = texture(screen_tex, uv - offset).b;

    // ---------- CONTRAST ----------
    col = (col - 0.5) * 1.4 + 0.5 - 0.06;

    // ---------- DESATURATION ----------
    float lum = dot(col, vec3(0.299,0.587,0.114));
    col = mix(col, vec3(lum), 0.35);

    // ---------- SCREEN FLICKER ----------
    float flicker = sin(TIME * 40.0) * 0.02;
    col += flicker;

    // ---------- SCANLINES ----------
    float scan = sin(UV.y * 900.0) * 0.03;
    col -= scan;

    // ---------- GRAIN ----------
    col += (rand(uv * TIME * 30.0) - 0.5) * grain_strength;

    // ---------- VIGNETTE ----------
    float vig = smoothstep(0.3, 0.85, length(centered));
    col *= 1.0 - vig * vignette_strength;
	// ---------- ROLLING CRT LINE ----------
float line_pos = mod(TIME * 0.5, 1.0);        // speed of line
float line = smoothstep(line_pos - 0.02, line_pos, uv.y) -
             smoothstep(line_pos, line_pos + 0.02, uv.y);

col += line * 0.25;
if(rand(vec2(TIME*2.0, uv.y)) > 0.998){
    col *= 0.2;
}ffffffffffffffffffffff
    // ---------- GAMMA ----------
    col = pow(col, vec3(1.1));

    ALBEDO = clamp(col, 0.0, 1.0);
}
	"""
	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader

	screen_material = shader_mat
	screen_mesh.material_override = screen_material
	camera_model.visible = false

func set_camera_state(active: bool):
	if is_camera_up == active:
		return

	is_camera_up = active

	if active:
		camera_model.visible = true
		initialize.play()

		target_y = raised_y
		target_rot = -8.0
		target_fov = camera_fov

	else:
		target_y = lowered_y
		target_rot = 0.0
		target_fov = normal_fov

func flash():
	if !is_camera_up or !can_flash:
		return

	can_flash = false

	anim.play("camera_button_clicked")
	clicked.play()

	main_cam.cull_mask &= ~(1 << 1)

	camera_light.light_energy = 20.0
	camera_light.visible = true

	await RenderingServer.frame_post_draw

	var img = get_viewport().get_texture().get_image()
	img.resize(800, 450, Image.INTERPOLATE_NEAREST)

	main_cam.cull_mask |= (1 << 1)

	var tex = ImageTexture.create_from_image(img)
	screen_material.set_shader_parameter("screen_tex", tex)

	trigger_photo_reaction()

	camera_light.light_energy = 12.0
	await get_tree().create_timer(0.05).timeout

	camera_light.visible = false

	await get_tree().create_timer(0.15).timeout
	can_flash = true

func _process(delta):
	breath_time += delta
	if is_camera_up:
		var breath_offset = sin(breath_time * breath_speed) * breath_strength
		breath_offset += sin(breath_time * breath_speed * 0.5) * breath_strength * 0.4
		main_cam.rotation_degrees.z = base_roll + breath_offset
	else:
		main_cam.rotation_degrees.z = lerp(main_cam.rotation_degrees.z, base_roll, delta * 6.0)

	var fov_speed = 10.0 if is_camera_up else 6.0
	main_cam.fov = lerp(main_cam.fov, target_fov, delta * fov_speed)

	
	camera_model.position.y = lerp(
		camera_model.position.y,
		target_y,
		delta * (raise_speed if is_camera_up else lower_speed)
	)

	camera_model.rotation_degrees.x = lerp(
		camera_model.rotation_degrees.x,
		target_rot,
		delta * 5.0
	)
# Hide only when fully lowered
	if !is_camera_up and camera_model.position.y <= lowered_y + 0.005:
		camera_model.visible = false
		if initialize.playing:
			initialize.stop()
		

func trigger_photo_reaction():
	var space_state = get_world_3d().direct_space_state
	
	var from = main_cam.global_transform.origin
	var to = from + -main_cam.global_transform.basis.z * 5.0

	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	if result:
		var collider = result.collider
		print("Hit:", result.collider)
		var node = collider

		while node:
			if node.has_method("on_photo_taken"):
				print("Photo target found:", node)
				node.on_photo_taken()
				break
			node = node.get_parent()
