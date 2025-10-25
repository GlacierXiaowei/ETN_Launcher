extends HBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	var button=Button.new()
	button.size=Vector2(128,128)
	$Container.add_child(button)
	pass # Replace with function body.


func _on_container_pre_sort_children():
	var _count=1
	for i in $Container.get_children():
		if i is Control:
			_count+=1
			$Container.fit_child_in_rect(i,Rect2(Vector2(64,64*_count),Vector2(70,70)))
	pass # Replace with function body.
