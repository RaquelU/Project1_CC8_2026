extends Node

signal server_selected(ip: String, port: int)

const DISCOVERY_PORT := 8888
const PROTOCOL_VERSION := 1
const MESSAGE_MAX_SIZE := 64 * 1024
const SEARCH_TIME := 3.0
const RETRY_INTERVAL := 0.5
const LIMITED_BROADCAST := "255.255.255.255"

var udp := PacketPeerUDP.new()
var discovered_servers: Array[Dictionary] = []
var destinations: Array[String] = []

var searching := false
var elapsed_time := 0.0
var retry_time := 0.0


func start_discovery() -> void:
	var broadcast_destinations := get_broadcast_destinations()

	if broadcast_destinations.size() < 2:
		print(
			"ADVERTENCIA: falta el broadcast dirigido de la subred. ",
			"Ejecuta el cliente con --broadcast=<BROADCAST_DE_SUBRED>."
		)

	start_search(broadcast_destinations)


func start_unicast_discovery(ip: String) -> void:
	start_search([ip])


func start_search(search_destinations: Array[String]) -> void:
	discovered_servers.clear()
	destinations = remove_duplicate_addresses(search_destinations)
	elapsed_time = 0.0
	retry_time = 0.0
	searching = true

	udp.close()

	if udp.bind(0) != OK:
		push_error("No se pudo abrir el socket UDP del cliente.")
		searching = false
		return

	udp.set_broadcast_enabled(true)
	send_discover()

	print("Buscando servidores por UDP en: ", destinations)


func _process(delta: float) -> void:
	if not searching:
		return

	read_responses()

	elapsed_time += delta
	retry_time += delta

	if retry_time >= RETRY_INTERVAL:
		retry_time = 0.0
		send_discover()

	if elapsed_time >= SEARCH_TIME:
		finish_discovery()


func send_discover() -> void:
	var packet := JSON.stringify({
		"type": "discover",
		"v": PROTOCOL_VERSION
	}).to_utf8_buffer()

	for destination in destinations:
		var result := udp.set_dest_address(destination, DISCOVERY_PORT)

		if result != OK:
			print("No se pudo configurar el destino UDP: ", destination)
			continue

		result = udp.put_packet(packet)

		if result != OK:
			print("No se pudo enviar discover a ", destination, ":", DISCOVERY_PORT)


func get_broadcast_destinations() -> Array[String]:
	var result: Array[String] = [LIMITED_BROADCAST]

	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--broadcast="):
			var address := argument.get_slice("=", 1).strip_edges()

			if is_valid_ipv4(address):
				result.append(address)
			else:
				print("Broadcast inválido ignorado: ", address)

	return remove_duplicate_addresses(result)


func remove_duplicate_addresses(addresses: Array[String]) -> Array[String]:
	var unique: Array[String] = []

	for address in addresses:
		if not unique.has(address):
			unique.append(address)

	return unique


func is_valid_ipv4(address: String) -> bool:
	var parts := address.split(".")

	if parts.size() != 4:
		return false

	for part in parts:
		if part.is_empty() or not part.is_valid_int():
			return false

		var value := int(part)

		if value < 0 or value > 255:
			return false

	return true


func read_responses() -> void:
	while udp.get_available_packet_count() > 0:
		var packet := udp.get_packet()

		if packet.size() > MESSAGE_MAX_SIZE:
			continue

		var sender_ip := udp.get_packet_ip()
		var message = JSON.parse_string(packet.get_string_from_utf8())

		if is_valid_server_info(message):
			register_server(sender_ip, message)


func is_valid_server_info(message) -> bool:
	if typeof(message) != TYPE_DICTIONARY:
		return false

	if message.get("type") != "server_info":
		return false

	if not is_protocol_integer(message.get("v")):
		return false

	if int(message.get("v")) != PROTOCOL_VERSION:
		return false

	if typeof(message.get("name")) != TYPE_STRING:
		return false

	if not is_protocol_integer(message.get("tcp_port")):
		return false

	if typeof(message.get("state")) != TYPE_STRING:
		return false

	if message.get("state") not in ["lobby", "playing"]:
		return false

	if not is_protocol_integer(message.get("players")):
		return false

	var port := int(message["tcp_port"])
	return port > 0 and port <= 65535


func register_server(ip: String, message: Dictionary) -> void:
	var port := int(message["tcp_port"])

	for server in discovered_servers:
		if server["ip"] == ip and server["tcp_port"] == port:
			server["name"] = str(message["name"])
			server["state"] = str(message["state"])
			server["players"] = int(message["players"])
			return

	discovered_servers.append({
		"ip": ip,
		"tcp_port": port,
		"name": str(message["name"]),
		"state": str(message["state"]),
		"players": int(message["players"])
	})

	print(
		"Servidor encontrado: ",
		message["name"],
		" | ",
		ip,
		":",
		port,
		" | Estado: ",
		message["state"],
		" | Jugadores: ",
		message["players"]
	)


func finish_discovery() -> void:
	searching = false
	udp.close()

	if discovered_servers.is_empty():
		print("No se encontraron servidores.")
		print(
			"Respaldo UDP unicast: --ip=<IP_DEL_SERVIDOR>. ",
			"Respaldo TCP directo: --ip=<IP_DEL_SERVIDOR> --port=<PUERTO_TCP>."
		)
		return

	print("Servidores disponibles:")

	for index in range(discovered_servers.size()):
		var server := discovered_servers[index]

		print(
			"[", index, "] ",
			server["name"],
			" - ",
			server["ip"],
			":",
			server["tcp_port"],
			" - ",
			server["state"],
			" - jugadores: ",
			server["players"]
		)

	select_server()


func select_server() -> void:
	var selected_index := get_requested_server_index()

	if selected_index < 0 or selected_index >= discovered_servers.size():
		selected_index = 0

	var selected := discovered_servers[selected_index]

	print(
		"Servidor seleccionado: [",
		selected_index,
		"] ",
		selected["name"],
		" - ",
		selected["ip"],
		":",
		selected["tcp_port"]
	)

	server_selected.emit(
		selected["ip"],
		selected["tcp_port"]
	)


func get_requested_server_index() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--server-index="):
			return int(argument.get_slice("=", 1))

	return 0


func is_protocol_integer(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false

	var numeric_value: float = float(value)
	return numeric_value == floor(numeric_value)
