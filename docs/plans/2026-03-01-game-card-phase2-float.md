# Game Card Component - Phase 2: 漂浮、阴影与3D倾斜

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 实现Oscillator物理漂浮系统、动态阴影偏移、鼠标悬停"拾起"效果（漂浮增强+缩放+平滑过渡）。

**Architecture:** 
- 新增 CardAnimationComponent: 统一管理所有动画（漂浮、缩放、旋转）
- 使用简谐振子(Oscillator)实现自然的物理漂浮
- 所有状态变化使用Tween实现平滑过渡，避免突兀
- 以卡片中心为锚点进行所有变换

**Tech Stack:** Godot 4.x, GDScript, Tween动画, 物理模拟

---

## Task 1: 创建 Oscillator 工具类

**Files:**
- Create: `script/utils/oscillator.gd`

**Step 1: 编写物理振荡器类**

```gdscript
class_name Oscillator

var spring: float = 150.0
var damp: float = 10.0
var displacement: float = 0.0
var velocity: float = 0.0
var enabled: bool = true

func _init(spring_constant: float = 150.0, damping: float = 10.0) -> void:
	spring = spring_constant
	damp = damping

func update(delta: float) -> void:
	if not enabled:
		return
	var force = -spring * displacement - damp * velocity
	velocity += force * delta
	displacement += velocity * delta

func reset() -> void:
	displacement = 0.0
	velocity = 0.0

func set_displacement(value: float) -> void:
	displacement = value
```

---

## Task 2: 创建 CardAnimationComponent

**Files:**
- Create: `scenes/main_menu/components/card_animation_component.gd`

**Step 1: 编写动画组件脚本**

```gdscript
extends Node
class_name CardAnimationComponent

# 导出参数
@export var card: Control
@export var visual_component: CardVisualComponent

@export_group("Float Settings")
@export var float_amplitude_idle: Vector2 = Vector2(8, 12)
@export var float_amplitude_hover: Vector2 = Vector2(15, 20)
@export var float_transition_duration: float = 0.5

@export_group("Hover Settings")
@export var hover_scale: float = 1.08
@export var hover_scale_duration: float = 0.5

@export_group("Tilt Settings")
@export var max_tilt_angle: float = 15.0

# 内部变量
var _oscillator_x: Oscillator = Oscillator.new(150.0, 10.0)
var _oscillator_y: Oscillator = Oscillator.new(120.0, 8.0)
var _base_position: Vector2
var _current_float_amplitude: Vector2
var _is_floating_enabled: bool = true

# Tween引用
var _tween_scale: Tween
var _tween_float: Tween
var _tween_tilt: Tween

func _ready() -> void:
	if card:
		_base_position = card.position
	_current_float_amplitude = float_amplitude_idle

func _process(delta: float) -> void:
	if _is_floating_enabled:
		_update_float_animation(delta)

func _update_float_animation(delta: float) -> void:
	_oscillator_x.update(delta)
	_oscillator_y.update(delta)
	
	var offset = Vector2(
		_oscillator_x.displacement * _current_float_amplitude.x,
		_oscillator_y.displacement * _current_float_amplitude.y
	)
	
	if card:
		card.position = _base_position + offset

func enable_floating() -> void:
	_is_floating_enabled = true
	_oscillator_x.enabled = true
	_oscillator_y.enabled = true

func disable_floating() -> void:
	_is_floating_enabled = false
	_oscillator_x.enabled = false
	_oscillator_y.enabled = false

func transition_to_hover_float() -> void:
	if _tween_float and _tween_float.is_running():
		_tween_float.kill()
	
	_tween_float = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween_float.tween_method(
		func(amp): _current_float_amplitude = amp,
		_current_float_amplitude,
		float_amplitude_hover,
		float_transition_duration
	)

func transition_to_idle_float() -> void:
	if _tween_float and _tween_float.is_running():
		_tween_float.kill()
	
	_tween_float = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween_float.tween_method(
		func(amp): _current_float_amplitude = amp,
		_current_float_amplitude,
		float_amplitude_idle,
		float_transition_duration
	)

func scale_to_hover() -> void:
	if not card:
		return
	
	if _tween_scale and _tween_scale.is_running():
		_tween_scale.kill()
	
	_tween_scale = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_tween_scale.tween_property(card, "scale", Vector2(hover_scale, hover_scale), hover_scale_duration)

func scale_to_normal() -> void:
	if not card:
		return
	
	if _tween_scale and _tween_scale.is_running():
		_tween_scale.kill()
	
	_tween_scale = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_tween_scale.tween_property(card, "scale", Vector2.ONE, hover_scale_duration + 0.05)

func scale_to_selected() -> void:
	if not card:
		return
	
	if _tween_scale and _tween_scale.is_running():
		_tween_scale.kill()
	
	_tween_scale = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_tween_scale.tween_property(card, "scale", Vector2(0.95, 0.95), 0.3)

func update_3d_tilt(mouse_pos: Vector2, card_size: Vector2) -> void:
	if not visual_component:
		return
	
	# 计算归一化的鼠标位置 (0.0 - 1.0)
	var lerp_x = clamp(mouse_pos.x / card_size.x, 0.0, 1.0)
	var lerp_y = clamp(mouse_pos.y / card_size.y, 0.0, 1.0)
	
	# 计算目标旋转角度
	var target_rot_y = lerp(-max_tilt_angle, max_tilt_angle, lerp_x)
	var target_rot_x = lerp(max_tilt_angle, -max_tilt_angle, lerp_y)
	
	visual_component.set_rotation_3d(target_rot_x, target_rot_y)

func reset_tilt_with_animation() -> void:
	if not visual_component:
		return
	
	if _tween_tilt and _tween_tilt.is_running():
		_tween_tilt.kill()
	
	_tween_tilt = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	_tween_tilt.tween_method(
		func(x): visual_component.set_rotation_3d(x, visual_component._3d_material.get_shader_parameter("y_rot")),
		visual_component._3d_material.get_shader_parameter("x_rot"),
		0.0,
		0.4
	)
	_tween_tilt.tween_method(
		func(y): visual_component.set_rotation_3d(visual_component._3d_material.get_shader_parameter("x_rot"), y),
		visual_component._3d_material.get_shader_parameter("y_rot"),
		0.0,
		0.4
	)

func reset_tilt_immediate() -> void:
	if visual_component:
		visual_component.reset_rotation()

func get_current_float_offset() -> Vector2:
	return Vector2(
		_oscillator_x.displacement * _current_float_amplitude.x,
		_oscillator_y.displacement * _current_float_amplitude.y
	)
```

