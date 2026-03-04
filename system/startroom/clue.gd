extends Label3D


@export var clue_key : String  # "birthday", "death", etc.

func _ready():
	if clue_key in GameManager.puzzle_data:
		var value = GameManager.puzzle_data[clue_key]
		print(format_text(value))
		text = format_text(value)
		
func format_text(value):
	match clue_key:
		"birthday":
			return str(value)
		"death":
			return str(value)
		"abandon":
			return str(value) 
		"case":
			return str(value)
		_:
			return str(value)
