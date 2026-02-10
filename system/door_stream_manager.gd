extends Node

@export var disable_delay := 2.0

var current_room : Node3D
var active_rooms := {}

func player_entered(room: Node3D):
	current_room = room
	activate_room(room)

func player_exited(room: Node3D):
	await get_tree().create_timer(disable_delay).timeout
	if current_room != room:
		deactivate_room(room)

func activate_room(room):
	if active_rooms.has(room):
		return
	room.enable_room()
	active_rooms[room] = true

func deactivate_room(room):
	if room == current_room:
		return
	room.disable_room()
	active_rooms.erase(room)
