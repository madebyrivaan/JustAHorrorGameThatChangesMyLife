# GameManager.gd (Autoload)
extends Node

# ===============================
# DATA STORAGE
# ===============================

var puzzle_data : Dictionary = {}
var completed_sequences : Dictionary = {}
var current_game_state : String = "START"   # optional story state


# ===============================
# INITIALIZATION
# ===============================

func _ready():
	randomize()
	_generate_puzzle_data()


# ===============================
# PUZZLE SYSTEM
# ===============================

func _generate_puzzle_data():
	var birthday = randi_range(5, 12)
	var death_years = randi_range(1, 9)
	var abandon_years = randi_range(3, 9)
	var case_number = randi_range(1, 5)
	
	puzzle_data = {
		"birthday": birthday,
		"death": death_years,
		"abandon": abandon_years,
		"case": case_number
	}
	
	print("Puzzle Data Generated:", puzzle_data)


func get_locker_code() -> String:
	return str(puzzle_data["birthday"]) + \
		   str(puzzle_data["death"]) + \
		   str(puzzle_data["abandon"]) + \
		   str(puzzle_data["case"])


# ===============================
# SEQUENCE SYSTEM
# ===============================

func request_event(event_name:String, source):
	# Already completed?
	if completed_sequences.has(event_name):
		print("⛔ Sequence already completed:", event_name)
		return

	print("📩 Event Requested:", event_name)

	JumpscareManager.evaluate_event(event_name, source)


func mark_sequence_done(event_name:String):
	completed_sequences[event_name] = true
	print("✅ Sequence Marked Done:", event_name)


func is_sequence_done(event_name:String) -> bool:
	return completed_sequences.has(event_name)


# ===============================
# STORY STATE SYSTEM (Optional Future)
# ===============================

func set_game_state(new_state:String):
	current_game_state = new_state
	print("🎭 Game State Changed To:", current_game_state)


func get_game_state() -> String:
	return current_game_state


# ===============================
# DEBUG
# ===============================

func reset_sequences():
	completed_sequences.clear()
	print("♻ All sequences reset.")
