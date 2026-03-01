# Game Card Component - Phase 1: Shader与基础结构

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 复制Shader资源，创建组件化的GameCard基础结构（拆分为视觉组件和输入处理组件）。

**Architecture:** 
- 复用参考项目的 `fake_3D.gdshader` 和 `dissolve.gdshader`
- 采用组件化设计：GameCard作为容器，功能分散到子节点组件
- CardVisualComponent: 负责材质、纹理显示
- CardInputHandler: 负责输入检测（Button）

**Tech Stack:** Godot 4.x, GDScript, GLSL Shader

---

## Task 1: 复制 fake_3d.gdshader

**Files:**
- Create: `assets/shaders/fake_3d.gdshader`

**Step 1: 创建Shader文件**

```glsl
shader_type canvas_item;

uniform vec2 rect_size;
uniform float fov : hint_range(1, 179) = 90;
uniform bool cull_back = true;
uniform float y_rot : hint_range(-360.0, 360.0) = 0.0;
uniform float x_rot : hint_range(-360.0, 360.0) = 0.0;
uniform float inset : hint_range(0, 1) = 0.0;

varying flat vec2 o;
varying vec3 p;

void vertex(){
	float sin_b = sin(y_rot / 180.0 * PI);
	float cos_b = cos(y_rot / 180.0 * PI);
	float sin_c = sin(x_rot / 180.0 * PI);
	float cos_c = cos(x_rot / 180.0 * PI);
	
	mat3 inv_rot_mat;
	inv_rot_mat[0][0] = cos_b;
	inv_rot_mat[0][1] = 0.0;
	inv_rot_mat[0][2] = -sin_b;
	inv_rot_mat[1][0] = sin_b * sin_c;
	inv_rot_mat[1][1] = cos_c;
	inv_rot_mat[1][2] = cos_b * sin_c;
	inv_rot_mat[2][0] = sin_b * cos_c;
	inv_rot_mat[2][1] = -sin_c;
	inv_rot_mat[2][2] = cos_b * cos_c;
	
	float t = tan(fov / 360.0 * PI);
	p = inv_rot_mat * vec3((UV - 0.5), 0.5 / t);
	float v = (0.5 / t) + 0.5;
	p.xy *= v * inv_rot_mat[2].z;
	o = v * inv_rot_mat[2].xy;
	VERTEX += (UV - 0.5) * rect_size * t * (1.0 - inset);
}

void fragment(){
	if (cull_back && p.z <= 0.0) discard;
	vec2 uv = (p.xy / p.z).xy - o;
    COLOR = texture(TEXTURE, uv + 0.5);
	COLOR.a *= step(max(abs(uv.x), abs(uv.y)), 0.5);
}
```

---

## Task 2: 复制 dissolve.gdshader

**Files:**
- Create: `assets/shaders/dissolve.gdshader`

**Step 1: 创建Shader文件**

```glsl
shader_type canvas_item;

uniform sampler2D dissolve_texture : source_color;
uniform float dissolve_value : hint_range(0,1);
uniform float burn_size: hint_range(0.0, 1.0, 0.01);
uniform vec4 burn_color: source_color;

void fragment(){
    vec4 main_texture = texture(TEXTURE, UV);
    vec4 noise_texture = texture(dissolve_texture, UV);
	float burn_size_step = burn_size * step(0.001, dissolve_value) * step(dissolve_value, 0.999);
	float threshold = smoothstep(noise_texture.x-burn_size_step, noise_texture.x, dissolve_value);
	float border = smoothstep(noise_texture.x, noise_texture.x + burn_size_step, dissolve_value);
	COLOR.a *= threshold;
	COLOR.rgb = mix(burn_color.rgb, main_texture.rgb, border);
}
```

---

## Task 3: 创建 CardVisualComponent 脚本

**Files:**
- Create: `scenes/main_menu/components/card_visual_component.gd`

**Step 1: 编写视觉组件脚本**

```gdscript
extends Node
class_name CardVisualComponent

@export var card_texture: TextureRect
@export var shadow: TextureRect

var _3d_material: ShaderMaterial

func _ready() -> void:
	_setup_materials()

func _setup_materials() -> void:
	if card_texture:
		_3d_material = card_texture.material
		if _3d_material:
			set_rotation_3d(0.0, 0.0)

func set_poster_texture(texture: Texture2D) -> void:
	if card_texture:
		card_texture.texture = texture

func set_rotation_3d(x_rot: float, y_rot: float) -> void:
	if _3d_material:
		_3d_material.set_shader_parameter("x_rot", x_rot)
		_3d_material.set_shader_parameter("y_rot", y_rot)

func reset_rotation() -> void:
	set_rotation_3d(0.0, 0.0)

func update_rect_size(size: Vector2) -> void:
	if _3d_material:
		_3d_material.set_shader_parameter("rect_size", size)
```

---

## Task 4: 创建 CardInputHandler 脚本

**Files:**
- Create: `scenes/main_menu/components/card_input_handler.gd`

**Step 1: 编写输入处理组件脚本**

```gdscript
extends Button
class_name CardInputHandler

signal card_hovered()
signal card_unhovered()
signal card_clicked()
signal card_released()

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _on_mouse_entered() -> void:
	card_hovered.emit()

func _on_mouse_exited() -> void:
	card_unhovered.emit()

func _on_button_down() -> void:
	card_clicked.emit()

func _on_button_up() -> void:
	card_released.emit()
```

---

## Task 5: 创建 GameCard 主场景

**Files:**
- Create: `scenes/main_menu/game_card.tscn`

**Step 1: 创建场景文件**

