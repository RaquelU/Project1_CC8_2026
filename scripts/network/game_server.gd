extends Node

const TCP_PORT := 8889
const UDP_PORT := 8888
const SERVER_NAME := "Servidor CTF Godot"
const PROTOCOL_VERSION := 1

const MAX_PLAYERS := 100
const NAME_MAX_LENGTH := 20
const MESSAGE_MAX_SIZE := 64 * 1024

const MAP_SIZE := 1000.0
const PLAYER_RADIUS := 15.0
const CIRCLE_RADIUS := 300.0
const INTERACT_RADIUS := 40.0
const SPEED := 200.0
const TICK_RATE := 20.0

const COUNTDOWN_SECONDS := 5
const MIN_PLAYERS := 16
const POST_GAME_SECONDS := 5.0
const SPAWN_RADIUS_MIN := 350.0
const SPAWN_RADIUS_MAX := 450.0

const MAP_MIN := PLAYER_RADIUS
const MAP_MAX := MAP_SIZE - PLAYER_RADIUS
const CENTER := Vector2(500.0, 500.0)
const VICTORY_DISTANCE := CIRCLE_RADIUS + PLAYER_RADIUS

const SERVER_PLAYER_SCENE: PackedScene = preload("res://scenes/network/server_player_view.tscn")
const FLAG_CARRY_OFFSET := Vector3(0.0, 3.6, -1.6)
const FLAG_GROUND_HEIGHT := 0.1

var tcp_server := TCPServer.new()
var udp_server := UDPServer.new()

var clients: Dictionary = {}
var players: Dictionary = {}
var pending_interactions: Array[String] = []

var next_player_id := 1
var tick_accumulator := 0.0
var phase := "lobby"
var countdown_token := 0
var round_ending := false

var flag: Dictionary = {
	"owner": null,
	"x": CENTER.x,
	"y": CENTER.y
}

var owner_was_inside := false
var random := RandomNumberGenerator.new()

var player_visuals: Dictionary = {}
var flag_visual_original_parent: Node

@onready var players_container: Node3D = $PlayersContainer
@onready var flag_visual: Node3D = $GameplayArea/Flag
@onready var status_label: Label = $UI/StatusLabel


func _ready() -> void:
	random.randomize()

	flag_visual_original_parent = flag_visual.get_parent()

	if tcp_server.listen(TCP_PORT) != OK:
		push_error("No se pudo iniciar el servidor TCP.")
		return

	udp_server.max_pending_connections = MAX_PLAYERS

	if udp_server.listen(UDP_PORT, "0.0.0.0") != OK:
		push_error("No se pudo iniciar el descubrimiento UDP.")
		return

	print("Servidor TCP iniciado en el puerto ", TCP_PORT)
	print("Descubrimiento UDP activo en el puerto ", UDP_PORT)

	update_status_label()


func _process(delta: float) -> void:
	process_discovery()
	accept_new_clients()
	read_client_messages()

	tick_accumulator += delta

	while tick_accumulator >= 1.0 / TICK_RATE:
		tick_accumulator -= 1.0 / TICK_RATE

		if phase == "playing":
			update_game(1.0 / TICK_RATE)

			if phase == "playing":
				broadcast_state()

	update_visuals()


func accept_new_clients() -> void:
	while tcp_server.is_connection_available():
		var peer := tcp_server.take_connection()
		peer.set_no_delay(true)

		if clients.size() >= MAX_PLAYERS:
			send_message(peer, {
				"type": "error",
				"reason": "LOBBY_FULL"
			})
			peer.disconnect_from_host()
			continue

		var player_id := str(next_player_id)
		next_player_id += 1

		clients[player_id] = {
			"peer": peer,
			"buffer": "",
			"joined": false,
			"invalid_json_count": 0
		}

		print("Nueva conexión TCP: ", player_id)


func read_client_messages() -> void:
	var disconnected: Array[String] = []

	for player_id in clients.keys():
		if not clients.has(player_id):
			continue

		var client: Dictionary = clients[player_id]
		var peer: StreamPeerTCP = client["peer"]
		peer.poll()

		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			disconnected.append(player_id)
			continue

		var available := peer.get_available_bytes()

		if available <= 0:
			continue

		var result := peer.get_data(available)

		if result[0] != OK:
			disconnected.append(player_id)
			continue

		client["buffer"] += result[1].get_string_from_utf8()
		clients[player_id] = client
		process_buffer(player_id)

	for player_id in disconnected:
		remove_client(player_id)


