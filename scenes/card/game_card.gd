extends Button
class_name GameCard

signal card_selected()
signal card_deselected()
signal card_confirmed()
signal card_hover_started()
signal card_hover_ended()

@export var card_scale: float = 0.5
@export var angle_x_max: float = 8.0
@export var angle_y_max: float = 8.0
@export var poster_texture: Texture2D

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

func _ready() -> void:
	print("[GameCard] _ready() - 初始化完成")
	angle_x_max = deg_to_rad(angle_x_max)
	angle_y_max = deg_to_rad(angle_y_max)
	_update_card_size()
	_setup_texture()


@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if not card_drag_component:
		return
	
	# 更新拖拽位置

	card_drag_component.process_drag()
	
	# 如果在拖拽中，计算速度并应用3D旋转
	if card_drag_component.is_dragging():
		_update_drag_rotation(delta)


func _update_drag_rotation(delta: float) -> void:
	var current_pos: Vector2 = global_position
	_drag_velocity = (current_pos - _last_drag_pos) / delta
	_last_drag_pos = current_pos
	

	visual_component.set_rotation_from_velocity(_drag_velocity, angle_x_max)



func _update_card_size() -> void:
	var viewport_size = get_viewport_rect().size
	var target_width = viewport_size.x * card_scale
	var target_height = target_width * (9.0 / 16.0)
	custom_minimum_size = Vector2(target_width, target_height)
	
	var half_size = custom_minimum_size / 2.0
	pivot_offset = half_size
	
	if visual_component:
		visual_component.update_rect_size(custom_minimum_size)

func _setup_texture() -> void:
	if poster_texture and visual_component:
		visual_component.set_poster_texture(poster_texture)
		print("[GameCard] 海报纹理已设置")

func _on_mouse_entered() -> void:
	print("[GameCard] 鼠标进入 - 发射 card_selected")
	card_selected.emit()
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

func _on_gui_input(event: InputEvent) -> void:
	shadow_component.update_shadow_position()
	card_drag_component.handle_input(event)
	
	## 新增：如果在拖拽中，不处理悬停3D效果
	#if card_drag_component and card_drag_component.is_dragging():
		#return
	#
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

func _on_pressed() -> void:
	print("[GameCard] 卡片被点击 - 发射 card_confirmed")
	card_confirmed.emit()

func deselect() -> void:
	_is_selected = false
	print("[GameCard] deselect() 被调用")

func is_selected() -> bool:
	return _is_selected
