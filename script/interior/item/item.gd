extends Node3D

@export var preview_scene : PackedScene
@export var item_id := ""
@export var item_des := ""

func interact(player):
	InspectionManager.start_inspection(self, preview_scene)

func on_picked():
	queue_free()
