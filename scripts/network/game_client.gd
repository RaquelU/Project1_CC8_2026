extends Node

const PROTOCOL_VERSION := 1
const MESSAGE_MAX_SIZE := 64 * 1024
const REMOTE_PLAYER_SCENE: PackedScene = preload("res://scenes/player/remote_player.tscn")

const FLAG_CARRY_OFFSET := Vector3(0.0, 3.6, -1.6)
const FLAG_GROUND_HEIGHT := 0.1

@export var server_ip := "127.0.0.1"
@export var server_port := 8889
@export var player_name := "Jugador local"

const CONNECT_TIMEOUT_SECONDS := 6.0

@onready var server_discovery: Node = $"../ServerDiscovery"
@onready var countdown_label: Label = $"../UI/CountdownLabel"
@onready var info_panel: Control = get_node_or_null("../UI/InfoPanel")

var peer := StreamPeerTCP.new()
var buffer := ""

var connected := false
var connecting := false
var connect_elapsed := 0.0
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
signal connection_failed(reason: String)


func _ready() -> void:
	add_to_group("network_client")

	local_player = get_tree().get_first_node_in_group("local_player")
	flag = get_tree().get_first_node_in_group("flag")

	if flag:
		flag_original_parent = flag.get_parent()

	server_discovery.server_selected.connect(_on_server_selected)

	try_manual_connection_from_arguments()


func _process(delta: float) -> void:
	peer.poll()

	var status := peer.get_status()

	if status == StreamPeerTCP.STATUS_CONNECTED:
		connecting = false
		connect_elapsed = 0.0

		if not connected:
			connected = true
			_log("Conectado al servidor.")

		if not join_sent:
			send_join()

		read_messages()

	elif status == StreamPeerTCP.STATUS_CONNECTING:
		if connecting:
			connect_elapsed += delta

			if connect_elapsed >= CONNECT_TIMEOUT_SECONDS:
				_log("Tiempo de espera agotado al conectar con el servidor.")
				fail_connection("TIMEOUT")

	elif status == StreamPeerTCP.STATUS_ERROR:
		if connected:
			connected = false
			join_sent = false
			game_started = false
			clear_remote_players()
			hide_countdown()
			_log("Servidor desconectado.")
		elif connecting:
			_log("No se pudo conectar con el servidor.")
			fail_connection("CONNECTION_ERROR")

	else:
		# STATUS_NONE: la conexión se cerró (por el servidor o localmente).
		if connected:
			connected = false
			join_sent = false
			game_started = false
			clear_remote_players()
			hide_countdown()
			_log("Servidor desconectado.")
		elif connecting:
			_log("No se pudo conectar con el servidor.")
			fail_connection("CONNECTION_ERROR")


func fail_connection(reason: String) -> void:
	connecting = false
	connect_elapsed = 0.0
	join_sent = false
	game_started = false

	if peer.get_status() != StreamPeerTCP.STATUS_NONE:
		peer.disconnect_from_host()

	connection_failed.emit(reason)


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
		connecting = false
		push_error("No se pudo iniciar la conexión TCP.")
		_log("No se pudo iniciar la conexión TCP.")
		connection_failed.emit("CONNECT_FAILED")
		return

	connecting = true
	connect_elapsed = 0.0

	_log("Conectando con %s:%s" % [server_ip, server_port])

func connect_with_address(ip: String, port: int) -> void:
	server_ip = ip
	server_port = port
	connect_to_server()


func disconnect_from_server() -> void:
	peer.disconnect_from_host()

	buffer = ""
	connected = false
	connecting = false
	connect_elapsed = 0.0
	join_sent = false
	game_started = false
	last_direction = Vector2(99.0, 99.0)

	clear_remote_players()
	hide_countdown()

	if info_panel:
		info_panel.set_players([])

	_log("Desconectado por el jugador. Volviendo al menú.")


func _log(text: String) -> void:
	print(text)

	if info_panel:
		info_panel.add_log(text)

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
			_log("ID asignado: %s" % local_player_id)
			connection_completed.emit()
			_log("Configuración recibida del servidor: %s" % message["config"])

		"lobby":
			game_started = false
			last_direction = Vector2(99.0, 99.0)
			clear_remote_players()
			update_known_player_names(message.get("players", []))
			hide_countdown()
			_log("Jugadores en lobby: %s" % message.get("players", []).size())

		"countdown":
			game_started = false
			show_countdown(int(message["seconds"]))
			_log("La partida inicia en %s" % message["seconds"])

		"start":
			game_started = true
			last_direction = Vector2(99.0, 99.0)
			hide_countdown()
			_log("Partida iniciada.")

		"state":
			apply_state(message)

		"game_over":
			game_started = false
			hide_countdown()
			_log("Ganador: %s" % get_display_name(str(message["winner"])))

		"error":
			_log("Error del servidor: %s" % message["reason"])


func get_display_name(player_id: String) -> String:
	if player_id == local_player_id:
		return player_name

	return str(known_player_names.get(player_id, "Jugador %s" % player_id))


func show_countdown(seconds: int) -> void:
	if not countdown_label:
		return

	countdown_label.text = str(seconds)
	countdown_label.visible = true


func hide_countdown() -> void:
	if countdown_label:
		countdown_label.visible = false


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

	var display_names: Array[String] = []

	for player_data in player_list:
		var player_id := str(player_data["id"])
		var name_text := str(player_data["name"])

		known_player_names[player_id] = name_text

		if player_id == local_player_id:
			display_names.append("%s (tú)" % name_text)
		else:
			display_names.append(name_text)

	if info_panel:
		info_panel.set_players(display_names)


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
			release_flag_from_node(remote_players[player_id])
			remote_players[player_id].queue_free()
			remote_players.erase(player_id)


func clear_remote_players() -> void:
	for player_id in remote_players.keys():
		release_flag_from_node(remote_players[player_id])
		remote_players[player_id].queue_free()

	remote_players.clear()


func release_flag_from_node(node: Node) -> void:
	# Si la bandera está actualmente sujeta al jugador que se va a eliminar,
	# hay que sacarla antes del queue_free(), o el motor la destruiría junto
	# con su portador (queue_free borra también a los hijos), y ya no
	# volvería a aparecer en las siguientes partidas.
	if is_instance_valid(flag) and flag.get_parent() == node:
		if flag_original_parent:
			flag.reparent(flag_original_parent)
		else:
			node.remove_child(flag)


func protocol_to_godot(x: float, y: float) -> Vector3:
	return Vector3(
		(x - 500.0) / 10.0,
		0.0,
		(y - 500.0) / 10.0
	)


func update_flag(flag_data: Dictionary) -> void:
	if not is_instance_valid(flag) or flag_data.is_empty():
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
