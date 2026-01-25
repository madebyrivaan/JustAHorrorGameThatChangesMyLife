extends Node3D

@onready var light: DirectionalLight3D = $DirectionalLight3D
@onready var thunder_audio: AudioStreamPlayer3D = $ThunderAudio

@export var Thunder_activate := false
@export var OffThunder := false

# --- TUNING ---
@export var min_wait := 8.0
@export var max_wait := 16.0

@export var light_only_chance := 0.65
@export var light_with_sound_chance := 0.15

# --- DEBUG COUNTERS ---
var total_cycles := 0
var light_only_count := 0
var light_sound_count := 0
var nothing_count := 0

func trigger_lightning(strong := false):
	var flashes = randi_range(2, 4)

	for i in range(flashes):
		light.light_energy = randf_range(0.5, 0.9) if strong else randf_range(0.25, 0.45)

		await get_tree().create_timer(0.04).timeout
		light.light_energy = 0.0
		await get_tree().create_timer(0.06).timeout


func trigger_thunder():
	var delay = randf_range(1.6, 2.8)
	await get_tree().create_timer(delay).timeout

	thunder_audio.volume_db = randf_range(10.0, 16.0)
	thunder_audio.play()


func print_stats():
	print("---- THUNDER STATS ----")
	print("Total cycles: ", total_cycles)
	print("Light only: ", light_only_count,
		" (", float(light_only_count) / total_cycles * 100.0, "% )")
	print("Light + sound: ", light_sound_count,
		" (", float(light_sound_count) / total_cycles * 100.0, "% )")
	print("Nothing: ", nothing_count,
		" (", float(nothing_count) / total_cycles * 100.0, "% )")
	print("-----------------------")


func _ready():
	randomize()
	print("Thunder started: ", self.get_instance_id())

	if thunder_audio.stream:
		thunder_audio.stream.loop = false

	if OffThunder:
		return

	if Thunder_activate:
		await trigger_lightning(true)
		await trigger_thunder()
		return

	while true:
		await get_tree().create_timer(randf_range(min_wait, max_wait)).timeout

		total_cycles += 1
		var roll = randf()

		print("🎲 Roll:", roll)

		if roll < light_only_chance:
			light_only_count += 1
			print("⚡ EVENT: LIGHT ONLY")
			await trigger_lightning(false)

		elif roll < light_only_chance + light_with_sound_chance:
			light_sound_count += 1
			print("⚡🔊 EVENT: LIGHT + THUNDER")
			await trigger_lightning(true)
			await trigger_thunder()

		else:
			nothing_count += 1
			print("🌑 EVENT: NOT")
