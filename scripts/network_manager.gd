extends Node

signal update_lobby_code(lobby_code:String)
signal join_host_lobby(lobby_id:int)

## Has a mapping of {unique code:steam lobby}[br][br]
var active_lobbies:Dictionary
var active_hosts:Dictionary

func _generate_lobby_code() -> String:
	var random_code:int = randi_range(100000,999999)
	var code:String = str(random_code)
	if active_lobbies.has(random_code):
		code = _generate_lobby_code()
	return code

@rpc("any_peer")
func create_lobby_code(peer:int, lobby_id:int) -> void:
	var code:String = _generate_lobby_code()
	active_lobbies.set(code, lobby_id)
	#Steam.setLobbyData(lobby_id, "lobby_code", code)
	send_lobby_code.rpc_id(peer, code)

@rpc
func send_lobby_code(lobby_code:String) -> void:
	update_lobby_code.emit(lobby_code)

@rpc("any_peer")
func find_lobby(peer:int, lobby_code:String) -> void:
	if active_lobbies.has(lobby_code):
		send_lobby_id.rpc_id(peer, active_lobbies.get(lobby_code), lobby_code)

@rpc
func send_lobby_id(lobby_id:int, lobby_code:String) -> void:
	join_host_lobby.emit(lobby_id)
	update_lobby_code.emit(lobby_code)