func process_buffer(player_id: String) -> void:
	if not clients.has(player_id):
		return

	var client: Dictionary = clients[player_id]
	var buffer: String = client["buffer"]

	while true:
		var newline_position := buffer.find("\n")

		if newline_position == -1:
			break

		var line := buffer.substr(0, newline_position)
		buffer = buffer.substr(newline_position + 1)

		if line.ends_with("\r"):
			line = line.left(-1)

		if line.to_utf8_buffer().size() + 1 > MESSAGE_MAX_SIZE:
			client["buffer"] = buffer
			clients[player_id] = client
			send_error_and_close(player_id, "MESSAGE_TOO_LARGE")
			return

		if not line.is_empty():
			parse_message(player_id, line)

		if not clients.has(player_id):
			return

		client = clients[player_id]

	if buffer.to_utf8_buffer().size() >= MESSAGE_MAX_SIZE:
		client["buffer"] = ""
		clients[player_id] = client
		send_error_and_close(player_id, "MESSAGE_TOO_LARGE")
		return

	client["buffer"] = buffer
	clients[player_id] = client


func parse_message(player_id: String, text: String) -> void:
	var message = JSON.parse_string(text)

	if typeof(message) != TYPE_DICTIONARY:
		var client: Dictionary = clients[player_id]
		client["invalid_json_count"] = int(client["invalid_json_count"]) + 1
		clients[player_id] = client

		send_error(player_id, "INVALID_JSON")

		if int(client["invalid_json_count"]) >= 3:
			disconnect_client(player_id)

		return

	if not message.has("type"):
		send_error(player_id, "MISSING_FIELD")
		return

	if typeof(message["type"]) != TYPE_STRING:
		send_error(player_id, "INVALID_FIELD")
		return

	match message["type"]:
		"join":
			handle_join(player_id, message)
		"input":
			handle_input(player_id, message)
		"interact":
			handle_interact(player_id)
		_:
			send_error(player_id, "UNKNOWN_TYPE")


func handle_join(player_id: String, message: Dictionary) -> void:
	if not clients.has(player_id):
		return

	var client: Dictionary = clients[player_id]

	if bool(client["joined"]):
		send_error(player_id, "INVALID_PHASE")
		return

	if phase != "lobby":
		send_error_and_close(player_id, "GAME_STARTED")
		return

	if not message.has("v") or not message.has("name"):
		send_error(player_id, "MISSING_FIELD")
		return

	if not is_protocol_integer(message["v"]):
		send_error(player_id, "INVALID_FIELD")
		return

	if int(message["v"]) != PROTOCOL_VERSION:
		send_error_and_close(player_id, "VERSION_MISMATCH")
		return

	if typeof(message["name"]) != TYPE_STRING:
		send_error(player_id, "INVALID_FIELD")
		return

	var player_name: String = str(message["name"]).strip_edges()

	if not is_valid_player_name(player_name):
		send_error(player_id, "NAME_INVALID")
		return

	client["joined"] = true
	clients[player_id] = client

	players[player_id] = {
		"id": player_id,
		"name": player_name,
		"x": CENTER.x,
		"y": CENTER.y,
		"dir": Vector2.ZERO
	}

	send_to_player(player_id, {
		"type": "welcome",
		"player_id": player_id,
		"config": {
			"map_size": MAP_SIZE,
			"circle_radius": CIRCLE_RADIUS,
			"player_radius": PLAYER_RADIUS,
			"interact_radius": INTERACT_RADIUS,
			"speed": SPEED,
			"tick_rate": int(TICK_RATE)
		}
	})

	broadcast_lobby()

	if players.size() >= MIN_PLAYERS:
		start_countdown()


func is_valid_player_name(player_name: String) -> bool:
	if player_name.is_empty() or player_name.length() > NAME_MAX_LENGTH:
		return false

	for index in range(player_name.length()):
		var character_code := player_name.unicode_at(index)

		if character_code < 32 or character_code == 127:
			return false

	return true


