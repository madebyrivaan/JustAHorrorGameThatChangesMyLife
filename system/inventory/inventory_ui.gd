extends CanvasLayer

@onready var name_label = $Control/Label
@onready var description_label = $Control/RichTextLabel
@onready var preview_holder: Node3D = $Control/SubViewportContainer/SubViewport/InspectionWorld/PreviewHolder

func _ready():
	visible = false
	
	Inventory.inventory_toggled.connect(_on_inventory_toggled)
	Inventory.selection_changed.connect(_on_selection_changed)
	Inventory.inventory_changed.connect(_on_inventory_changed)


func _unhandled_input(event):
	if event.is_action_pressed("inventory_toggle"):
		Inventory.toggle()

	if !Inventory.inventory_open:
		return

	if event.is_action_pressed("ui_right"):
		Inventory.select_next()

	if event.is_action_pressed("ui_left"):
		Inventory.select_previous()
	
	if Inventory.inventory_open and event.is_action_pressed("interact"):
		var selected = Inventory.get_selected()
		var player = get_tree().get_first_node_in_group("player")
	
		if player and player.locked_target:
			var success = player.locked_target.try_use_item(selected)
		
			if success:
				print("Item used successfully")
				Inventory.remove_selected()
				player.locked_target = null
				Inventory.toggle() # close inventory
			else:
				print("Wrong item")
		else:
			print("Nothing to use item on")



func _on_inventory_toggled(open):
	visible = open
	
	if open:
		get_tree().call_group("player", "set_input_locked", true)
		get_tree().call_group("interior", "enable_blur")
		
		if Inventory.items.size() > 0:
			_on_selection_changed(Inventory.get_selected())
	else:
		get_tree().call_group("player", "set_input_locked", false)
		get_tree().call_group("interior", "disable_blur")


func _on_inventory_changed():
	if Inventory.items.size() == 1:
		_on_selection_changed(Inventory.get_selected())


func _on_selection_changed(data: Dictionary):
	if data.is_empty():
		return
		
	name_label.text = data["id"]
	description_label.text = data["description"]
	
	_spawn_preview(data["preview_scene"])


func _spawn_preview(scene: PackedScene):
	for c in preview_holder.get_children():
		c.queue_free()
	
	if scene == null:
		return
	print("Spawning preview:", scene)

	var preview = scene.instantiate()
	preview_holder.add_child(preview)
	print("Preview instance:", preview)

	# 🔥 RESET EVERYTHING
	preview.transform = Transform3D.IDENTITY
	preview.rotation = Vector3.ZERO   # ⭐ MOST IMPORTANT

	# Optional scale
	preview.scale = Vector3.ONE * 0.15
	# Reset transform for clean cinematic look
	preview.transform = Transform3D.IDENTITY
