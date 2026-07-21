extends CharacterBody3D

const SPEED: float = 20.0
const GRAVITY: float = 30.0
const MOUSE_SENSITIVITY: float = 0.002
const MAP_MIN: float = -48.5
const MAP_MAX: float = 48.5
const INTERACTION_DISTANCE: float = 4.0
const CIRCLE_CENTER := Vector2.ZERO
const VICTORY_DISTANCE: float = 31.5

@onready var camera_pivot: Node3D = $CameraPivot
var has_flag: bool = false
var flag: Node3D
var game_finished: bool = false

	
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	flag = get_tree().get_first_node_in_group("flag")

	if flag:
		print("Bandera encontrada.")
	else:
		print("No se encontró la bandera.")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)

		camera_pivot.rotate_x(
			-event.relative.y * MOUSE_SENSITIVITY
		)

		camera_pivot.rotation.x = clamp(
			camera_pivot.rotation.x,
			deg_to_rad(-80.0),
			deg_to_rad(80.0)
		)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if event.is_action_pressed("interact"):
		try_to_take_flag()


func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	move_player()
	move_and_slide()
	clamp_position_to_map()
	check_victory()


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0


func move_player() -> void:
	if game_finished:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
        "move_backward"
	)

	var direction := (
		transform.basis.x * input_direction.x
		+ transform.basis.z * input_direction.y
	)

	direction.y = 0.0
	direction = direction.normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0.0
		velocity.z = 0.0

func clamp_position_to_map() -> void:
	global_position.x = clamp(global_position.x, MAP_MIN, MAP_MAX)
	global_position.z = clamp(global_position.z, MAP_MIN, MAP_MAX)

func try_to_take_flag() -> void:
	if has_flag:
		return

	if not is_instance_valid(flag):
		print("No se encontró la bandera.")
		return

	var player_position_2d := Vector2(
		global_position.x,
		global_position.z
	)

	var flag_position_2d := Vector2(
		flag.global_position.x,
		flag.global_position.z
	)

	var distance_to_flag := player_position_2d.distance_to(
		flag_position_2d
	)

	if distance_to_flag > INTERACTION_DISTANCE:
		print("La bandera está demasiado lejos.")
		return

	has_flag = true

	flag.reparent(self)
	flag.position = Vector3(1.2, 1.8, -1.5)

	print("Bandera capturada.")
	
func check_victory() -> void:
	if game_finished or not has_flag:
		return

	var player_position_2d := Vector2(
		global_position.x,
		global_position.z
	)

	var distance_to_center := player_position_2d.distance_to(
		CIRCLE_CENTER
	)

	if distance_to_center > VICTORY_DISTANCE:
		game_finished = true
		velocity = Vector3.ZERO
		print("¡Victoria! El jugador salió completamente del círculo con la bandera.")
