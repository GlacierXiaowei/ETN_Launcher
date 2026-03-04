extends NodeState

@onready var card_panel: Node2D = $"../.."
@onready var state_label: Label = $"../../StateLabel"
@onready var install_component: InstallComponent = $"../../InstallComponent"


var title: String
var content : String
var buttons : Array

func _on_enter() -> void:
	state_label.text = "启动游戏"


func _on_card_confirm() -> void:
	card_panel._start_game()
	transition.emit("runningstate")
