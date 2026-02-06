extends Node

var items := [] # each item = {id, preview, desc}

func add_item(item:Node3D):
	items.append({
		"id": item.item_id,
		"desc": item.item_des,
		"preview": item.preview_scene
	})
	print("Inventory:", items)

func has_item(item_name:String) -> bool:
	return item_name in items

func remove_item(item_name:String):
	items.erase(item_name)

func clear():
	items.clear()