```ini
[gd_scene load_steps=7 format=3 uid="uid://gamecard001"]

[ext_resource type="Shader" path="res://assets/shaders/fake_3d.gdshader" id="1_fake3d"]
[ext_resource type="Texture2D" uid="uid://blpcwwemhcq32" path="res://assets/image/poster/game1_poster.png" id="2_poster"]
[ext_resource type="Script" path="res://scenes/main_menu/components/card_visual_component.gd" id="3_visual"]
[ext_resource type="Script" path="res://scenes/main_menu/components/card_input_handler.gd" id="4_input"]

[sub_resource type="ShaderMaterial" id="3d_mat"]
resource_local_to_scene = true
shader = ExtResource("1_fake3d")
shader_parameter/rect_size = Vector2(1152, 648)
shader_parameter/fov = 90.0
shader_parameter/cull_back = true
shader_parameter/y_rot = 0.0
shader_parameter/x_rot = 0.0
shader_parameter/inset = 0.0

[sub_resource type="StyleBoxEmpty" id="empty_style"]

[node name="GameCard" type="Control"]
custom_minimum_size = Vector2(1152, 648)
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -576.0
offset_top = -324.0
offset_right = 576.0
offset_bottom = 324.0
pivot_offset = Vector2(576, 324)

[node name="Shadow" type="TextureRect" parent="."]
modulate = Color(0, 0, 0, 0.3)
self_modulate = Color(1, 1, 1, 0.5)
show_behind_parent = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = 30.0
offset_bottom = 30.0
grow_horizontal = 2
grow_vertical = 2
expand_mode = 1

[node name="CardTexture" type="TextureRect" parent="."]
material = SubResource("3d_mat")
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("2_poster")
expand_mode = 1
stretch_mode = 5

[node name="CardVisualComponent" type="Node" parent="."]
script = ExtResource("3_visual")
card_texture = NodePath("../CardTexture")
shadow = NodePath("../Shadow")

[node name="CardInputHandler" type="Button" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_styles/normal = SubResource("empty_style")
theme_override_styles/hover = SubResource("empty_style")
theme_override_styles/pressed = SubResource("empty_style")
theme_override_styles/disabled = SubResource("empty_style")
theme_override_styles/focus = SubResource("empty_style")
script = ExtResource("4_input")
```

---

## Task 6: 创建 GameCard 主脚本

**Files:**
- Create: `scenes/main_menu/game_card.gd`

**Step 1: 编写主控脚本**

```gdscript
extends Control
class_name GameCard

signal card_selected()
signal card_deselected()
signal card_confirmed()

@export var card_scale: float = 0.6
@export var poster_texture: Texture2D

@onready var visual_component: CardVisualComponent = $CardVisualComponent
@onready var input_handler: CardInputHandler = $CardInputHandler
@onready var card_texture_rect: TextureRect = $CardTexture

var _is_selected: bool = false

func _ready() -> void:
	_update_card_size()
	_setup_texture()
	_connect_signals()

func _update_card_size() -> void:
	var viewport_size = get_viewport_rect().size
	var target_width = viewport_size.x * card_scale
	var target_height = target_width * (9.0 / 16.0)
	custom_minimum_size = Vector2(target_width, target_height)
	
	# 更新中心点
	var half_size = custom_minimum_size / 2.0
	pivot_offset = half_size
	
	# 更新视觉组件的shader参数
	if visual_component:
		visual_component.update_rect_size(custom_minimum_size)

func _setup_texture() -> void:
	if poster_texture and visual_component:
		visual_component.set_poster_texture(poster_texture)

func _connect_signals() -> void:
	if input_handler:
		input_handler.card_hovered.connect(_on_card_hovered)
		input_handler.card_unhovered.connect(_on_card_unhovered)
		input_handler.card_clicked.connect(_on_card_clicked)

func _on_card_hovered() -> void:
	pass  # Phase 2实现

func _on_card_unhovered() -> void:
	pass  # Phase 2实现

func _on_card_clicked() -> void:
	pass  # Phase 3实现

func deselect() -> void:
	"""外部调用：取消选中状态"""
	pass  # Phase 3实现

func is_selected() -> bool:
	return _is_selected
```

---

## Task 7: 创建Phase 1测试场景

**Files:**
- Create: `scenes/test/game_card/test_phase1.tscn`

**Step 1: 创建测试场景**

```ini
[gd_scene load_steps=2 format=3 uid="uid://testphase1"]

[ext_resource type="PackedScene" uid="uid://gamecard001" path="res://scenes/main_menu/game_card.tscn" id="1_gamecard"]

[node name="TestPhase1" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.1, 0.1, 0.15, 1)

[node name="GameCard" parent="." instance=ExtResource("1_gamecard")]
layout_mode = 1

[node name="Label" type="Label" parent="."]
layout_mode = 1
anchors_preset = 5
anchor_left = 0.5
anchor_right = 0.5
offset_left = -200.0
offset_top = 50.0
offset_right = 200.0
offset_bottom = 100.0
grow_horizontal = 2
theme_override_font_sizes/font_size = 24
text = "Phase 1: 基础结构测试"
horizontal_alignment = 1
```

---

## 验收标准

1. ✅ Shader文件正确复制到 `assets/shaders/`
2. ✅ 组件脚本创建：`CardVisualComponent` 和 `CardInputHandler`
3. ✅ 场景能在Godot编辑器中打开无报错
4. ✅ 卡面显示在中央，尺寸正确（约1152x648 @1920x1080）
5. ✅ CardTexture使用fake_3d材质
6. ✅ 组件化结构清晰，职责分离

---

*Plan version: 2.0*
*Phase: 1/5 - Shader与组件化基础结构*
