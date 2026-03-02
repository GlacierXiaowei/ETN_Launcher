extends Button
class_name GameCard

signal card_selected()
signal card_deselected()
signal card_hover_started()
signal card_hover_ended()

@export var card_scale: float = 0.5
@export var angle_x_max: float = 8.0
@export var angle_y_max: float = 8.0
@export var poster_texture: Texture2D

@onready var card_float_component: CardFloatComponent = $CardFloatComponent
@onready var shadow_component: CardShadowComponent = $CardShadowComponent
@onready var card_drag_component: CardDragComponent = $CardDragComponent
@onready var visual_component: Card3DVisualComponent = $Card3DVisualComponent
@onready var card_texture_rect: TextureRect = $CardTexture
@onready var shadow: TextureRect = $Shadow

var _last_drag_pos: Vector2
var _drag_velocity: Vector2

var _is_selected: bool = false
var _tween_hover: Tween
#var _tween_rot: Tween
var _current_rot_x: float = 0.0
var _current_rot_y: float = 0.0

# 添加变量
var _click_start_pos: Vector2 = Vector2.ZERO
var _is_potential_click: bool = false
var _click_threshold: float = 10.0  # 移动阈值（像素）



func _ready() -> void:
	print("[GameCard] _ready() - 初始化完成")
	angle_x_max = deg_to_rad(angle_x_max)
	angle_y_max = deg_to_rad(angle_y_max)
	_update_card_size()
	_setup_texture()
	_center_in_viewport()



@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	card_drag_component.process_drag()
	# 如果在拖拽中，计算速度并应用3D旋转,同时阻止篇幅（否则功能异常）
	if card_drag_component.is_dragging():
		_update_drag_rotation(delta)

func _update_hover_tilt() -> void:
	var mouse_pos: Vector2 = get_local_mouse_position()
	var lerp_val_x: float = remap(mouse_pos.x, 0.0, size.x, 0.0, 1.0)
	var lerp_val_y: float = remap(mouse_pos.y, 0.0, size.y, 0.0, 1.0)
	
	var target_rot_x: float = lerp_angle(-angle_x_max, angle_x_max, lerp_val_x)
	var target_rot_y: float = lerp_angle(angle_y_max, -angle_y_max, lerp_val_y)

	visual_component.set_rotation_3d(rad_to_deg(target_rot_y), rad_to_deg(target_rot_x))



func _update_drag_rotation(delta: float) -> void:
	var current_pos: Vector2 = global_position
	_drag_velocity = (current_pos - _last_drag_pos) / delta
	_last_drag_pos = current_pos
	visual_component.set_rotation_from_velocity(_drag_velocity, rad_to_deg(angle_x_max))


func _update_card_size() -> void:
	var viewport_size = get_viewport_rect().size
	var target_width = viewport_size.x * card_scale
	var target_height = target_width * (9.0 / 16.0)
	custom_minimum_size = Vector2(target_width, target_height)

	
	if visual_component:
		visual_component.update_rect_size(custom_minimum_size)

func _setup_texture() -> void:
	if poster_texture and visual_component:
		visual_component.set_poster_texture(poster_texture)
		print("[GameCard] 海报纹理已设置")

func _center_in_viewport() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	global_position = (viewport_size - size) / 2.0
	card_float_component.set_base_position(global_position)
	card_float_component.set_base_position(global_position)

func _on_mouse_entered() -> void:
	card_float_component.disable_float()
	print("[GameCard] 鼠标进入 -")

	card_hover_started.emit()
	
	if _tween_hover and _tween_hover.is_running():
		_tween_hover.kill()
	_tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_tween_hover.tween_property(self, "scale", Vector2(1.075, 1.075), 0.4)


func _on_mouse_exited() -> void:
	print("[GameCard] 鼠标离开 - 发射 card_deselected")
	card_deselected.emit()
	card_hover_ended.emit()
	
	if _tween_hover and _tween_hover.is_running():
		_tween_hover.kill()
	_tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_tween_hover.tween_property(self, "scale", Vector2.ONE, 0.75)
	
	# 使用 visual_component 重置旋转
	if visual_component:
		visual_component.reset_rotation()
	_current_rot_x = 0.0
	_current_rot_y = 0.0
	
	await _tween_hover.finished
	card_float_component.set_base_position(global_position)
	card_float_component.enable_float()
func _on_gui_input(event: InputEvent) -> void:
	_check_click_event(event)
	shadow_component.update_shadow_position()
	card_drag_component.handle_input(event)
	

	if not event is InputEventMouseMotion:
		return
	
	var mouse_pos: Vector2 = get_local_mouse_position()
	var lerp_val_x: float = remap(mouse_pos.x, 0.0, size.x, 0.0, 1.0)
	var lerp_val_y: float = remap(mouse_pos.y, 0.0, size.y, 0.0, 1.0)
	
	var target_rot_x: float = lerp_angle(-angle_x_max, angle_x_max, lerp_val_x)
	var target_rot_y: float = lerp_angle(angle_y_max, -angle_y_max, lerp_val_y)
	
	_current_rot_x = target_rot_x
	_current_rot_y = target_rot_y
	
	if visual_component:
		visual_component.set_rotation_3d(rad_to_deg(_current_rot_y), rad_to_deg(_current_rot_x))


# 封装函数
func _check_click_event(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	
	if event.is_pressed():
		_is_potential_click = true
		_click_start_pos = get_global_mouse_position()
	elif event.is_released() and _is_potential_click:
		var moved = get_global_mouse_position().distance_to(_click_start_pos)
		if moved < _click_threshold:
			card_selected.emit()
		_is_potential_click = false


func deselect() -> void:
	_is_selected = false
	print("[GameCard] deselect() 被调用")

func is_selected() -> bool:
	return _is_selected


func _on_card_drag_component_drag_ended() -> void:
	# 先更新基准位置
	_last_drag_pos = global_position  
	card_float_component.set_base_position(global_position)  
	card_float_component.enable_float()


func _on_card_drag_component_drag_started() -> void:
	_last_drag_pos = global_position
	card_float_component.disable_float()


func _on_card_selected() -> void:
	print("检测到点击")
