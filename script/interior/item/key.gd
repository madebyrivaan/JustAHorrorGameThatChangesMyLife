extends StaticBody3D

@export var item_id := "key"
@export var preview_scene : PackedScene

func interact(player):
	InspectionManager.start_inspection(self, preview_scene)
