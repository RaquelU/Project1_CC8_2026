extends Node

const PORT := 8889
const PROTOCOL_VERSION := 1
const MAX_PLAYERS := 100

const MAP_SIZE := 1000.0
const PLAYER_RADIUS := 15.0
const CIRCLE_RADIUS := 300.0
const INTERACT_RADIUS := 40.0
const SPEED := 200.0
const TICK_RATE := 20.0
const COUNTDOWN_SECONDS := 5

const MAP_MIN := PLAYER_RADIUS
const MAP_MAX := MAP_SIZE - PLAYER_RADIUS
const CENTER := Vector2(500.0, 500.0)
const VICTORY_RADIUS := CIRCLE_RADIUS + PLAYER_RADIUS

var tcp_server := TCPServer.new()
var clients: Dictionary = {}
var players: Dictionary = {}

var next_player_id := 1
var tick_accumulator := 0.0
var phase := "lobby"
var countdown_active := false

var flag := {
	"owner": null,
	"x": 500.0,
	"y": 500.0
}

var random := RandomNumberGenerator.new()


func _ready() -> void:
	random.randomize()

	var result := tcp_server.listen(PORT)

	if result != OK:
		push_error("No se pudo iniciar el servidor TCP.")
		return

	print("Servidor iniciado en el puerto ", PORT)


func _process(delta: float) -> void:
	accept_new_clients()
	read_client_messages()

	tick_accumulator += delta

	while tick_accumulator >= 1.0 / TICK_RATE:
		tick_accumulator -= 1.0 / TICK_RATE

		if phase == "playing":
			update_game(1.0 / TICK_RATE)
			broadcast_state()
			
# Aceptar conexiones

func accept_new_clients() -> void:
	while tcp_server.is_connection_available():
		if clients.size() >= MAX_PLAYERS:
			var rejected_peer := tcp_server.take_connection()
			send_message(rejected_peer, {
				"type": "error",
				"reason": "LOBBY_FULL"
			})
			rejected_peer.disconnect_from_host()
			continue

		var peer := tcp_server.take_connection()
		var player_id := str(next_player_id)

		next_player_id += 1

		clients[player_id] = {
			"peer": peer,
			"buffer": "",
			"joined": false
		}

		print("Nueva conexión: ", player_id)
		
func read_client_messages() -> void:
	var disconnected: Array[String] = []

	for player_id in clients:
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
	var client: Dictionary = clients[player_id]
	var buffer: String = client["buffer"]
	var newline_position := buffer.find("\n")

	while newline_position != -1:
		var line := buffer.substr(0, newline_position).strip_edges()
		buffer = buffer.substr(newline_position + 1)

		if not line.is_empty():
			parse_message(player_id, line)

		newline_position = buffer.find("\n")

	client["buffer"] = buffer
	clients[player_id] = client
	