---

## Task 3: 创建 CardShadowComponent

**Files:**
- Create: `scenes/main_menu/components/card_shadow_component.gd`

**Step 1: 编写阴影组件脚本**

```gdscript
extends Node
class_name CardShadowComponent

@export var shadow: TextureRect
@export var card: Control

@export var max_shadow_offset: float = 50.0
@export var shadow_offset_y: float = 30.0
@export var shadow_smoothness: float = 0.3

var _tween_shadow: Tween

func update_shadow_position() -> void:
	if not shadow or not card:
		return
	
	var viewport_center_x = card.get_viewport_rect().size.x / 2.0
	var card_global_x = card.global_position.x + card.size.x / 2.0
	var distance_from_center = card_global_x - viewport_center_x
	
	# 计算阴影偏移
	var normalized_distance = clamp(abs(distance_from_center) / viewport_center_x, 0.0, 1.0)
	var target_offset_x = -sign(distance_from_center) * max_shadow_offset * normalized_distance
	
	# 使用Tween平滑过渡
	if _tween_shadow and _tween_shadow.is_running():
		_tween_shadow.kill()
	
	_tween_shadow = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_tween_shadow.tween_property(shadow, "position:x", target_offset_x, shadow_smoothness)
	shadow.position.y = shadow_offset_y

func set_shadow_alpha(alpha: float, duration: float = 0.3) -> void:
	if not shadow:
		return
	
	var tween = create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property(shadow, "self_modulate:a", alpha, duration)
```

---

## Task 4: 更新 GameCard 主脚本

**Files:**
- Modify: `scenes/main_menu/game_card.gd`

**Step 1: 添加新组件引用和参数**

在原有代码基础上添加：

```gdscript
@onready var animation_component: CardAnimationComponent = $CardAnimationComponent
@onready var shadow_component: CardShadowComponent = $CardShadowComponent
@onready var shadow_rect: TextureRect = $Shadow

var _is_hovering: bool = false
```

