extends Node
class_name StartGame

@onready var card_panel: Node2D = $".."
@onready var install_component: InstallComponent = $"../InstallComponent"
@onready var game_card: GameCard = $"../GameCard"

var game_name : String 
var user_path : String
var boot_path

func _ready() -> void:
	game_name = install_component.game_name
	user_path = install_component.user_path
	
func start_game() -> void :
	pass
