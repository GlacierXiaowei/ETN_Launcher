# Game Card Component 游戏卡面组件 Implementation Plan (v2 Balatro 风格)

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 创建具有 Balatro 风格漂浮 +3D 倾斜效果的游戏卡面组件，支持单击选中状态、7 种状态机切换和液态玻璃风格 UI。

**Architecture:** 
- 主组件 `GameCard` (Button) 统一处理输入、漂浮动画、3D 倾斜
- 7 个状态 Node 子节点（状态机模式），每个状态独立脚本
- Shader 复用策略：`fake_3d.gdshader` 用于 3D 倾斜，`dissolve.gdshader` 用于可选溶解效果
- 代码与场景同目录放置（`scenes/main_menu/`），便于管理
- 使用 StyleBoxFlat 实现选中白边，Balatro 式动态阴影

**Tech Stack:** Godot 4.x, GDScript, Tween 动画，状态机模式，Shader (fake_3D + dissolve)

---

## 核心设计决策

### 视觉规格

| 属性 | 值 | 说明 |
|------|-----|------|
| 卡面尺寸 | 1920 * 0.6 = 1152px 宽 | 1080P 海报，60% 屏幕宽度（导出变量可调） |
| 长宽比 | 16:9 | 海报原始比例 |
| 圆角 | 24px | 与全局弹窗统一 |
| 漂浮幅度 | ±10-15px | 小幅度柔和漂浮 |
| 3D 倾斜角 | ±15 度 | 鼠标悬浮时触发 |
| 选中缩放 | 0.95 | 单击选中后缩小至 95% |
| 白边透明度 | 75% | StyleBoxFlat 实现 |
| 阴影 | Balatro 式动态偏移 | 随卡面位置左右移动 |

### 状态流程图

```
[空闲漂浮] → 鼠标悬浮 → [3D 倾斜交互] → 单击 → [选中状态]
                                           ↓
                                    漂浮停止 + 缩放 0.95 + 白边显示
                                           ↓
                                    触发 card_selected 信号
                                           ↓
                                    调用 PopupManager.show_confirm()
```

### 文件结构

```
res://
├── scenes/
│   ├── main_menu/
│   │   ├── game_card.tscn              # 主卡面场景
│   │   ├── game_card.gd                # 主卡面脚本
│   │   ├── states/                     # 7 个状态节点（场景 + 脚本）
│   │   │   ├── not_installed_state.tscn
│   │   │   ├── not_installed_state.gd
│   │   │   ├── checking_update_state.tscn
│   │   │   ├── checking_update_state.gd
│   │   │   ├── update_available_state.tscn
│   │   │   ├── update_available_state.gd
│   │   │   ├── update_required_state.tscn
│   │   │   ├── update_required_state.gd
│   │   │   ├── update_failed_state.tscn
│   │   │   ├── update_failed_state.gd
│   │   │   ├── ready_to_launch_state.tscn
│   │   │   ├── ready_to_launch_state.gd
│   │   │   ├── running_state.tscn
│   │   │   └── running_state.gd
│   │   └── game_card_state_machine.gd  # 状态机初始化脚本
│   └── test/
│       └── game_card/
│           ├── test_game_card.tscn
│           ├── test_game_card.gd
│           └── test_two_cards.tscn
├── assets/
│   ├── shaders/
│   │   ├── fake_3d.gdshader            # 3D 倾斜 (从参考项目复制)
│   │   └── dissolve.gdshader           # 溶解效果 (从参考项目复制)
│   └── image/
│       └── poster/
│           ├── game1_poster .png       # 已有
│           └── game2_poster .png       # 已有
└── script/managers/
    └── game_state.gd                   # 单例 (已有，需完善)
```

---

## Task 分解

### Task 0: 确认 GameState 单例配置

**Files:**
- Read: `script/managers/game_state.gd`
- Read: `project.godot`

**Step 1: 检查 autoload 配置**

在 Godot 编辑器打开项目设置 → 自动加载，确认 `GameState` 已添加

**Step 2: 如未配置，手动添加**

