extends Node

##背景缩放动画 注意所有的动画都绑定在两个函数上 我们只需要管理Textrue的visibility
@onready var zhe_zhao: ColorRect = $"../../ZheZhao"
@onready var bg: Control = $"../../BG"
@export var main_menu: Control 

@onready var setting_panel: Control = $"../../SettingPanel"

var bg_arr : Array
@onready var texture_rect: TextureRect = $"../../BG/TextureRect"
@onready var texture_rect_2: TextureRect = $"../../BG/TextureRect2"
@onready var texture_rect_3: TextureRect = $"../../BG/TextureRect3"

var card_arr : Array
@onready var card_panel: Control = $"../../CardPanel"
@onready var card_panel_2: Control = $"../../CardPanel2"
@onready var card_panel_3: Control = $"../../CardPanel3"

@onready var blur_overlay: ColorRect = $"../../BG/BlurOverlay"

var _tween_click_scale : Tween
var _tween_bg_1 : Tween
var _tween_bg_2 : Tween
var _tween_blur : Tween
var _tween_card : Tween
var _tween_setting : Tween

func _ready() -> void:
	bg_arr = [texture_rect ,texture_rect_2 ,texture_rect_3]
	card_arr = [card_panel, card_panel_2, card_panel_3]

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
	if target_page == 0:
		turn_to_setting()
		return
	
	current_page = current_page -1
	target_page = target_page -1
	
	# 禁用卡面交互和漂浮组件
	card_arr[current_page].control_effect(false)
	card_arr[target_page].control_effect(false)
	
	## 背景切换动画（模糊峰值时切换可见性）
	bg_arr[current_page].visible = true
	bg_arr[target_page].visible = true
	bg_arr[target_page].scale = Vector2(1,1)
	
	## 模糊动画：2.0 → 5.0 → 2.0
	_tween_blur = create_tween()
	_tween_blur.tween_property(blur_overlay.material, "shader_parameter/blur_amount", 5.0, 0.25)
	_tween_blur.tween_callback(_switch_background.bind(current_page, target_page))
	_tween_blur.tween_property(blur_overlay.material, "shader_parameter/blur_amount", 2.0, 0.25)
	
	## 卡面位移动画
	var card_pos_up : = Vector2(0, -1080)
	var card_pos_down : = Vector2(0, 1080)
	if current_page > target_page:
		var temp = card_pos_up
		card_pos_up = card_pos_down
		card_pos_down = temp
	
	card_arr[current_page].visible = true
	card_arr[current_page].position = Vector2.ZERO
	card_arr[target_page].visible = true
	card_arr[target_page].position = card_pos_down
	card_arr[target_page].modulate.a = 1.0
	
	_tween_card = create_tween()
	_tween_card.set_ease(Tween.EASE_OUT)
	_tween_card.set_parallel()
	_tween_card.tween_property(card_arr[current_page], "position", card_pos_up, 0.5).set_trans(Tween.TRANS_BACK)
	_tween_card.tween_property(card_arr[target_page], "position", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_BACK)
	
	## 等待卡面动画完成后清理
	await _tween_card.finished
	card_arr[current_page].visible = false
	
	# 恢复卡面交互和漂浮组件
	card_arr[current_page].control_effect(true)
	card_arr[target_page].control_effect(true)


func turn_to_setting() -> void:
	zhe_zhao.mouse_filter = Control.MOUSE_FILTER_STOP
	
	setting_panel.enter_outer_setting.emit()
	if _tween_setting and _tween_setting.is_running():
		_tween_setting.kill()
	_tween_setting = create_tween()
	_tween_setting.set_ease(Tween.EASE_OUT)
	#_tween_setting.set_trans(Tween.TRANS_BACK)  # 优雅的回弹效果
	_tween_setting.tween_property(setting_panel, "position", Vector2.ZERO, 0.3)
	
	await _tween_setting.finished
	zhe_zhao.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_setting_panel_exit_outer_setting() -> void:
	zhe_zhao.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if _tween_setting and _tween_setting.is_running():
		_tween_setting.kill()
	_tween_setting = create_tween()
	_tween_setting.set_ease(Tween.EASE_OUT)
	#_tween_setting.set_trans(Tween.TRANS_BACK)  # 优雅的回弹效果
	_tween_setting.tween_property(setting_panel, "position", Vector2(0,-1080), 0.3)
	
	await _tween_setting.finished
	zhe_zhao.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _switch_background(current_idx: int, target_idx: int) -> void:
	## 模糊峰值时切换背景可见性
	bg_arr[current_idx].visible = false
	bg_arr[target_idx].scale = Vector2(1,1)
