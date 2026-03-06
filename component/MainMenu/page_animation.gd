extends Node

##背景缩放动画 注意所有的动画都绑定在两个函数上 我们只需要管理Textrue的visibility
@onready var bg: Control = $"../../BG"

var bg_arr : Array
@onready var texture_rect: TextureRect = $"../../BG/TextureRect"
@onready var texture_rect_2: TextureRect = $"../../BG/TextureRect2"
@onready var texture_rect_3: TextureRect = $"../../BG/TextureRect3"

var _tween_click_scale : Tween
var _tween_bg_1 : Tween
var _tween_bg_2 : Tween

func _ready() -> void:
	bg_arr = [texture_rect ,texture_rect_2 ,texture_rect_3]

func _on_card_panel_card_selected() -> void:
	
	if _tween_click_scale and _tween_click_scale.is_running():
		_tween_click_scale.kill()
	_tween_click_scale = create_tween()
	_tween_click_scale.set_ease(Tween.EASE_OUT)
	#_tween_click_scale.set_trans(Tween.TRANS_BACK)  # 优雅的回弹效果
	_tween_click_scale.tween_property(bg, "scale", Vector2(1.25,1.25), 3.00)


func _on_card_panel_card_deselected() -> void:
	if _tween_click_scale and _tween_click_scale.is_running():
		_tween_click_scale.kill()
	_tween_click_scale = create_tween()
	_tween_click_scale.set_ease(Tween.EASE_IN)
	#_tween_click_scale.set_trans(Tween.TRANS_BACK)  # 优雅的回弹效果
	_tween_click_scale.tween_property(bg, "scale", Vector2(1,1), 0.15)


func turn_to_page(current_page: int,target_page : int):
	current_page = current_page -1
	target_page = target_page -1
	
	var pos_up : = Vector2(0,-1080)
	var pos_down : = Vector2(0, 1080)
	if current_page > target_page :
		var temp = pos_up
		pos_up = pos_down
		pos_down = temp
		
	bg_arr[current_page].visible = true
	bg_arr[target_page].visible = true
	
	bg_arr[target_page].scale = Vector2(0.1,0.1)
	_tween_bg_1 = create_tween()
	_tween_bg_1.set_ease(Tween.EASE_OUT)
	_tween_bg_1.tween_property(bg_arr[target_page], "position",
	 Vector2.ZERO, 0.6).set_trans(Tween.TRANS_SINE)
	_tween_bg_1.tween_property(bg_arr[target_page],  "scale", Vector2.ONE, 0.6)
	
	_tween_bg_2 = create_tween()
	_tween_bg_2.set_ease(Tween.EASE_OUT)
	_tween_bg_2.set_trans(Tween.TRANS_SINE)
	_tween_bg_2.tween_property(bg_arr[current_page], "position",
	 pos_up, 0.6).set_trans(Tween.TRANS_SINE)
	_tween_bg_2.tween_property(bg_arr[current_page],  "scale", Vector2(0.1,0.1), 0.6)
	await _tween_bg_2.finished
	bg_arr[current_page].visible = false
