class_name Game
extends Node

@onready var level: Node3D = %Level
@onready var lobby: Control = %Lobby

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func spawn_test_level(peer:int) -> void:
	if not multiplayer.is_server():
		return
	var test_level:TestLevel = preload("uid://citkhk08xrhj5").instantiate()
	test_level.peer = peer
	test_level.name = "TestLevel"
	level.add_child(test_level, true)