func start_countdown() -> void:
	if phase != "lobby" or players.size() < MIN_PLAYERS:
		return

	phase = "countdown"
	countdown_token += 1
	var current_token := countdown_token

	for seconds in range(COUNTDOWN_SECONDS, 0, -1):
		if current_token != countdown_token:
			return

		if players.size() < MIN_PLAYERS:
			abort_countdown()
			return

		broadcast({
			"type": "countdown",
			"seconds": seconds
		})

		await get_tree().create_timer(1.0).timeout

	if current_token != countdown_token:
		return

	if players.size() < MIN_PLAYERS:
		abort_countdown()
		return

	begin_round()


func abort_countdown() -> void:
	countdown_token += 1
	phase = "lobby"
	broadcast_lobby()
	print("Countdown cancelado: faltan jugadores.")


func begin_round() -> void:
	phase = "playing"
	round_ending = false
	pending_interactions.clear()
	reset_flag()

	for player_id in players:
		var player: Dictionary = players[player_id]
		var spawn := create_spawn_position()

		player["x"] = spawn.x
		player["y"] = spawn.y
		player["dir"] = Vector2.ZERO
		players[player_id] = player

	broadcast({"type": "start"})
	broadcast_state()
	print("La partida comenzó con ", players.size(), " jugadores.")


func create_spawn_position() -> Vector2:
	var angle := random.randf_range(0.0, TAU)
	var radius := random.randf_range(SPAWN_RADIUS_MIN, SPAWN_RADIUS_MAX)

	return Vector2(
		CENTER.x + cos(angle) * radius,
		CENTER.y + sin(angle) * radius
	)


func broadcast_lobby() -> void:
	var player_list: Array = []

	for player in players.values():
		player_list.append({
			"id": player["id"],
			"name": player["name"]
		})

	broadcast({
		"type": "lobby",
		"players": player_list
	})


func handle_input(player_id: String, message: Dictionary) -> void:
	if not validate_player_action(player_id):
		return

	if not message.has("dir"):
		send_error(player_id, "MISSING_FIELD")
		return

	var direction = message["dir"]

	if typeof(direction) != TYPE_DICTIONARY:
		send_error(player_id, "INVALID_FIELD")
		return

	if not direction.has("x") or not direction.has("y"):
		send_error(player_id, "MISSING_FIELD")
		return

	if not is_valid_direction(direction["x"]) or not is_valid_direction(direction["y"]):
		send_error(player_id, "INVALID_FIELD")
		return

	var player: Dictionary = players[player_id]
	player["dir"] = Vector2(
		int(direction["x"]),
		int(direction["y"])
	)
	players[player_id] = player


func is_valid_direction(value: Variant) -> bool:
	if not is_protocol_integer(value):
		return false

	return int(value) in [-1, 0, 1]


func validate_player_action(player_id: String) -> bool:
	if not clients.has(player_id) or not bool(clients[player_id]["joined"]):
		send_error(player_id, "NOT_JOINED")
		return false

	if not players.has(player_id):
		send_error(player_id, "NOT_JOINED")
		return false

	if phase != "playing":
		send_error(player_id, "INVALID_PHASE")
		return false

	return true


func handle_interact(player_id: String) -> void:
	if not validate_player_action(player_id):
		return

	pending_interactions.append(player_id)


func update_game(delta: float) -> void:
	for player_id in players:
		var player: Dictionary = players[player_id]
		var direction: Vector2 = player["dir"]

		if direction != Vector2.ZERO:
			direction = direction.normalized()

		var position := Vector2(
			float(player["x"]),
			float(player["y"])
		)

		position += direction * SPEED * delta
		position.x = clamp(position.x, MAP_MIN, MAP_MAX)
		position.y = clamp(position.y, MAP_MIN, MAP_MAX)

		player["x"] = position.x
		player["y"] = position.y
		players[player_id] = player

	update_flag_position()
	check_carrier_victory()

	if phase != "playing":
		pending_interactions.clear()
		return

	process_pending_interactions()
	update_flag_position()


func process_pending_interactions() -> void:
	var interactions := pending_interactions.duplicate()
	pending_interactions.clear()

	for player_id in interactions:
		if phase != "playing":
			return

		if players.has(player_id):
			apply_interaction(player_id)


