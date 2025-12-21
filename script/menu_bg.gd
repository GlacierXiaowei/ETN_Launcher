extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$white_bg_animation.play("white_bg_animation")
	
	await get_tree().create_timer(2.5).timeout 
	
	
	$white_bg_animation.play("blur_animation")
	#blur_animation 是循环动画
	#考虑一直循环 
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
