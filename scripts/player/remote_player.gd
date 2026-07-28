extends CharacterBody3D

const INTERPOLATION_SPEED := 12.0

var target_position := Vector3.ZERO


func _ready() -> void:
	add_to_group("remote_player")
	target_position = global_position


func _physics_process(delta: float) -> void:
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


func set_network_position(new_position: Vector3) -> void:
	target_position.x = new_position.x
	target_position.z = new_position.z
