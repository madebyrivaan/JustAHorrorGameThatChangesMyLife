extends Node3D

@onready var camera_model: Node3D = $camera
@onready var initialize: AudioStreamPlayer3D = $camera/Sketchfab_model/audio/initialize
@onready var clicked: AudioStreamPlayer3D = $camera/Sketchfab_model/audio/clicked
@onready var anim: AnimationPlayer = $camera/Sketchfab_model/AnimationPlayer
@onready var camera_light: SpotLight3D = $camera/Sketchfab_model/SpotLight3D
var screen_material : ShaderMaterial
@onready var screen_mesh: MeshInstance3D = $camera/Sketchfab_model/ScreenMesh
@onready var main_cam: Camera3D = $Camera3D
var has_booted_once := false

var normal_fov := 56.8
var camera_fov := 42.0
var breath_time := 0.0

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
uniform sampler2D logo_tex;

uniform float boot_progress = 1.0; // 0 = off, 1 = ready
uniform float distortion = 0.18;
uniform float vignette_strength = 0.75;
uniform float grain_strength = 0.07;
uniform float aberration = 0.004;

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {

    vec2 uv = UV;
    vec3 final_col;

    // ======================
    // BOOT MODE
    // ======================
    if (boot_progress < 1.0) {

        float noise = rand(uv * TIME * 15.0);
        vec3 col = vec3(noise * 0.4);

        vec4 logo = texture(logo_tex, uv);
        float fade = smoothstep(0.2, 0.8, boot_progress);
        col = mix(col, logo.rgb, logo.a * fade);

        float roll = sin(uv.y * 40.0 + TIME * 8.0) * 0.02;
        col *= 1.0 - abs(roll);

        if (rand(vec2(TIME, uv.y)) > 0.995) {
            col = vec3(1.0);
        }

        final_col = col;

    } else {

        // ======================
        // NORMAL CAMERA MODE
        // ======================

        vec2 centered = uv - 0.5;
        float dist = dot(centered, centered);

        float vertical_wave = sin(uv.y * 15.0 + TIME * 2.0) * 0.003;
        uv.x += vertical_wave;

        uv += centered * dist * distortion;

        vec2 offset = centered * aberration;

        float r = texture(screen_tex, uv + offset).r;
        float g = texture(screen_tex, uv).g;
        float b = texture(screen_tex, uv - offset).b;

        vec3 col = vec3(r,g,b);

        col = (col - 0.5) * 1.5 + 0.5 - 0.08;

        float lum = dot(col, vec3(0.299,0.587,0.114));
        col = mix(col, vec3(lum), 0.35);

        float vig = smoothstep(0.3, 0.85, length(centered));
        col *= 1.0 - vig * vignette_strength;

        col += (rand(uv * TIME) - 0.5) * grain_strength;

        col = pow(col, vec3(1.15));

        final_col = col;
    }

    ALBEDO = clamp(final_col, 0.0, 1.0);
}



	"""
	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader

	screen_material = shader_mat
	screen_mesh.material_override = screen_material

	# Now assign logo AFTER material exists
	var logo = load("res://icons/sony-white-logo-image-png-701751694773074woruxayxst-removebg-preview.png")
	screen_material.set_shader_parameter("logo_tex", logo)

	# Start in boot mode
	screen_material.set_shader_parameter("boot_progress", 0.0)
	

	camera_model.visible = true   # 👈 ADD THIS
	# Run boot sequence for 2 seconds
	await start_boot_sequence(2.0)
	camera_model.visible = false

func set_camera_state(active: bool):
	if is_camera_up == active:
		return  # prevent spam calls

	is_camera_up = active

	if active:
		camera_model.visible = true
		initialize.play()

		var boot_time := 2.0
		if has_booted_once:
			boot_time = 0.25

		start_boot_sequence(boot_time)
		has_booted_once = true


func flash():
	if !is_camera_up or !can_flash:
		return
	
	can_flash = false
	
	anim.play("camera_button_clicked")
	clicked.play();
	
	
	# Disable layer 2 temporarily
	main_cam.cull_mask &= ~(1 << 1)  # layer index starts at 0, so layer 2 = index 1

	# TAKE SCREENSHOT
	
	camera_light.light_energy = 20.0

	await get_tree().process_frame   # let engine render one frame with reduced volumetric
	await get_tree().create_timer(0.02).timeout

	# TAKE SCREENSHOT HERE (no volumetric changes needed)
	camera_light.visible = true
	# PHASE 2 — Glow Fade (0.1 sec)
	camera_light.light_energy = 12.0
	await get_tree().create_timer(0.1).timeout
	var img = get_viewport().get_texture().get_image()
	img.resize(800, 450, Image.INTERPOLATE_NEAREST)
	
	main_cam.cull_mask |= (1 << 1)


	var tex = ImageTexture.create_from_image(img)
	screen_material.set_shader_parameter("screen_tex", tex)
	trigger_photo_reaction()
	
	# PHASE 1 — Hard Shock (0.05 sec)
	camera_light.light_energy = 20.0
	await get_tree().create_timer(0.05).timeout
	
	
	# OFF
	camera_light.visible = false
	
	# Restore layer
	await get_tree().create_timer(0.15).timeout
	can_flash = true
	
func _process(delta):
	breath_time += delta
	if is_camera_up:
		var breath_offset = sin(breath_time * 1.5) * 0.2
		main_cam.rotation_degrees.z += breath_offset * delta

	var target_y = raised_y if is_camera_up else lowered_y
	var target_rot = -8.0 if is_camera_up else 0.0
	var target_fov = camera_fov if is_camera_up else normal_fov
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
	if !is_camera_up and abs(camera_model.position.y - lowered_y) < 0.01:
		camera_model.visible = false
		initialize.playing = false;
		
func start_boot_sequence(duration: float) -> void:
	_boot_async(duration)

func _boot_async(duration: float) -> void:
	screen_material.set_shader_parameter("screen_tex", null)
	screen_material.set_shader_parameter("boot_progress", 0.0)

	var t := 0.0
	while t < duration:
		t += get_process_delta_time()
		var progress = clamp(t / duration, 0.0, 1.0)
		screen_material.set_shader_parameter("boot_progress", progress)
		await get_tree().process_frame

	screen_material.set_shader_parameter("boot_progress", 1.0)

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
