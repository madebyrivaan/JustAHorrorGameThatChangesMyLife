extends Node3D

@export var idle_rotate = true
@onready var preview_holder: Node3D = $PreviewHolder

func _process(delta):

	if idle_rotate and preview_holder.get_child_count() > 0:
		var item = preview_holder.get_child(0)
		item.rotate_y(delta * 0.6)
