extends Panel

@onready var list_root: Control = $HBoxContainer/list
@onready var preview = $HBoxContainer/preview/inspection_scene

var slots := []
var index := 0

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event):
	if event.is_action_pressed("tab"):
		visible = !visible
		get_tree().paused = visible
		if visible:
			refresh()

	if !visible:
		return

	if event.is_action_pressed("ui_down"):
		index = min(index + 1, slots.size() - 1)
		update_selection()

	if event.is_action_pressed("ui_up"):
		index = max(index - 1, 0)
		update_selection()

func refresh():
	for c in list_root.get_children():
		c.queue_free()

	slots.clear()

	for item in Inventory.items:
		var slot = preload("res://system/inspector/inspection_slot.tscn").instantiate()
		slot.set_item(item)
		list_root.add_child(slot)
		slots.append(slot)

	index = 0
	update_selection()

func update_selection():
	for i in slots.size():
		slots[i].set_selected(i == index)

	show_preview(index)
	
func show_preview(i):
	print("Selected:", Inventory.items[i].id)
