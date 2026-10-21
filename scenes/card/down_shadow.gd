extends Node2D


var _tween_click_position : Tween
##控制淡入淡出的
var _tween_click_modulate : Tween

@onready var texture_rect: TextureRect = $TextureRect
@onready var state_label: Label = $StateLabel



func _ready() -> void:
	texture_rect.modulate.a = 0.0
	state_label.modulate.a = 0.0

func _on_game_card_card_deselected() -> void:
	
	if _tween_click_modulate and _tween_click_modulate.is_running():
		_tween_click_modulate.kill()
	_tween_click_modulate = create_tween()
	_tween_click_modulate.set_ease(Tween.EASE_OUT)
	_tween_click_modulate.set_trans(Tween.TRANS_BACK)
	_tween_click_modulate.tween_property(state_label, "modulate:a", 0.0, 0.5)
	
	if _tween_click_position and _tween_click_position.is_running():
		_tween_click_position.kill()
	_tween_click_position = create_tween()
	_tween_click_position.set_ease(Tween.EASE_OUT)
	_tween_click_position.set_trans(Tween.TRANS_BACK)  # 优雅的回弹效果
	_tween_click_position.tween_property(texture_rect, "modulate:a", 0.0, 0.7)


func _on_game_card_card_selected() -> void:
	if _tween_click_modulate and _tween_click_modulate.is_running():
		_tween_click_modulate.kill()
	_tween_click_modulate = create_tween()
	_tween_click_modulate.set_ease(Tween.EASE_OUT)
	_tween_click_modulate.set_trans(Tween.TRANS_BACK)
	_tween_click_modulate.tween_property(state_label, "modulate:a", 1.0, 0.7)
	
	if _tween_click_position and _tween_click_position.is_running():
		_tween_click_position.kill()
	_tween_click_position = create_tween()
	_tween_click_position.set_ease(Tween.EASE_OUT)
	_tween_click_position.set_trans(Tween.TRANS_BACK)
	_tween_click_position.tween_property(texture_rect, "modulate:a", 1.0, 0.5)