func apply_interaction(player_id: String) -> void:
	var player_position := get_player_position(player_id)
	var owner_value: Variant = flag.get("owner")

	if owner_value == null:
		var flag_position := Vector2(
			float(flag["x"]),
			float(flag["y"])
		)

		if player_position.distance_to(flag_position) <= INTERACT_RADIUS:
			set_flag_owner(player_id)

		return

	var owner_id := str(owner_value)

	if owner_id == player_id:
		return

	if not players.has(owner_id):
		reset_flag()
		return

	var owner_position := get_player_position(owner_id)

	if player_position.distance_to(owner_position) <= INTERACT_RADIUS:
		set_flag_owner(player_id)


func set_flag_owner(player_id: String) -> void:
	flag["owner"] = player_id

	var position := get_player_position(player_id)
	flag["x"] = position.x
	flag["y"] = position.y
	owner_was_inside = position.distance_to(CENTER) <= VICTORY_DISTANCE


func get_player_position(player_id: String) -> Vector2:
	var player: Dictionary = players[player_id]

	return Vector2(
		float(player["x"]),
		float(player["y"])
	)


func update_flag_position() -> void:
	var owner_value: Variant = flag.get("owner")

	if owner_value == null:
		return

	var owner_id := str(owner_value)

	if not players.has(owner_id):
		return

	var carrier_position := get_player_position(owner_id)
	flag["x"] = carrier_position.x
	flag["y"] = carrier_position.y


func check_carrier_victory() -> void:
	var owner_value: Variant = flag.get("owner")

	if owner_value == null:
		return

	var owner_id := str(owner_value)

	if not players.has(owner_id):
		return

	var distance_to_center := get_player_position(owner_id).distance_to(CENTER)

	if distance_to_center <= VICTORY_DISTANCE:
		owner_was_inside = true
	elif owner_was_inside:
		finish_round(owner_id)


func finish_round(winner_id: String) -> void:
	if round_ending:
		return

	round_ending = true
	phase = "finished"

	broadcast({
		"type": "game_over",
		"winner": winner_id
	})

	print("Ganador: ", winner_id)
	await get_tree().create_timer(POST_GAME_SECONDS).timeout

	if phase == "finished":
		return_to_lobby()


func return_to_lobby() -> void:
	phase = "lobby"
	round_ending = false
	pending_interactions.clear()
	reset_flag()

	for player_id in players:
		var player: Dictionary = players[player_id]
		player["dir"] = Vector2.ZERO
		players[player_id] = player

	broadcast_lobby()
	print("Servidor regresó al lobby.")

	if players.size() >= MIN_PLAYERS:
		start_countdown()


func broadcast_state() -> void:
	var player_list: Array = []

	for player in players.values():
		player_list.append({
			"id": player["id"],
			"x": snappedf(float(player["x"]), 0.1),
			"y": snappedf(float(player["y"]), 0.1)
		})

	broadcast({
		"type": "state",
		"flag": {
			"owner": flag["owner"],
			"x": snappedf(float(flag["x"]), 0.1),
			"y": snappedf(float(flag["y"]), 0.1)
		},
		"players": player_list
	})


func send_message(peer: StreamPeerTCP, message: Dictionary) -> void:
	var text := JSON.stringify(message) + "\n"
	peer.put_data(text.to_utf8_buffer())


func send_to_player(player_id: String, message: Dictionary) -> void:
	if not clients.has(player_id):
		return

	var peer: StreamPeerTCP = clients[player_id]["peer"]
	send_message(peer, message)


func broadcast(message: Dictionary) -> void:
	for player_id in clients:
		if bool(clients[player_id]["joined"]):
			send_to_player(player_id, message)


func send_error(player_id: String, reason: String) -> void:
	send_to_player(player_id, {
		"type": "error",
		"reason": reason
	})


func send_error_and_close(player_id: String, reason: String) -> void:
	send_error(player_id, reason)
	disconnect_client(player_id)


func disconnect_client(player_id: String) -> void:
	if clients.has(player_id):
		var peer: StreamPeerTCP = clients[player_id]["peer"]
		peer.disconnect_from_host()

	remove_client(player_id)


