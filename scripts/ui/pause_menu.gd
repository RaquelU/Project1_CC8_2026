extends Control

@onready var server_browser: Control = get_node("../ServerBrowser")
@onready var resume_button: Button = %ResumeButton
@onready var return_to_menu_button: Button = %ReturnToMenuButton


func _ready() -> void:
	visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	return_to_menu_button.pressed.connect(_on_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if server_browser.visible:
		return

	if visible:
		resume()
	else:
		open_pause_menu()

	get_viewport().set_input_as_handled()


func open_pause_menu() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func resume() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_resume_pressed() -> void:
	resume()


func _on_quit_pressed() -> void:
	get_tree().quit()
