class_name CardFloatComponent
extends Node

# ============================================
# CardFloatComponent - 卡片漂浮与视差组件
# ============================================
# 结合 Oscillator 物理振荡和鼠标视差效果
# 实现自然的卡片呼吸动画和交互反馈

# ============================================
# 导出变量 - 在检查器中调整
# ============================================

## 卡片节点引用，拖入需要漂浮的卡片
@export var card: Button

## 漂浮振幅 (X: 水平幅度, Y: 垂直幅度)
## 数值越大，上下左右晃动范围越大
## 推荐值: X=8~15, Y=6~12
@export var float_amplitude: Vector2 = Vector2(15, 12)

## 视差强度 (X: 水平强度, Y: 垂直强度)
## 鼠标偏离屏幕中心时，卡片跟随偏移的最大像素数
## 数值越大，鼠标移动时卡片偏移越明显
## 推荐值: X=30~50, Y=20~35
@export var parallax_strength: Vector2 = Vector2(42, 30)

## 平滑过渡速度
## 控制视差偏移的跟随速度，值越大跟随越快
## 推荐值: 1.5~3.0
@export var smoothing: float = 1.75

var _oscillator_x: Oscillator
var _oscillator_y: Oscillator
var _float_enabled: bool = false
var _parallax_enabled: bool = true
var _original_position: Vector2
var _parallax_offset: Vector2 = Vector2.ZERO

func _ready():
	_oscillator_x = Oscillator.new(120.0, 8.0)
	_oscillator_y = Oscillator.new(150.0, 10.0)
	
	if card:
		_original_position = card.global_position
		_oscillator_x.set_displacement(float_amplitude.x * 0.5)
		_oscillator_y.set_displacement(float_amplitude.y * 0.5)
	
	enable_float()

func _process(delta):
	var target_pos = _original_position
	if not _float_enabled:
		return
	# 1. 计算漂浮偏移
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
	card.global_position = target_pos

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
	
	## 平滑回到原位
	#if card:
		#var tween = create_tween()
		#tween.tween_property(card, "position", _original_position + _parallax_offset, 0.3)

func set_parallax_enabled(enabled: bool):
	_parallax_enabled = enabled
	if not enabled:
		_parallax_offset = Vector2.ZERO

func set_base_position(pos: Vector2) -> void:
	_original_position = pos
