extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_add_button_to_buttongroup()
	

func _add_button_to_buttongroup() -> void :
	var button_group=ButtonGroup.new()
	for i in $VBoxContainer.get_children():
		if i is Button:
			i.button_group=button_group
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
	
