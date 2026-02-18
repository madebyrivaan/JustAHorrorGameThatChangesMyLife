extends Control

signal code_entered(input_code)

@onready var line_edit: LineEdit = $LineEdit

func _ready():
	visible = false
	line_edit.text_submitted.connect(_on_text_submitted)

func open():
	visible = true
	line_edit.text = ""
	line_edit.grab_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close():
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_text_submitted(new_text: String):
	emit_signal("code_entered", new_text)
	close()
