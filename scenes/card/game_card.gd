extends Button
class_name GameCard

signal card_selected()
signal card_deselected()
signal card_confirmed()
signal card_hover_started()
signal card_hover_ended()

@export var card_scale: float = 0.6
@export var poster_texture: Texture2D

@onready var visual_component: CardVisualComponent = $CardVisualComponent
@onready var card_texture_rect: TextureRect = $CardTexture
@onready var shadow: TextureRect = $Shadow

var _is_selected: bool = false
var _tween_hover: Tween
var _tween_rot: Tween

func _ready() -> void:
	print("[GameCard] _ready() - 初始化完成")
	_update_card_size()
	_setup_texture()
	_connect_signals()

func _connect_signals() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	pressed.connect(_on_pressed)

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
	_tween_hover.tween_property(self, "scale", Vector2(1.05, 1.05), 0.3)

func _on_mouse_exited() -> void:
	print("[GameCard] 鼠标离开 - 发射 card_deselected")
	card_deselected.emit()
	card_hover_ended.emit()
	
	if _tween_hover and _tween_hover.is_running():
		_tween_hover.kill()
	_tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_tween_hover.tween_property(self, "scale", Vector2.ONE, 0.3)
	
	if _tween_rot and _tween_rot.is_running():
		_tween_rot.kill()
	_tween_rot = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	if card_texture_rect and card_texture_rect.material:
		_tween_rot.tween_property(card_texture_rect.material, "shader_parameter/x_rot", 0.0, 0.3)
		_tween_rot.tween_property(card_texture_rect.material, "shader_parameter/y_rot", 0.0, 0.3)

func _on_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		return
	
	var mouse_pos: Vector2 = get_local_mouse_position()
	var lerp_val_x: float = remap(mouse_pos.x, 0.0, size.x, 0.0, 1.0)
	var lerp_val_y: float = remap(mouse_pos.y, 0.0, size.y, 0.0, 1.0)
	
	var rot_x: float = lerp_angle(-5.0, 5.0, lerp_val_x)
	var rot_y: float = lerp_angle(5.0, -5.0, lerp_val_y)
	
	if card_texture_rect and card_texture_rect.material:
		card_texture_rect.material.set_shader_parameter("x_rot", rad_to_deg(rot_y))
		card_texture_rect.material.set_shader_parameter("y_rot", rad_to_deg(rot_x))

func _on_pressed() -> void:
	print("[GameCard] 卡片被点击 - 发射 card_confirmed")
	card_confirmed.emit()

func deselect() -> void:
	_is_selected = false
	print("[GameCard] deselect() 被调用")

func is_selected() -> bool:
	return _is_selected
