extends Node

const PROTOCOL_VERSION := 1
const MESSAGE_MAX_SIZE := 64 * 1024
const REMOTE_PLAYER_SCENE: PackedScene = preload("res://scenes/player/remote_player.tscn")

const FLAG_CARRY_OFFSET := Vector3(0.0, 1.5, -1.8)
const FLAG_GROUND_HEIGHT := 0.1

@export var server_ip := "127.0.0.1"
@export var server_port := 8889
@export var player_name := "Jugador local"

@onready var server_discovery: Node = $"../ServerDiscovery"

var peer := StreamPeerTCP.new()
var buffer := ""

var connected := false
var join_sent := false
var game_started := false
var local_player_id := ""

var last_direction := Vector2(99.0, 99.0)
var local_player: Node3D
var flag: Node3D
var flag_original_parent: Node

var remote_players: Dictionary = {}
var known_player_names: Dictionary = {}

signal connection_completed


func _ready() -> void:
	add_to_group("network_client")

	local_player = get_tree().get_first_node_in_group("local_player")
	flag = get_tree().get_first_node_in_group("flag")

	if flag:
		flag_original_parent = flag.get_parent()

	server_discovery.server_selected.connect(_on_server_selected)

	try_manual_connection_from_arguments()


func _process(_delta: float) -> void:
	peer.poll()

	var status := peer.get_status()

	if status == StreamPeerTCP.STATUS_CONNECTED:
		if not connected:
			connected = true
			print("Conectado al servidor.")

		if not join_sent:
			send_join()

		read_messages()

	elif connected:
		connected = false
		join_sent = false
		game_started = false
		clear_remote_players()
		print("Servidor desconectado.")


func connect_to_server() -> void:
	if peer.get_status() != StreamPeerTCP.STATUS_NONE:
		peer.disconnect_from_host()

	buffer = ""
	connected = false
	join_sent = false
	game_started = false
	last_direction = Vector2(99.0, 99.0)

	var result := peer.connect_to_host(server_ip, server_port)

	if result != OK:
		push_error("No se pudo iniciar la conexión TCP.")
		return

	print("Conectando con ", server_ip, ":", server_port)

func connect_with_address(ip: String, port: int) -> void:
	server_ip = ip
	server_port = port
	connect_to_server()

func send_join() -> void:
	join_sent = true

	send_message({
		"type": "join",
		"v": PROTOCOL_VERSION,
		"name": player_name
	})


func send_input(direction: Vector2) -> void:
	if not game_started or direction == last_direction:
		return

	last_direction = direction

	send_message({
		"type": "input",
		"dir": {
			"x": int(direction.x),
			"y": int(direction.y)
		}
	})


func send_interact() -> void:
	if game_started:
		send_message({"type": "interact"})


func send_message(message: Dictionary) -> void:
	if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return

	var text := JSON.stringify(message) + "\n"
	peer.put_data(text.to_utf8_buffer())


func read_messages() -> void:
	var available := peer.get_available_bytes()

	if available <= 0:
		return

	var result := peer.get_data(available)

	if result[0] != OK:
		return

	buffer += result[1].get_string_from_utf8()

	while true:
		var newline_position := buffer.find("\n")

		if newline_position == -1:
			break

		var line := buffer.substr(0, newline_position)
		buffer = buffer.substr(newline_position + 1)

		if line.ends_with("\r"):
			line = line.left(-1)

		if line.to_utf8_buffer().size() + 1 > MESSAGE_MAX_SIZE:
			print("MESSAGE_TOO_LARGE")
			peer.disconnect_from_host()
			return

		if line.is_empty():
			continue

		var message = JSON.parse_string(line)

		if typeof(message) == TYPE_DICTIONARY:
			handle_message(message)

	if buffer.to_utf8_buffer().size() >= MESSAGE_MAX_SIZE:
		print("MESSAGE_TOO_LARGE")
		peer.disconnect_from_host()


