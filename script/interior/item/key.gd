extends Node3D

@export var preview_scene : PackedScene
@export var item_id := "Rusty key"
@export var item_des := "Cold to the touch. Covered in grime.
Judging by the rust, it’s been here for years."

func interact(player):
	InspectionManager.start_inspection(self, preview_scene)

func on_picked():
	queue_free()
