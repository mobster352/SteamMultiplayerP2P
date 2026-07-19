extends Node

var steamworks:Steamworks
var steamworks_server:SteamworksServer

func _ready() -> void:
	if OS.has_feature("dedicated_server"):
		steamworks_server = preload("uid://cxftj83vrhqpa").new()
		steamworks_server.name = "SteamworksServer"
		add_child(steamworks_server)
	else:
		steamworks = preload("uid://be1vlyqrjcnm6").new()
		steamworks.name = "Steamworks"
		add_child(steamworks)