func parse_message(player_id: String, text: String) -> void:
	var message = JSON.parse_string(text)

	if typeof(message) != TYPE_DICTIONARY:
		send_error(player_id, "INVALID_JSON")
		return

	if not message.has("type") or typeof(message["type"]) != TYPE_STRING:
		send_error(player_id, "MISSING_FIELD")
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
	var client: Dictionary = clients[player_id]

	if client["joined"]:
		send_error(player_id, "ALREADY_JOINED")
		return

	if message.get("v") != PROTOCOL_VERSION:
		send_error(player_id, "VERSION_MISMATCH")
		return

	var player_name := str(message.get("name", "")).strip_edges()

	if player_name.is_empty() or player_name.length() > 20:
		send_error(player_id, "NAME_INVALID")
		return

	client["joined"] = true
	clients[player_id] = client

	var spawn := create_spawn_position()

	players[player_id] = {
		"id": player_id,
		"name": player_name,
		"x": spawn.x,
		"y": spawn.y,
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

	if phase == "lobby" and not countdown_active:
		start_countdown()
		
func create_spawn_position() -> Vector2:
	while true:
		var position := Vector2(
			random.randf_range(MAP_MIN, MAP_MAX),
			random.randf_range(MAP_MIN, MAP_MAX)
		)

		if position.distance_to(CENTER) > VICTORY_RADIUS:
			return position

	return Vector2(500.0, 850.0)
	
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
	
func start_countdown() -> void:
	countdown_active = true
	phase = "countdown"

	for seconds in range(COUNTDOWN_SECONDS, 0, -1):
		if players.is_empty():
			phase = "lobby"
			countdown_active = false
			return

		broadcast({
			"type": "countdown",
			"seconds": seconds
		})

		await get_tree().create_timer(1.0).timeout

	phase = "playing"
	countdown_active = false

	broadcast({
		"type": "start"
	})

	print("La partida comenzó.")
	
func handle_input(player_id: String, message: Dictionary) -> void:
	if not validate_player_action(player_id):
		return

	var direction = message.get("dir")

	if typeof(direction) != TYPE_DICTIONARY:
		send_error(player_id, "INVALID_FIELD")
		return

	var x = direction.get("x")
	var y = direction.get("y")

	if not is_valid_direction(x) or not is_valid_direction(y):
		send_error(player_id, "INVALID_FIELD")
		return

	var player: Dictionary = players[player_id]
	player["dir"] = Vector2(float(x), float(y))
	players[player_id] = player
	
func is_valid_direction(value) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false

	return int(value) in [-1, 0, 1]


func validate_player_action(player_id: String) -> bool:
	if not players.has(player_id):
		send_error(player_id, "NOT_JOINED")
		return false

	if phase != "playing":
		send_error(player_id, "INVALID_PHASE")
		return false

	return true
	
func update_game(delta: float) -> void:
	for player_id in players:
		var player: Dictionary = players[player_id]

		var old_position := Vector2(
			player["x"],
			player["y"]
		)

		var direction: Vector2 = player["dir"]

		if direction != Vector2.ZERO:
			direction = direction.normalized()

		var new_position := old_position + direction * SPEED * delta

		new_position.x = clamp(new_position.x, MAP_MIN, MAP_MAX)
		new_position.y = clamp(new_position.y, MAP_MIN, MAP_MAX)

		player["x"] = new_position.x
		player["y"] = new_position.y

		players[player_id] = player

		check_victory(player_id, old_position, new_position)

		if phase == "finished":
			return

	update_flag_position()
	
func handle_interact(player_id: String) -> void:
	if not validate_player_action(player_id):
		return

	var player_position := get_player_position(player_id)
	var current_owner = flag["owner"]

	if current_owner == null:
		var flag_position := Vector2(flag["x"], flag["y"])

		if player_position.distance_to(flag_position) <= INTERACT_RADIUS:
			flag["owner"] = player_id
			print("Jugador ", player_id, " capturó la bandera.")
		else:
			send_error(player_id, "TOO_FAR")

		return

	if current_owner == player_id:
		return

	if not players.has(current_owner):
		reset_flag()
		return

	var owner_position := get_player_position(current_owner)

	if player_position.distance_to(owner_position) <= INTERACT_RADIUS:
		flag["owner"] = player_id
		print("Jugador ", player_id, " robó la bandera.")
	else:
		send_error(player_id, "TOO_FAR")
		
func get_player_position(player_id: String) -> Vector2:
	var player: Dictionary = players[player_id]

	return Vector2(
		player["x"],
		player["y"]
	)


func update_flag_position() -> void:
	var owner = flag["owner"]

	if owner == null or not players.has(owner):
		return

	var position := get_player_position(owner)

	flag["x"] = position.x
	flag["y"] = position.y
	
func check_victory(
	player_id: String,
	old_position: Vector2,
	new_position: Vector2
) -> void:
	if flag["owner"] != player_id:
		return

	var old_distance := old_position.distance_to(CENTER)
	var new_distance := new_position.distance_to(CENTER)

	if old_distance <= VICTORY_RADIUS and new_distance > VICTORY_RADIUS:
		phase = "finished"

		broadcast({
			"type": "game_over",
			"winner": player_id
		})

		print("Ganador: ", player_id)
		
func broadcast_state() -> void:
	var player_list: Array = []

	for player in players.values():
		player_list.append({
			"id": player["id"],
			"name": player["name"],
			"x": snappedf(player["x"], 0.1),
			"y": snappedf(player["y"], 0.1)
		})

	broadcast({
		"type": "state",
		"flag": {
			"owner": flag["owner"],
			"x": snappedf(flag["x"], 0.1),
			"y": snappedf(flag["y"], 0.1)
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
		if clients[player_id]["joined"]:
			send_to_player(player_id, message)


func send_error(player_id: String, reason: String) -> void:
	send_to_player(player_id, {
		"type": "error",
		"reason": reason
	})
	
func remove_client(player_id: String) -> void:
	clients.erase(player_id)
	players.erase(player_id)

	if flag["owner"] == player_id:
		reset_flag()

	broadcast_lobby()

	print("Cliente desconectado: ", player_id)


func reset_flag() -> void:
	flag["owner"] = null
	flag["x"] = CENTER.x
	flag["y"] = CENTER.y
