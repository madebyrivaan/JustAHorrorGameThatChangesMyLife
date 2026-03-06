extends Node3D

@onready var world_environment: WorldEnvironment = $"../../../env/WorldEnvironment"
@onready var directional_light_3d: DirectionalLight3D = $"content/white-window/DirectionalLight3D"


func _ready() -> void :
	directional_light_3d.visible = false
	world_environment.environment.volumetric_fog_enabled = false
		
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "player":
		directional_light_3d.visible = true
		world_environment.environment.volumetric_fog_enabled = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.name == "player":
		directional_light_3d.visible = false
		world_environment.environment.volumetric_fog_enabled = false
