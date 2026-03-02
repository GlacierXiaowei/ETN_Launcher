class_name CardFloatComponent
extends Node

# ============================================
# CardFloatComponent - 卡片漂浮与视差组件
# ============================================
# 结合 Oscillator 物理振荡和鼠标视差效果
# 实现自然的卡片呼吸动画和交互反馈

@export var card: Button
@export var float_amplitude: Vector2 = Vector2(12, 10)
@export var parallax_strength: Vector2 = Vector2(12, 10)
@export var smoothing: float = 2.0

var _oscillator_x: Oscillator
var _oscillator_y: Oscillator
var _float_enabled: bool = false
var _parallax_enabled: bool = true
var _original_position: Vector2
var _parallax_offset: Vector2 = Vector2.ZERO

func _ready():
	_oscillator_x = Oscillator.new(120.0, 8.0)  # X轴：稍慢的振动
	_oscillator_y = Oscillator.new(150.0, 10.0) # Y轴：稍快的振动
	
	if card:
		_original_position = card.position
		# 给振荡器初始位移以启动动画
		_oscillator_x.set_displacement(float_amplitude.x * 0.5)
		_oscillator_y.set_displacement(float_amplitude.y * 0.5)

func _process(delta):
	var target_pos = _original_position
	
	# 1. 计算漂浮偏移
	if _float_enabled:
		_oscillator_x.update(delta)
		_oscillator_y.update(delta)
		
		var float_offset = Vector2(
			_oscillator_x.displacement,
			_oscillator_y.displacement
		)
		target_pos += float_offset
	
	# 2. 计算视差偏移
	if _parallax_enabled:
		_update_parallax(delta)
		target_pos += _parallax_offset
	
	# 应用位置
	card.position = target_pos

func _update_parallax(delta):
	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size / 2.0
	var mouse_pos = get_viewport().get_mouse_position()
	var dist = mouse_pos - center
	var normalized = Vector2(
		clamp(dist.x / center.x, -1.0, 1.0),
		clamp(dist.y / center.y, -1.0, 1.0)
	)
	
	var target_parallax = Vector2(
		-normalized.x * parallax_strength.x,
		-normalized.y * parallax_strength.y
	)
	
	_parallax_offset.x = lerp(_parallax_offset.x, target_parallax.x, smoothing * delta)
	_parallax_offset.y = lerp(_parallax_offset.y, target_parallax.y, smoothing * delta)

func enable_float():
	_float_enabled = true
	if _oscillator_x and _oscillator_y:
		_oscillator_x.enabled = true
		_oscillator_y.enabled = true

func disable_float():
	_float_enabled = false
	if _oscillator_x and _oscillator_y:
		_oscillator_x.enabled = false
		_oscillator_y.enabled = false
	
	# 平滑回到原位
	if card:
		var tween = create_tween()
		tween.tween_property(card, "position", _original_position + _parallax_offset, 0.3)

func set_parallax_enabled(enabled: bool):
	_parallax_enabled = enabled
	if not enabled:
		_parallax_offset = Vector2.ZERO
