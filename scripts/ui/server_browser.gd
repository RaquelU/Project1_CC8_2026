extends Control

@onready var player_name_input: LineEdit = %PlayerNameInput
@onready var search_button: Button = %SearchButton
@onready var search_status_label: Label = %SearchStatusLabel
@onready var server_list: ItemList = %ServerList
@onready var connect_button: Button = %ConnectButton
@onready var manual_ip_input: LineEdit = %ManualIpInput
@onready var discover_ip_button: Button = %DiscoverIpButton
@onready var manual_port_input: LineEdit = %ManualPortInput
@onready var direct_connect_button: Button = %DirectConnectButton

@onready var network_client: Node = get_node("../../NetworkClient")
@onready var server_discovery: Node = get_node("../../ServerDiscovery")

var servers: Array[Dictionary] = []


func _ready() -> void:
	network_client.connection_completed.connect(_on_connection_completed)
	network_client.connection_failed.connect(_on_connection_failed)
	search_button.pressed.connect(_on_search_pressed)
	connect_button.pressed.connect(_on_connect_pressed)
	discover_ip_button.pressed.connect(_on_discover_ip_pressed)
	direct_connect_button.pressed.connect(_on_direct_connect_pressed)

	server_discovery.discovery_finished.connect(_on_discovery_finished)

	connect_button.disabled = true
	search_status_label.text = "Presiona Buscar servidores."


func _on_search_pressed() -> void:
	servers.clear()
	server_list.clear()
	connect_button.disabled = true

	search_status_label.text = "Buscando servidores..."
	search_button.disabled = true

	server_discovery.start_discovery()


func _on_discovery_finished(found_servers: Array[Dictionary]) -> void:
	search_button.disabled = false
	servers = found_servers

	server_list.clear()

	if servers.is_empty():
		search_status_label.text = "No se encontraron servidores."
		connect_button.disabled = true
		return

	for server in servers:
		var description := "%s | %s:%s | %s | %s jugadores" % [
			server["name"],
			server["ip"],
			server["tcp_port"],
			server["state"],
			server["players"]
		]

		server_list.add_item(description)

	server_list.select(0)
	connect_button.disabled = false
	search_status_label.text = "Servidores encontrados: %s" % servers.size()


func _on_connect_pressed() -> void:
	var selected_items := server_list.get_selected_items()

	if selected_items.is_empty():
		search_status_label.text = "Selecciona un servidor."
		return

	var selected_index := selected_items[0]

	if selected_index < 0 or selected_index >= servers.size():
		search_status_label.text = "Servidor seleccionado inválido."
		return

	var selected_server := servers[selected_index]

	apply_player_name()

	search_status_label.text = "Conectando con %s..." % selected_server["name"]

	connect_button.disabled = true
	search_button.disabled = true
	
	network_client.connect_with_address(
		str(selected_server["ip"]),
		int(selected_server["tcp_port"])
	)


func _on_discover_ip_pressed() -> void:
	var ip := manual_ip_input.text.strip_edges()

	if not server_discovery.is_valid_ipv4(ip):
		search_status_label.text = "La dirección IP no es válida."
		return

	servers.clear()
	server_list.clear()
	connect_button.disabled = true

	search_status_label.text = "Buscando servidor en %s..." % ip

	server_discovery.start_unicast_discovery(ip)


func _on_direct_connect_pressed() -> void:
	var ip := manual_ip_input.text.strip_edges()
	var port_text := manual_port_input.text.strip_edges()

	if not server_discovery.is_valid_ipv4(ip):
		search_status_label.text = "La dirección IP no es válida."
		return

	if not port_text.is_valid_int():
		search_status_label.text = "El puerto no es válido."
		return

	var port := int(port_text)

	if port <= 0 or port > 65535:
		search_status_label.text = "El puerto debe estar entre 1 y 65535."
		return

	apply_player_name()

	search_status_label.text = "Conectando directamente con %s:%s..." % [
		ip,
		port
	]

	direct_connect_button.disabled = true
	discover_ip_button.disabled = true
	
	network_client.connect_with_address(ip, port)


func _on_connection_failed(reason: String) -> void:
	var messages := {
		"TIMEOUT": "No se pudo conectar: tiempo de espera agotado.",
		"CONNECTION_ERROR": "No se pudo conectar con el servidor.",
		"CONNECT_FAILED": "No se pudo iniciar la conexión.",
	}

	search_status_label.text = messages.get(reason, "No se pudo conectar con el servidor.")

	search_button.disabled = false
	discover_ip_button.disabled = false
	direct_connect_button.disabled = false
	connect_button.disabled = servers.is_empty()


func apply_player_name() -> void:
	var selected_name := player_name_input.text.strip_edges()

	if selected_name.is_empty():
		selected_name = "Jugador"

	network_client.player_name = selected_name


func _on_connection_completed() -> void:
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func reset_and_show() -> void:
	servers.clear()
	server_list.clear()

	connect_button.disabled = true
	search_button.disabled = false
	discover_ip_button.disabled = false
	direct_connect_button.disabled = false

	search_status_label.text = "Presiona Buscar servidores."

	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
