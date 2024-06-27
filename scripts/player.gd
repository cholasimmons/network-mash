# Player.gd
extends CharacterBody2D

@onready var camera = $Camera2D
@onready var tag_color :ColorRect = $Color
@onready var Lobby = get_parent()
@onready var label = $Label

var color :Color = Color.DARK_GREEN
var move_speed = 120
var rotation_speed = 3.0  # Speed of rotation
var thrust:Vector2 = Vector2.ZERO
var player_id: int

# creator

func _ready():
	#get_parent().get_node("MultiplayerSynchronizer").get_multiplayer_authority() == multiplayer.get_un
	player_id = name.to_int()
	tag_color.color = color
	# Set initial position of the label relative to the character
	#label.position = Vector2(0, -128)  # Adjust the Y-offset as needed to position the label above the character
	label.text = str(player_id)  # Replace with the actual text you want to display
	
	if is_multiplayer_authority():
		camera.make_current()
	
	#Lobby.player_loaded.rpc_id(player_id)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		# get_tree().create_timer(2)
		get_parent().exit_game(player_id)
		# get_tree().quit()

func handle_input(delta) -> void:
	if Input.is_action_pressed("ui_up"):
		thrust = Vector2(cos(rotation), sin(rotation))
	elif Input.is_action_pressed("ui_down"):
		thrust = Vector2(-cos(rotation), -sin(rotation))
	else:
		thrust = Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		rotation -= rotation_speed * delta
	elif Input.is_action_pressed("ui_right"):
		rotation += rotation_speed * delta

	velocity += (thrust.normalized() * move_speed) * delta
	move_and_slide()
	# Apply damping to slow down gradually
	velocity *= 0.999

		

func _process(delta):
	
	if is_multiplayer_authority():
		handle_input(delta)
	# Reset the label rotation to counteract the parent's rotation
	label.rotation = -rotation
	label.position = Vector2(0, -128).rotated(-rotation)  # Adjust the Y-offset as needed to position the label above the character

	# Synchronize position with the other player
	#rpc_unreliable("sync_position", global_position)

func _enter_tree():
	$MultiplayerSynchronizer.set_multiplayer_authority(name.to_int())

#@rpc
#func sync_position(pos):
	#global_position = pos
