extends Panel

@onready var list := $VBoxContainer

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event):
	if event.is_action_pressed("tab"):
		visible = !visible
		get_tree().paused = visible
		refresh()

		Input.set_mouse_mode(
			Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED
		)

func refresh():
	for c in list.get_children():
		c.queue_free()

	for item in Inventory.items:
		var label = Label.new()
		label.text = item
		list.add_child(label)
