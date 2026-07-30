extends PanelContainer

## Panel pequeño para la esquina superior derecha que muestra la misma
## información relevante que se imprime en la terminal, más la lista de
## jugadores conectados. La terminal se sigue usando para depurar errores,
## pero ya no hace falta mirarla durante el juego normal.

const MAX_LOG_LINES := 10

@export var panel_title := "Registro"

@onready var title_label: Label = %TitleLabel
@onready var log_text: RichTextLabel = %LogText
@onready var players_text: RichTextLabel = %PlayersText

var log_lines: Array[String] = []


func _ready() -> void:
	title_label.text = panel_title
	players_text.text = "(nadie conectado)"


func add_log(text: String) -> void:
	var timestamp := Time.get_time_string_from_system()
	log_lines.append("[%s] %s" % [timestamp, text])

	while log_lines.size() > MAX_LOG_LINES:
		log_lines.remove_at(0)

	log_text.text = "\n".join(log_lines)
	log_text.scroll_to_line(log_text.get_line_count())


func set_players(names: Array) -> void:
	if names.is_empty():
		players_text.text = "(nadie conectado)"
		return

	var lines: Array[String] = []

	for player_name in names:
		lines.append("• %s" % str(player_name))

	players_text.text = "\n".join(lines)
