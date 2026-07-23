# Nuevo script creado para poder hacer el descubrimiento de servidor
extends Node

signal server_selected(ip: String, port: int)

const DISCOVERY_PORT := 8888
const PROTOCOL_VERSION := 1
const SEARCH_TIME := 2.0

var udp := PacketPeerUDP.new()
var discovered_servers: Array[Dictionary] = []
var searching := false
var elapsed_time := 0.0


func start_discovery() -> void:
	discovered_servers.clear()
	elapsed_time = 0.0
	searching = true

	udp.close()

	var bind_result := udp.bind(0)

	if bind_result != OK:
		push_error("No se pudo abrir el socket UDP del cliente.")
		searching = false
		return

	udp.set_broadcast_enabled(true)
	udp.set_dest_address("255.255.255.255", DISCOVERY_PORT)

	var message := {
		"type": "discover",
		"v": PROTOCOL_VERSION
	}

	var result := udp.put_packet(
		JSON.stringify(message).to_utf8_buffer()
	)

	if result != OK:
		push_error("No se pudo enviar el mensaje discover.")
		searching = false
		return

	print("Buscando servidores por UDP...")


func _process(delta: float) -> void:
	if not searching:
		return

	read_responses()
	elapsed_time += delta

	if elapsed_time >= SEARCH_TIME:
		finish_discovery()


func read_responses() -> void:
	while udp.get_available_packet_count() > 0:
		var packet := udp.get_packet()
		var server_ip := udp.get_packet_ip()
		var text := packet.get_string_from_utf8()
		var message = JSON.parse_string(text)

		if typeof(message) != TYPE_DICTIONARY:
			continue

		if message.get("type") != "server_info":
			continue

		if message.get("v") != PROTOCOL_VERSION:
			continue

		register_server(server_ip, message)


func register_server(ip: String, message: Dictionary) -> void:
	var tcp_port := int(message.get("tcp_port", 0))

	if tcp_port <= 0:
		return

	for server in discovered_servers:
		if server["ip"] == ip and server["tcp_port"] == tcp_port:
			return

	discovered_servers.append({
		"ip": ip,
		"tcp_port": tcp_port,
		"name": str(message.get("name", "Servidor sin nombre")),
		"state": str(message.get("state", "unknown")),
		"players": int(message.get("players", 0))
	})

	print(
		"Servidor encontrado: ",
		message.get("name", "Servidor sin nombre"),
		" | IP: ",
		ip,
		" | TCP: ",
		tcp_port,
		" | Estado: ",
		message.get("state", "unknown"),
		" | Jugadores: ",
		message.get("players", 0)
	)


func finish_discovery() -> void:
	searching = false
	udp.close()

	if discovered_servers.is_empty():
		print("No se encontraron servidores.")
		return

	print("Servidores encontrados: ", discovered_servers.size())

	for index in range(discovered_servers.size()):
		var server := discovered_servers[index]

		print(
			"[", index, "] ",
			server["name"],
			" - ",
			server["ip"],
			":",
			server["tcp_port"]
		)

	select_server()


func select_server() -> void:
	var selected_index := get_requested_server_index()

	if selected_index < 0 or selected_index >= discovered_servers.size():
		selected_index = 0

	var selected := discovered_servers[selected_index]

	print(
		"Servidor seleccionado: ",
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
