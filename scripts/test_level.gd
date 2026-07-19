class_name TestLevel
extends Node3D

@onready var player_1_marker: Marker3D = %Player1Marker
@onready var player_2_marker: Marker3D = %Player2Marker
@onready var players: Node3D = %Players

var peer:int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not multiplayer.is_server():
		return
	add_player(multiplayer.multiplayer_peer.get_unique_id(), player_1_marker.global_transform)
	if peer:
		add_player(peer, player_2_marker.global_transform)


func add_player(id:int, tf:Transform3D) -> void:
	var player:Player = preload("uid://ddothv46uhrgu").instantiate()
	player.global_transform = tf
	player.name = str(id)
	player.player_id = id
	players.add_child(player, true)
	print("Player spawned: ", player.name)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
