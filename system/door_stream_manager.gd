extends Node

# door → rooms mapping
@export var door_map := {
	# door_node : { "enable": [], "disable": [] }
}

func GetRoomGroup(name:String):
	var room = get_tree().get_first_node_in_group(name)
	return room
	
func register_door(door):
	door.door_state_changed.connect(_on_door_state)

func _on_door_state(door, state):
	if !door_map.has(door):
		return

	var data = door_map[door]

	match state:
		door.DoorState.OPENING:
			for r in data.enable:
				_enable_room(r)

		door.DoorState.CLOSING:
			for r in data.disable:
				_disable_room(r)

func _enable_room(room: Node3D):
	room.visible = true
	room.process_mode = Node.PROCESS_MODE_INHERIT

func _disable_room(room: Node3D):
	room.visible = false
	room.process_mode = Node.PROCESS_MODE_DISABLED
