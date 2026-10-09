class_name TestLevel
extends Node3D

@onready var player_1_marker: Marker3D = %Player1Marker
@onready var player_2_marker: Marker3D = %Player2Marker
@onready var players: Node3D = %Players

var peer:int
var player2:Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not multiplayer.is_server():
		return
	add_player(multiplayer.multiplayer_peer.get_unique_id(), player_1_marker.global_transform)
	if peer > 0:
		player2 = add_player(peer, player_2_marker.global_transform)


func add_player(id:int, tf:Transform3D) -> Node3D:
	var player:Player = preload("uid://ddothv46uhrgu").instantiate()
	player.global_transform = tf
	player.name = str(id)
	player.player_id = id
	players.add_child(player, true)
	print("Player spawned: ", player.name)
	return player


func add_peer(id:int) -> void:
	peer = id
	player2 = add_player(peer, player_2_marker.global_transform)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
