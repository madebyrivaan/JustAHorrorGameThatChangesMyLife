extends Label3D


@export var clue_key : String  # "birthday", "death", etc.

func _ready():
	if clue_key in GameManager.puzzle_data:
		var value = GameManager.puzzle_data[clue_key]
		text = format_text(value)

func format_text(value):
	match clue_key:
		"birthday":
			return "She was " + str(value) + " years old."
		"death":
			return "She died " + str(value) + " years ago."
		"abandon":
			return "This house was abandoned " + str(value) + " years ago."
		"case":
			return "Case file number: " + str(value)
		_:
			return str(value)