路径：`res://script/managers/game_state.gd`，名称：`GameState`

---

### Task 1: 复制 Shader 资源

**Files:**
- Create: `assets/shaders/fake_3d.gdshader`
- Create: `assets/shaders/dissolve.gdshader`

**Step 1: 创建 fake_3d.gdshader**

复制 `godot_ui_components-main/scenes/shared/shaders/fake_3D.gdshader` 内容到 `assets/shaders/fake_3d.gdshader`

**Step 2: 创建 dissolve.gdshader**

复制 `godot_ui_components-main/scenes/shared/shaders/dissolve.gdshader` 内容到 `assets/shaders/dissolve.gdshader`

---

### Task 2: 创建 GameCard 主场景

**Files:**
- Create: `scenes/main_menu/game_card.tscn`

**Step 1: 创建场景文件**

```gdscript
[gd_scene load_steps=7 format=3 uid="uid://gamecard001"]

[ext_resource type="Shader" path="res://assets/shaders/fake_3d.gdshader" id="1_fake3d"]
[ext_resource type="Shader" path="res://assets/shaders/dissolve.gdshader" id="2_dissolve"]
[ext_resource type="Script" path="res://scenes/main_menu/game_card.gd" id="3_script"]

[sub_resource type="ShaderMaterial" id="3d_mat"]
shader = ExtResource("1_fake3d")
shader_parameter/rect_size = Vector2(1152, 648)
shader_parameter/fov = 90.0
shader_parameter/cull_back = true

[sub_resource type="ShaderMaterial" id="dissolve_mat"]
resource_local_to_scene = true
shader = ExtResource("2_dissolve")
shader_parameter/dissolve_value = 1.0
shader_parameter/burn_size = 0.1
shader_parameter/burn_color = Color(1, 0.615686, 0, 1)

[sub_resource type="StyleBoxFlat" id="selected_style"]
bg_color = Color(1, 1, 1, 0)
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = Color(1, 1, 1, 0.75)
corner_radius_top_left = 24
corner_radius_top_right = 24
corner_radius_bottom_right = 24
corner_radius_bottom_left = 24

[node name="GameCard" type="Button"]
material = SubResource("dissolve_mat")
custom_minimum_size = Vector2(1152, 648)
offset_left = -576.0
offset_top = -324.0
offset_right = 576.0
offset_bottom = 324.0
pivot_offset = Vector2(576, 324)
theme_override_styles/normal = SubResource("selected_style")
theme_override_styles/hover = SubResource("selected_style")
theme_override_styles/pressed = SubResource("selected_style")
script = ExtResource("3_script")
card_scale = 0.6
float_amplitude = Vector2(15, 15)
max_angle_x = 15.0
max_angle_y = 15.0

[node name="Shadow" type="TextureRect" parent="."]
modulate = Color(0, 0, 0, 0.4)
self_modulate = Color(1, 1, 1, 0.2)
show_behind_parent = true
offset_left = -500.0
offset_top = 50.0
offset_right = 500.0
offset_bottom = 200.0

[node name="CardTexture" type="TextureRect" parent="."]
material = SubResource("3d_mat")
offset_left = -576.0
offset_top = -324.0
offset_right = 576.0
offset_bottom = 324.0
expand_mode = 1

[node name="StateMachine" type="Node" parent="."]
```

---

### Task 3: 创建 GameCard 主脚本

**Files:**
- Create: `scenes/main_menu/game_card.gd`

**Step 1: 编写主脚本**

