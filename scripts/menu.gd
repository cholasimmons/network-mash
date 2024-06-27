extends CanvasLayer

signal menu_decision_host
signal menu_decision_join
signal menu_decision_start

@onready var host_btn: Button = $VBoxContainer/HBoxContainer/Host
@onready var join_btn: Button = $VBoxContainer/HBoxContainer/Join
@onready var start_btn: Button = $VBoxContainer/Start
@onready var player_name: LineEdit = $VBoxContainer/HBoxContainer2/Name
@onready var player_color: ColorPickerButton = $VBoxContainer/HBoxContainer2/Color

var player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	host_btn.pressed.connect(_on_host_button_pressed)
	join_btn.pressed.connect(_on_join_button_pressed)
	start_btn.pressed.connect(_on_start_button_pressed)
	start_btn.disabled = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_host_button_pressed():
	#host_btn.disabled = true
	if verify_details():
		emit_signal("menu_decision_host", player)

func _on_join_button_pressed():
	#join_btn.disabled = true
	if verify_details():
		emit_signal("menu_decision_join", player)

func _on_start_button_pressed():
	#start_btn.disabled = true
	if verify_details():
		emit_signal("menu_decision_start", player)

func verify_details() -> bool:
	if player_name.text.length() < 3:
		print("Name too short")
		return false
	else:
		player = {
			"name": player_name.text,
			"color": player_color.color
		}
		return true

func on_game_is_hosted():
	host_btn.disabled = true
	start_btn.disabled = false
	if is_multiplayer_authority():
		player_name.hide()
		player_color.hide()
