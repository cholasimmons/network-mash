# NetworkManager.gd
extends Node2D

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)

@export var player_scene: PackedScene = load("res://scenes/Player.tscn")

const MAX_PLAYERS :int = 8
const PORT = 9810
const LOBBY_NAME = "Maliyo Lobby"
const COMPRESSION_TYPE:ENetConnection.CompressionMode = ENetConnection.COMPRESS_RANGE_CODER

var peer:ENetMultiplayerPeer
var default_server_ip = "127.0.0.1"
var menu : CanvasLayer





func _ready():
	menu = $Menu
	menu.connect("menu_decision_host", _on_host_pressed)
	menu.connect("menu_decision_join", _on_join_pressed)
	menu.connect("menu_decision_start", _on_start_pressed)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	#multiplayer.server_disconnected.connect(_on_server_disconnected)
	if multiplayer.is_server():
		print_once_per_client.rpc()

# HOST GAME

func _on_host_pressed(player):
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		print("Error creating host: ", error)
		return
	peer.get_host().compress(COMPRESSION_TYPE)
	multiplayer.set_multiplayer_peer(peer)
	print("Server created by %s. Waiting for Players" %player.name)
	send_player_information(player.name, player.color, multiplayer.get_unique_id())
	menu.on_game_is_hosted()
	#add_player()
	#player_connected.emit(1, player_info)
	#call_deferred("add_player")
	#menu.hide()

# JOIN GAME

func _on_join_pressed(player):
	var cnt = multiplayer.get_reference_count()
	if cnt < 1:
		print("cannot join empty lobby")
		return
	
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(default_server_ip, PORT)
	if error:
		print("Error connecting client: ", error)
		return error
	
	peer.get_host().compress(COMPRESSION_TYPE)
	multiplayer.set_multiplayer_peer(peer);
	send_player_information(player.name, player.color, multiplayer.get_unique_id())
	#add_player()
	print("Client connected. ", player)
	
	#menu.hide()

# START GAME

func _on_start_pressed():
	start_multiplayer_game.rpc()
	pass


# Called on Server and Client | Connected
func _on_peer_connected(playerr):
	#print("player connected: ", str(playerr.get_instance_id()))
	print("info: ",playerr)
	GameManager.active_players += 1
	
	#_register_player.rpc_id(id, player_info)
	var player:Node = player_scene.instantiate()
	var unique_id = player.get_instance_id()
	#print("ID: ", unique_id)
	print("Active Players: ", GameManager.active_players)
	#player.name = str(unique_id)
	#player.color = Color.DARK_RED
	#GameManager.players[playerr.id] = playerr
	
	var cnt = multiplayer.get_reference_count()
	if cnt == 1:
		set_multiplayer_authority(playerr)
	call_deferred("add_child", player)
	add_child(player)

# Called on Server and Client | Disconnected
func _on_player_disconnected(id:int):
	print("Player disconnected: ", id)

# Called only from Clients
func _on_connected_ok():
	print("Connected to server.")
	send_player_information.rpc(menu.player_name.text, Color.AQUAMARINE, multiplayer.get_unique_id())

# Called only from Clients
func _on_connected_fail():
	print("Connected to server.")

func exit_game(id):
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)
	# if no_more_players:
		# return to menu as fresh game
		# multiplayer.peer = null
	menu.join_btn.disabled = false
	menu.host_btn.disabled = false
	menu.show()

func del_player(id):
	print("Delete player Id: ", id)
	rpc("_del_player", id)

@rpc("any_peer", "call_local")
func _del_player(id):
	var player_node = get_node(str(id))
	if player_node:
		GameManager.active_players -= 1
		GameManager.players.erase(id)
		player_node.queue_free()
	else:
		print("Unable to delete Player: ", id)

@rpc
func print_once_per_client():
	GameManager.active_players += 1
	print("A client connected! %d Total" %GameManager.active_players)

@rpc("any_peer", "call_local", "reliable")
func player_loaded(data):
	print("A player loaded via RPC. ", data)
	GameManager.active_players += 1
	#if multiplayer.is_server():
		#players[active_players]
		#if active_players == players.size():
			#$/root/Game.start_game()
			#active_players = 0

@rpc("any_peer")
func send_player_information(name, color, id):
	if !GameManager.players.has(id):
		GameManager.players[id] = {
			"name": name, "color": color, "id": id
		}
	if multiplayer.is_server():
		for i in GameManager.players:
			send_player_information.rpc(GameManager.players[i].name, GameManager.players[i].color, i)
	menu.on_game_is_hosted()


#@rpc("any_peer", "reliable")
#func _register_player(new_player_info):
	#var new_player_id = multiplayer.get_remote_sender_id()
	#players[new_player_id] = new_player_info
	#player_connected.emit(new_player_id, new_player_info)
	#print("Player registered: ", new_player_info)

# Optimizations

# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_game(game_scene_path):
	var scene = load("res://scenes/TestScene.tscn")
	get_tree().change_scene_to_file(scene)


@rpc("call_local", "reliable")
func start_multiplayer_game():
	var scene = load("res://scenes/TestScene.tscn")
	get_tree().root.add_child(scene)
	hide()
