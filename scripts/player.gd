class_name Player
extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var player_id:int:
	set(id):
		player_id = id
		%MultiplayerInput.set_multiplayer_authority(id)
		
@export var do_jump:bool
@export var _is_on_floor:bool
@export var input_dir: Vector2

func _ready() -> void:
	if multiplayer.get_unique_id() == player_id:
		%Camera3D.make_current()
	else:
		%Camera3D.current = false

func _apply_movement(delta:float) -> void:
	# Add the gravity.
	if not _is_on_floor:
		velocity += get_gravity() * delta

	# Handle jump.
	if do_jump and _is_on_floor:
		velocity.y = JUMP_VELOCITY
		do_jump = false

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	input_dir = %MultiplayerInput.input_direction 
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		_is_on_floor = is_on_floor()
		_apply_movement(delta)
