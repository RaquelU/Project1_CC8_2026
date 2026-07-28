extends Node

const PROTOCOL_VERSION := 1
const MESSAGE_MAX_SIZE := 64 * 1024

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
	for player_data in message.get("players", []):
		if (
			str(player_data["id"]) == local_player_id
			and local_player
		):
			local_player.set_network_position(
				protocol_to_godot(
					float(player_data["x"]),
					float(player_data["y"])
				)
			)

	update_flag(message.get("flag", {}))


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

	if flag_owner != null and str(flag_owner) == local_player_id:
		if flag.get_parent() != local_player:
			flag.reparent(local_player)

		flag.position = Vector3(1.2, 1.8, -1.5)
		return

	if flag.get_parent() != flag_original_parent:
		flag.reparent(flag_original_parent)

	var position := protocol_to_godot(
		float(flag_data["x"]),
		float(flag_data["y"])
	)

	flag.global_position = Vector3(
		position.x,
		0.1,
		position.z
	)


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
