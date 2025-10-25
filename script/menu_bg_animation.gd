extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$white_bg_animation.play("white_bg_animation")
	$menu_music.play()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
