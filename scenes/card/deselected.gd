extends GlassIconPanel


var _tween_click_scale : Tween
##控制淡入淡出的
var _tween_click_modulate : Tween

func _on_game_card_card_selected() -> void:
	
	disabled = false
	
	if _tween_click_modulate and _tween_click_modulate.is_running():
		_tween_click_modulate.kill()
	_tween_click_modulate = create_tween()
	_tween_click_modulate.set_ease(Tween.EASE_OUT)
	_tween_click_modulate.set_trans(Tween.TRANS_BACK)
	_tween_click_modulate.tween_property(self, "modulate:a", 1.0, 0.3)
	
	if _tween_click_scale and _tween_click_scale.is_running():
		_tween_click_scale.kill()
	_tween_click_scale = create_tween()
	_tween_click_scale.set_ease(Tween.EASE_OUT)
	_tween_click_scale.set_trans(Tween.TRANS_BACK)  # 优雅的回弹效果
	_tween_click_scale.tween_property(self, "scale", Vector2.ONE, 0.4)


func _on_game_card_card_deselected() -> void:
	
	disabled = true
	
	if _tween_click_modulate and _tween_click_modulate.is_running():
		_tween_click_modulate.kill()
	_tween_click_modulate = create_tween()
	_tween_click_modulate.set_ease(Tween.EASE_OUT)
	_tween_click_modulate.set_trans(Tween.TRANS_BACK)
	_tween_click_modulate.tween_property(self, "modulate:a", 0.0, 0.3)
	
	if _tween_click_scale and _tween_click_scale.is_running():
		_tween_click_scale.kill()
	_tween_click_scale = create_tween()
	_tween_click_scale.set_ease(Tween.EASE_OUT)
	_tween_click_scale.set_trans(Tween.TRANS_BACK)  # 优雅的回弹效果
	_tween_click_scale.tween_property(self, "scale", Vector2(0.2,0.2), 0.4)
	
