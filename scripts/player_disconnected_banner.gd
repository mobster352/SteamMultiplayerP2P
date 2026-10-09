class_name PlayerDisconnectedBanner
extends Control

@export var label: Label

func update_player_name(player_name:String) -> void:
	label.text = player_name + " has disconnected from the game"
	show()
	await get_tree().create_timer(5.0).timeout
	hide()