func remove_client(player_id: String) -> void:
	var was_joined: bool = players.has(player_id)
	var was_owner: bool = flag.get("owner") == player_id

	clients.erase(player_id)
	players.erase(player_id)

	if was_owner:
		reset_flag()

	if phase == "countdown" and players.size() < MIN_PLAYERS:
		abort_countdown()
	elif phase == "lobby" and was_joined:
		broadcast_lobby()
	elif phase == "playing" and players.is_empty():
		phase = "lobby"
		pending_interactions.clear()
		reset_flag()

	print("Cliente desconectado: ", player_id)


func reset_flag() -> void:
	flag["owner"] = null
	flag["x"] = CENTER.x
	flag["y"] = CENTER.y
	owner_was_inside = false


func process_discovery() -> void:
	udp_server.poll()

	while udp_server.is_connection_available():
		var peer := udp_server.take_connection()

		if peer == null:
			continue

		while peer.get_available_packet_count() > 0:
			var packet := peer.get_packet()

			if packet.size() > MESSAGE_MAX_SIZE:
				continue

			var message = JSON.parse_string(packet.get_string_from_utf8())

			if not is_valid_discover(message):
				continue

			var response := {
				"type": "server_info",
				"v": PROTOCOL_VERSION,
				"name": SERVER_NAME,
				"tcp_port": TCP_PORT,
				"state": "lobby" if phase == "lobby" else "playing",
				"players": players.size()
			}

			peer.put_packet(
				JSON.stringify(response).to_utf8_buffer()
			)


func is_valid_discover(message: Variant) -> bool:
	if typeof(message) != TYPE_DICTIONARY:
		return false

	if message.get("type") != "discover":
		return false

	var version: Variant = message.get("v")

	return (
		is_protocol_integer(version)
		and int(version) == PROTOCOL_VERSION
	)


func is_protocol_integer(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false

	var numeric_value: float = float(value)
	return numeric_value == floor(numeric_value)


func update_visuals() -> void:
	sync_player_visuals()
	sync_flag_visual()
	update_status_label()


func sync_player_visuals() -> void:
	var seen_ids: Dictionary = {}

	for player_id in players:
		seen_ids[player_id] = true

		var player: Dictionary = players[player_id]
		var position := protocol_to_godot(float(player["x"]), float(player["y"]))

		if not player_visuals.has(player_id):
			spawn_player_visual(player_id, str(player["name"]), position)
		else:
			var visual: Node3D = player_visuals[player_id]
			visual.global_position = position

	for player_id in player_visuals.keys():
		if not seen_ids.has(player_id):
			player_visuals[player_id].queue_free()
			player_visuals.erase(player_id)


func spawn_player_visual(player_id: String, player_name: String, position: Vector3) -> void:
	var visual: Node3D = SERVER_PLAYER_SCENE.instantiate()
	players_container.add_child(visual)
	visual.global_position = position

	var label: Label3D = visual.get_node("NameLabel")

	if label:
		label.text = player_name

	player_visuals[player_id] = visual


func sync_flag_visual() -> void:
	var owner_value: Variant = flag.get("owner")

	if owner_value != null:
		var carrier: Node3D = player_visuals.get(str(owner_value)) as Node3D

		if carrier:
			if flag_visual.get_parent() != carrier:
				flag_visual.reparent(carrier)

			flag_visual.position = FLAG_CARRY_OFFSET
			return

	if flag_visual.get_parent() != flag_visual_original_parent:
		flag_visual.reparent(flag_visual_original_parent)

	var position := protocol_to_godot(float(flag["x"]), float(flag["y"]))

	flag_visual.global_position = Vector3(
		position.x,
		FLAG_GROUND_HEIGHT,
		position.z
	)


func update_status_label() -> void:
	var phase_names := {
		"lobby": "Lobby",
		"countdown": "Cuenta regresiva",
		"playing": "En partida",
		"finished": "Fin de partida"
	}

	status_label.text = (
		"%s\nPuerto TCP: %d\nFase: %s\nJugadores: %d / %d"
		% [
			SERVER_NAME,
			TCP_PORT,
			phase_names.get(phase, phase),
			players.size(),
			MAX_PLAYERS
		]
	)


func protocol_to_godot(x: float, y: float) -> Vector3:
	return Vector3(
		(x - 500.0) / 10.0,
		0.0,
		(y - 500.0) / 10.0
	)
