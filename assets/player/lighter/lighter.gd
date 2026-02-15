extends Node3D

@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var omni_light_3d: OmniLight3D = $OmniLight3D

var is_on: bool = false
var is_busy: bool = false

func _ready() -> void:
	sprite_3d.visible = false


func toggle_lighter():
	if is_busy:
		return
	
	if is_on:
		turn_off()
	else:
		turn_on()


func turn_on():
	is_busy = true
	omni_light_3d.visible = true
	sprite_3d.visible = true
	animation_player.play("lighter_open")
	is_on = true


func turn_off():
	is_busy = true
	omni_light_3d.visible = false
	sprite_3d.visible = false
	animation_player.play("lighter_close")
	is_on = false


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "lighter_off":
		sprite_3d.visible = false
	
	is_busy = false
