extends MultiplayerSynchronizer

@onready var player: Player = $".."

var input_direction:Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_multiplayer_authority() != multiplayer.multiplayer_peer.get_unique_id():
		set_process(false)
		set_physics_process(false)
	input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")


func _physics_process(_delta: float) -> void:
	input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		jump.rpc()
		
@rpc("call_local")
func jump() -> void:
	if multiplayer.is_server():
		if player._is_on_floor:
			player.do_jump = true
