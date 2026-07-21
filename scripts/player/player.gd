extends CharacterBody3D

const MOUSE_SENSITIVITY := 0.002
const DIRECTION_THRESHOLD := 0.35
const INTERPOLATION_SPEED := 12.0

@onready var camera_pivot: Node3D = $CameraPivot

var network_client: Node
var target_position := Vector3.ZERO


func _ready() -> void:
	add_to_group("local_player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	target_position = global_position

	call_deferred("find_network_client")


func find_network_client() -> void:
	network_client = get_tree().get_first_node_in_group("network_client")
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)

		camera_pivot.rotation.x = clamp(
			camera_pivot.rotation.x,
			deg_to_rad(-80.0),
			deg_to_rad(80.0)
		)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("interact") and network_client:
		network_client.send_interact()
		
func _physics_process(delta: float) -> void:
	if network_client:
		network_client.send_input(get_network_direction())

	global_position.x = lerp(
		global_position.x,
		target_position.x,
		min(1.0, INTERPOLATION_SPEED * delta)
	)

	global_position.z = lerp(
		global_position.z,
		target_position.z,
		min(1.0, INTERPOLATION_SPEED * delta)
	)
	
func get_network_direction() -> Vector2:
	var input := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
        "move_backward"
	)

	if input == Vector2.ZERO:
		return Vector2.ZERO

	var direction := (
		transform.basis.x * input.x
		+ transform.basis.z * input.y
	).normalized()

	return Vector2(
		convert_axis(direction.x),
		convert_axis(direction.z)
	)


func convert_axis(value: float) -> int:
	if abs(value) < DIRECTION_THRESHOLD:
		return 0

	return 1 if value > 0.0 else -1
	
func set_network_position(new_position: Vector3) -> void:
	target_position.x = new_position.x
	target_position.z = new_position.z
