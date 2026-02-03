extends Node

var items := []

func add_item(item_name:String):
	items.append(item_name)
	print("Inventory:", items)

func has_item(item_name:String) -> bool:
	return item_name in items

func remove_item(item_name:String):
	items.erase(item_name)

func clear():
	items.clear()
