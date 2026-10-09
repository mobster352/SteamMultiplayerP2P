class_name Game
extends Node

@onready var level: Node3D = %Level
@onready var lobby: Control = %Lobby
var test_level:TestLevel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func spawn_test_level(peer:int) -> void:
	if not multiplayer.is_server():
		return
	test_level = preload("uid://citkhk08xrhj5").instantiate()
	test_level.peer = peer #player2
	test_level.name = "TestLevel"
	level.add_child(test_level, true)


@rpc("any_peer", "call_remote")
func add_peer(id:int) -> void:
	if test_level:
		test_level.add_peer(id)