**Step 2: 修改 `_ready()` 函数**

```gdscript
func _ready() -> void:
	_update_card_size()
	_setup_texture()
	_connect_signals()
	_setup_components()

func _setup_components() -> void:
	if animation_component:
		animation_component.card = self
		animation_component.visual_component = visual_component
	
	if shadow_component:
		shadow_component.shadow = shadow_rect
		shadow_component.card = self
```

**Step 3: 添加 `_process` 函数**

```gdscript
func _process(delta: float) -> void:
	# 更新阴影位置（每帧跟随漂浮动画）
	if shadow_component and animation_component:
		shadow_component.update_shadow_position()
```

**Step 4: 重写悬停处理函数**

```gdscript
func _on_card_hovered() -> void:
	_is_hovering = true
	
	if _is_selected:
		return
	
	# 过渡到悬停漂浮（更大的幅度）
	if animation_component:
		animation_component.transition_to_hover_float()
		animation_component.scale_to_hover()

func _on_card_unhovered() -> void:
	_is_hovering = false
	
	if _is_selected:
		return
	
	# 恢复空闲漂浮
	if animation_component:
		animation_component.transition_to_idle_float()
		animation_component.scale_to_normal()
		animation_component.reset_tilt_with_animation()
```

**Step 5: 添加输入处理**

```gdscript
func _gui_input(event: InputEvent) -> void:
	if _is_hovering and not _is_selected:
		if event is InputEventMouseMotion:
			if animation_component:
				animation_component.update_3d_tilt(get_local_mouse_position(), size)
```

---

## Task 5: 更新场景文件

**Files:**
- Modify: `scenes/main_menu/game_card.tscn`

**Step 1: 添加新组件节点**

在原有场景基础上添加两个新节点：

```ini
[ext_resource type="Script" path="res://scenes/main_menu/components/card_animation_component.gd" id="5_anim"]
[ext_resource type="Script" path="res://scenes/main_menu/components/card_shadow_component.gd" id="6_shadow"]

[node name="CardAnimationComponent" type="Node" parent="."]
script = ExtResource("5_anim")
card = NodePath("..")
visual_component = NodePath("../CardVisualComponent")

[node name="CardShadowComponent" type="Node" parent="."]
script = ExtResource("6_shadow")
shadow = NodePath("../Shadow")
card = NodePath("..")
```

---

## Task 6: 创建Phase 2测试场景

**Files:**
- Create: `scenes/test/game_card/test_phase2.gd`

**Step 1: 编写测试脚本**

```gdscript
extends Control

@onready var game_card = $GameCard

func _ready() -> void:
	print("=== Phase 2 测试 ===")
	print("测试内容：")
	print("1. 卡面空闲时自然上下漂浮（±8-12px）")
	print("2. 鼠标移入：漂浮幅度增大至±15-20px，同时放大到1.08倍")
	print("3. 鼠标移动：卡面产生3D倾斜跟随（±15度）")
	print("4. 鼠标移出：恢复原始大小和漂浮幅度，倾斜归零")
	print("5. 阴影随卡面位置动态偏移")
	print("6. 所有动画都有平滑过渡，无卡顿")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			print("重置测试...")
			get_tree().reload_current_scene()
```

**Step 2: 创建测试场景文件**

复制Phase 1的测试场景，将脚本替换为 `test_phase2.gd`，Label文本改为 "Phase 2: 漂浮与动画测试"

---

## 验收标准

1. ✅ 空闲时卡面自然上下漂浮（±8-12px）
2. ✅ 鼠标悬停时漂浮幅度平滑增大至±15-20px
3. ✅ 鼠标悬停时卡面弹性放大到1.08倍
4. ✅ 3D倾斜跟随鼠标位置，角度范围±15度
5. ✅ 从边缘进入时有平滑过渡动画（Tween）
6. ✅ 鼠标离开时恢复动画流畅自然
7. ✅ 阴影随卡面水平位置偏移（Balatro风格）
8. ✅ 所有变换以中心点为锚点
9. ✅ 组件化结构清晰，动画逻辑封装在CardAnimationComponent中

---

*Plan version: 2.0*
*Phase: 2/5 - 漂浮、阴影与3D倾斜*