```gdscript
extends Button
class_name GameCard

signal card_selected(selected: bool)

@export var card_scale: float = 0.6:
	set(v):
		card_scale = v
		_update_card_size()

@export var float_amplitude: Vector2 = Vector2(15, 15)
@export var max_angle_x: float = 15.0
@export var max_angle_y: float = 15.0

@onready var card_texture: TextureRect = $CardTexture
@onready var shadow: TextureRect = $Shadow
@onready var state_machine: Node = $StateMachine

var _is_hovering := false
var _is_selected := false
var _oscillator_x: Oscillator = Oscillator.new(150.0, 10.0)
var _oscillator_y: Oscillator = Oscillator.new(150.0, 10.0)
var _base_position: Vector2
var _tween_hover: Tween
var _tween_select: Tween

func _ready() -> void:
	_base_position = position
	_update_card_size()
	_setup_materials()
	_connect_signals()
	_initialize_state_machine()

func _update_card_size() -> void:
	var viewport_size = get_viewport_rect().size
	var target_width = viewport_size.x * card_scale
	var target_height = target_width * (9.0 / 16.0)
	custom_minimum_size = Vector2(target_width, target_height)
	if card_texture:
		card_texture.material.set_shader_parameter("rect_size", Vector2(target_width, target_height))

func _setup_materials() -> void:
	if card_texture and card_texture.material:
		card_texture.material.set_shader_parameter("x_rot", 0.0)
		card_texture.material.set_shader_parameter("y_rot", 0.0)

func _connect_signals() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	pressed.connect(_on_pressed)

func _initialize_state_machine() -> void:
	if state_machine and state_machine.has_method("transition_to"):
		state_machine.transition_to("notinstalledstate")

func _process(delta: float) -> void:
	if not _is_selected:
		_update_float_animation(delta)
	if _is_hovering and not _is_selected:
		_update_3d_tilt()

func _update_float_animation(delta: float) -> void:
	_oscillator_x.update(delta)
	_oscillator_y.update(delta)
	position = _base_position + Vector2(_oscillator_x.displacement, _oscillator_y.displacement) * float_amplitude
	_update_shadow_position()

func _update_shadow_position() -> void:
	if shadow:
		var center_x = get_viewport_rect().size.x / 2.0
		var distance = global_position.x - center_x
		shadow.position.x = lerp(0.0, -sign(distance) * 50.0, abs(distance / center_x))

func _update_3d_tilt() -> void:
	var mouse_pos = get_local_mouse_position()
	var lerp_x = remap(mouse_pos.x, 0.0, size.x, 0.0, 1.0)
	var lerp_y = remap(mouse_pos.y, 0.0, size.y, 0.0, 1.0)
	var rot_y = lerp_angle(-deg_to_rad(max_angle_x), deg_to_rad(max_angle_x), lerp_x)
	var rot_x = lerp_angle(deg_to_rad(max_angle_y), -deg_to_rad(max_angle_y), lerp_y)
	if card_texture and card_texture.material:
		card_texture.material.set_shader_parameter("y_rot", rad_to_deg(rot_y))
		card_texture.material.set_shader_parameter("x_rot", rad_to_deg(rot_x))

func _on_mouse_entered() -> void:
	_is_hovering = true
	if _tween_hover:
		_tween_hover.kill()
	_tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_tween_hover.tween_property(self, "scale", Vector2(1.05, 1.05), 0.4)

func _on_mouse_exited() -> void:
	_is_hovering = false
	_reset_rotation()
	if _tween_hover:
		_tween_hover.kill()
	_tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_tween_hover.tween_property(self, "scale", Vector2.ONE if not _is_selected else Vector2(0.95, 0.95), 0.5)

func _reset_rotation() -> void:
	if card_texture and card_texture.material:
		if _tween_hover:
			_tween_hover.parallel().tween_property(card_texture.material, "shader_parameter/x_rot", 0.0, 0.4)
			_tween_hover.parallel().tween_property(card_texture.material, "shader_parameter/y_rot", 0.0, 0.4)
		else:
			card_texture.material.set_shader_parameter("x_rot", 0.0)
			card_texture.material.set_shader_parameter("y_rot", 0.0)

func _on_gui_input(event: InputEvent) -> void:
	pass

func _on_pressed() -> void:
	_is_selected = not _is_selected
	_apply_selected_state()
	card_selected.emit(_is_selected)

func _apply_selected_state() -> void:
	if _tween_select:
		_tween_select.kill()
	_tween_select = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	if _is_selected:
		_tween_select.tween_property(self, "scale", Vector2(0.95, 0.95), 0.3)
		_oscillator_x.enabled = false
		_oscillator_y.enabled = false
	else:
		_tween_select.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4)
		_oscillator_x.enabled = true
		_oscillator_y.enabled = true

func get_current_state() -> String:
	if state_machine and state_machine.has_method("get_current_state_name"):
		return state_machine.get_current_state_name()
	return ""

func set_state(state_name: String) -> void:
	if state_machine and state_machine.has_method("transition_to"):
		state_machine.transition_to(state_name.to_lower())


class Oscillator:
	var spring: float = 150.0
	var damp: float = 10.0
	var displacement: float = 0.0
	var velocity: float = 0.0
	var enabled: bool = true
	
	func _init(s: float, d: float) -> void:
		spring = s
		damp = d
	
	func update(delta: float) -> void:
		if not enabled:
			return
		var force = -spring * displacement - damp * velocity
		velocity += force * delta
		displacement += velocity * delta
```

