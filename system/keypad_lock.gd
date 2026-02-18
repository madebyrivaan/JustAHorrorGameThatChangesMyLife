extends Node3D

@export var correct_code: String = "472"
var keypad_ui
var attempts = 0
@onready var locker_proto: Node3D = $".."

func _ready():
	keypad_ui = get_tree().root.find_child("KeypadUI", true, false)
	keypad_ui.code_entered.connect(_on_code_entered)

func interact(player):
	keypad_ui.open()

func _on_code_entered(input_code: String):
	if input_code == GameManager.get_locker_code():
		open_lock()
	else:
		wrong_attempt()

func open_lock():
	locker_proto.visible = false;
	print("Locker Opened")

func wrong_attempt():
	attempts += 1
	
	if attempts >= 3:
		print("wrong Attempted",attempts)
