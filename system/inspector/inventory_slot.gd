extends Control

@onready var label: Label = $VBoxContainer/Label


var data

func set_item(d):
	data = d
	label.text = d.id;

func set_selected(on):
	modulate = Color.WHITE if on else Color(1,1,1,0.5)
