extends Node
class_name Card3DVisualComponent

@export var card_texture: TextureRect
@export var shadow: TextureRect

var _3d_material: ShaderMaterial

## 当前旋转值（度），Tween会直接修改这个值
var _current_rot_x: float = 0.0
var _current_rot_y: float = 0.0

## Tween引用，用于平滑过渡
var _tween_rot: Tween

## 过渡持续时间（秒）
var _transition_duration: float = 0.2

func _ready() -> void:
	_setup_materials()

func _setup_materials() -> void:
	if card_texture:
		_3d_material = card_texture.material
		if _3d_material:
			_3d_material.set_shader_parameter("x_rot", 0.0)
			_3d_material.set_shader_parameter("y_rot", 0.0)

func set_poster_texture(texture: Texture2D) -> void:
	if card_texture:
		card_texture.texture = texture

## 设置3D旋转目标值，使用Tween平滑过渡
## 参数:
##   x_rot: X轴旋转目标值（度）
##   y_rot: Y轴旋转目标值（度）
func set_rotation_3d(x_rot: float, y_rot: float) -> void:
	# 停止之前的Tween
	if _tween_rot and _tween_rot.is_running():
		_tween_rot.kill()
	
	# 创建新的Tween动画
	_tween_rot = create_tween().set_parallel(true)
	_tween_rot.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Tween会平滑地改变_current_rot_x和_current_rot_y
	_tween_rot.tween_property(self, "_current_rot_x", x_rot, _transition_duration)
	_tween_rot.tween_property(self, "_current_rot_y", y_rot, _transition_duration)
	
	# 同时更新Shader参数
	_tween_rot.chain().tween_callback(_update_shader_params)

## 根据拖拽速度设置旋转（用于拖拽时的惯性效果）
## 参数:
##   velocity: 拖拽速度向量
##   max_angle: 最大旋转角度限制
func set_rotation_from_velocity(velocity: Vector2, max_angle: float = 15.0) -> void:
	var target_y: float = clampf(velocity.x * 0.1, -max_angle, max_angle)
	var target_x: float = clampf(-velocity.y * 0.1, -max_angle, max_angle)
	set_rotation_3d(target_x, target_y)

## 重置旋转到0（使用Tween平滑过渡）
func reset_rotation() -> void:
	set_rotation_3d(0.0, 0.0)

## 立即重置旋转（无过渡效果）
func reset_rotation_immediate() -> void:
	if _tween_rot and _tween_rot.is_running():
		_tween_rot.kill()
	_current_rot_x = 0.0
	_current_rot_y = 0.0
	_update_shader_params()

## 更新Shader材质参数
func _update_shader_params() -> void:
	if _3d_material:
		_3d_material.set_shader_parameter("x_rot", _current_rot_x)
		_3d_material.set_shader_parameter("y_rot", _current_rot_y)

## 每帧更新Shader（因为Tween在修改数值）
func _process(_delta: float) -> void:
	_update_shader_params()

## 更新Shader的矩形大小参数
func update_rect_size(size: Vector2) -> void:
	if _3d_material:
		_3d_material.set_shader_parameter("rect_size", size)
