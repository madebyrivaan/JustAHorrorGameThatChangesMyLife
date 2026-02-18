extends Node

signal inventory_changed
signal selection_changed
signal inventory_toggled

var items: Array = []
var selected_index: int = 0
var inventory_open: bool = false


func _ready():
	print("✅ Inventory Autoload Ready")


# ===============================
# ADD ITEM
# ===============================
func add_item(data: Dictionary):
	if data.is_empty():
		push_error("❌ Tried to add empty item data")
		return
	
	items.append(data)
	var item_ID = data.get("id")
	print("📦 Item Added:", )
	emit_signal("inventory_changed")


# ===============================
# TOGGLE INVENTORY
# ===============================
func toggle():
	inventory_open = !inventory_open
	print("🎒 Inventory Open:", inventory_open)
	emit_signal("inventory_toggled", inventory_open)


# ===============================
# SELECTION
# ===============================
func select_next():
	if items.size() == 0:
		return
		
	selected_index = (selected_index + 1) % items.size()
	print("➡ Selected:", get_selected()["id"])
	emit_signal("selection_changed", get_selected())


func select_previous():
	if items.size() == 0:
		return
		
	selected_index = (selected_index - 1 + items.size()) % items.size()
	print("⬅ Selected:", get_selected()["id"])
	emit_signal("selection_changed", get_selected())


func get_selected() -> Dictionary:
	if items.size() == 0:
		return {}
	return items[selected_index]


func remove_selected():
	if items.size() == 0:
		return
		
	items.remove_at(selected_index)
	
	if selected_index >= items.size():
		selected_index = max(0, items.size() - 1)
	
	emit_signal("inventory_changed")
	
	if items.size() > 0:
		emit_signal("selection_changed", get_selected())

func has_item(id: String) -> bool:
	for item in items:
		if item.get("id") == id:
			return true
	return false