func handle_message(message: Dictionary) -> void:
	match message.get("type", ""):
		"welcome":
			local_player_id = str(message["player_id"])
			print("ID asignado: ", local_player_id)
			connection_completed.emit()
			print("Configuración: ", message["config"])

		"lobby":
			game_started = false
			last_direction = Vector2(99.0, 99.0)
			clear_remote_players()
			update_known_player_names(message.get("players", []))
			print("Jugadores en lobby: ", message.get("players", []).size())

		"countdown":
			game_started = false
			print("La partida inicia en ", message["seconds"])

		"start":
			game_started = true
			last_direction = Vector2(99.0, 99.0)
			print("Partida iniciada.")

		"state":
			apply_state(message)

		"game_over":
			game_started = false
			print("Ganador: ", message["winner"])

		"error":
			print("Error del servidor: ", message["reason"])


func apply_state(message: Dictionary) -> void:
	var seen_ids: Dictionary = {}

	for player_data in message.get("players", []):
		var player_id := str(player_data["id"])
		var position := protocol_to_godot(
			float(player_data["x"]),
			float(player_data["y"])
		)

		if player_id == local_player_id:
			if local_player:
				local_player.set_network_position(position)
			continue

		seen_ids[player_id] = true
		update_remote_player(player_id, position)

	remove_stale_remote_players(seen_ids)
	update_flag(message.get("flag", {}))


func update_remote_player(player_id: String, position: Vector3) -> void:
	if not remote_players.has(player_id):
		spawn_remote_player(player_id, position)
	else:
		remote_players[player_id].set_network_position(position)


func update_known_player_names(player_list: Array) -> void:
	known_player_names.clear()

	for player_data in player_list:
		known_player_names[str(player_data["id"])] = str(player_data["name"])


func spawn_remote_player(player_id: String, position: Vector3) -> void:
	var remote_player: Node3D = REMOTE_PLAYER_SCENE.instantiate()
	add_child(remote_player)

	remote_player.global_position = position
	remote_player.set_network_position(position)

	var label: Label3D = remote_player.get_node("NameLabel")

	if label:
		label.text = known_player_names.get(player_id, "Jugador")

	remote_players[player_id] = remote_player


func remove_stale_remote_players(seen_ids: Dictionary) -> void:
	for player_id in remote_players.keys():
		if not seen_ids.has(player_id):
			remote_players[player_id].queue_free()
			remote_players.erase(player_id)


func clear_remote_players() -> void:
	for player_id in remote_players.keys():
		remote_players[player_id].queue_free()

	remote_players.clear()


func protocol_to_godot(x: float, y: float) -> Vector3:
	return Vector3(
		(x - 500.0) / 10.0,
		0.0,
		(y - 500.0) / 10.0
	)


func update_flag(flag_data: Dictionary) -> void:
	if not flag or flag_data.is_empty():
		return

	var flag_owner: Variant = flag_data.get("owner")

	if flag_owner != null:
		var carrier := get_carrier_node(str(flag_owner))

		if carrier:
			if flag.get_parent() != carrier:
				flag.reparent(carrier)

			flag.position = FLAG_CARRY_OFFSET
			return

	if flag.get_parent() != flag_original_parent:
		flag.reparent(flag_original_parent)

	var position := protocol_to_godot(
		float(flag_data["x"]),
		float(flag_data["y"])
	)

	flag.global_position = Vector3(
		position.x,
		FLAG_GROUND_HEIGHT,
		position.z
	)


func get_carrier_node(owner_id: String) -> Node3D:
	if owner_id == local_player_id:
		return local_player

	return remote_players.get(owner_id) as Node3D


func _on_server_selected(ip: String, port: int) -> void:
	server_ip = ip
	server_port = port
	connect_to_server()


func try_manual_connection_from_arguments() -> bool:
	var manual_ip := ""
	var manual_port := 0

	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--ip="):
			manual_ip = argument.get_slice("=", 1)
		elif argument.begins_with("--port="):
			manual_port = int(argument.get_slice("=", 1))

	if manual_ip.is_empty():
		return false

	if manual_port > 0:
		server_ip = manual_ip
		server_port = manual_port
		connect_to_server()
	else:
		server_discovery.start_unicast_discovery(manual_ip)

	return true
