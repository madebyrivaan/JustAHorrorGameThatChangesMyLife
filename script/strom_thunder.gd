extends Node3D

@onready var light: DirectionalLight3D = $LightningLight
@onready var env = $WorldEnvironment.environment
@onready var thunder_audio := $ThunderAudio
@export var Thunder_activate = false;
@export var OffThunder = false;
var base_fog_density := 0.1
var fog_flash_active := false

func trigger_lightning():
	var flashes = randi_range(2, 3)

	for i in range(flashes):
		light.light_energy = randf_range(8.0, 15.0)

		await lightning_fog_flash()

		await get_tree().create_timer(0.04).timeout
		light.light_energy = 0.0
		await get_tree().create_timer(0.05).timeout


func lightning_fog_flash():
	while fog_flash_active:
		await get_tree().process_frame

	fog_flash_active = true

	env.volumetric_fog_density = base_fog_density * 1
	await get_tree().create_timer(0.15).timeout

	var t := 0.0
	while t < 1.0:
		t += get_process_delta_time() * 4.0
		env.volumetric_fog_density = lerp(
			env.volumetric_fog_density,
			base_fog_density,
			t
		)
		await get_tree().process_frame

	env.volumetric_fog_density = base_fog_density
	fog_flash_active = false



func trigger_thunder():
	var delay = randf_range(1.2, 1.8)
	await get_tree().create_timer(delay).timeout
	thunder_audio.volume_db = randf_range(20.3,26.5)
	thunder_audio.play()



func _ready():
	if OffThunder:
		return;
		
	base_fog_density = env.volumetric_fog_density
	if Thunder_activate:
		await trigger_lightning();
		await get_tree().create_timer(randf_range(1.3,3.5)).timeout
		await trigger_thunder()
	else:
		while true:
			await get_tree().create_timer(randf_range(6, 15)).timeout
			if randf() < 0.8:
				await trigger_lightning()
			if randf() < 0.7:
				await trigger_thunder()
				