---

### Task 4: 创建状态机初始化脚本

**Files:**
- Create: `scenes/main_menu/game_card_state_machine.gd`

**Step 1: 编写脚本**

```gdscript
extends Node
class_name GameCardStateMachine

var node_states: Dictionary = {}
var current_state: Node = null

func _ready() -> void:
	for child in get_children():
		if child.has_signal("transition"):
			node_states[child.name.to_lower()] = child
			child.connect("transition", _on_transition)
	
	if node_states.size() > 0:
		var first_state = node_states.values()[0]
		_set_state(first_state)

func _on_transition(target_state_name: String) -> void:
	var new_state = node_states.get(target_state_name.to_lower())
	if new_state and new_state != current_state:
		if current_state and current_state.has_method("_on_exit"):
			current_state._on_exit()
		_set_state(new_state)

func _set_state(state: Node) -> void:
	current_state = state
	if current_state and current_state.has_method("_on_enter"):
		current_state._on_enter()

func get_current_state_name() -> String:
	if current_state:
		return current_state.name.to_lower()
	return ""

func transition_to(state_name: String) -> void:
	_on_transition(state_name)
```

---

### Task 5-11: 创建 7 个状态节点

每个状态节点包含 `.tscn` 和 `.gd` 两个文件，结构与 v1 计划类似，但需要：
- 场景放在 `scenes/main_menu/states/`
- 脚本放在同名 `.gd` 文件
- 每个状态实现 `_on_enter()`, `_on_exit()`, `get_popup_config()`

---

### Task 12: 创建测试场景

**Files:**
- Create: `scenes/test/game_card/test_game_card.tscn`
- Create: `scenes/test/game_card/test_game_card.gd`

**Step 1: 测试脚本**

```gdscript
extends Control

@onready var game_card: GameCard = $GameCard

func _ready() -> void:
	game_card.card_selected.connect(_on_card_selected)

func _on_card_selected(selected: bool) -> void:
	if selected:
		var state = game_card.get_current_state()
		match state:
			"readytolaunchstate":
				PopupManager.show_confirm(
					"启动游戏",
					"确定要启动这款游戏吗？",
					_launch_game,
					func(): pass
				)
			"notinstalledstate":
				PopupManager.show_confirm(
					"游戏未安装",
					"是否现在开始安装？",
					_install_game,
					func(): pass
				)

func _launch_game() -> void:
	print("启动游戏")

func _install_game() -> void:
	print("安装游戏")
```

---

## 验收标准

1. ✅ 卡面尺寸为屏幕宽度的 60%（约 1152px @1920x1080）
2. ✅ 空闲时小幅度漂浮（±10-15px）
3. ✅ 鼠标悬浮时 3D 倾斜±15 度
4. ✅ 单击选中后漂浮停止、缩放至 0.95、显示白色边框
5. ✅ `card_selected` 信号正确触发
6. ✅ 阴影随卡面位置偏移
7. ✅ 7 个状态可正常切换
8. ✅ 弹出对话框调用 PopupManager

---

*Plan version: v2.0 Balatro Style*
*Created: 2026-03-01*
*Updated with Balatro-style floating + 3D tilt effects*
