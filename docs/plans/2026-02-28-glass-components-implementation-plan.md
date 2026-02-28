# ETN Launcher 玻璃组件实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 基于 liquid_glass_ui.gdshader 创建可复用的弹窗 UI 组件（玻璃面板、玻璃按钮），并创建测试场景。

**Architecture:** 
- 组件脚本继承 Godot 内置 Control/Button 节点
- 玻璃效果通过 ShaderMaterial 实现
- 按钮状态通过切换 Shader 参数实现

**Tech Stack:** Godot 4.x, GDScript, CanvasItem Shader

---

## 准备工作

### Task 1: 创建组件文件夹

**Files:**
- Create: `scenes/test/glass_components/`

**Step 1: 创建目录**

```bash
mkdir -p "D:\冰川小未\Godot ALL\项目文件\ETN_Launcher\scenes\test\glass_components"
```

---

## Task 2: 创建 GlassPanel 组件

**Files:**
- Create: `scenes/test/glass_components/glass_panel.gd`

**Step 1: 创建 GlassPanel 脚本**

```gdscript
extends ColorRect
class_name GlassPanel

@export_group("Glass Effect")
@export var corner_radius_px: float = 22.0:
	set(v):
		corner_radius_px = v
		_update_shader_param("corner_radius_px", v)

@export var opacity: float = 1.0:
	set(v):
		opacity = v
		_update_shader_param("opacity", v)

@export var tint: Color = Color(0.80, 0.90, 1.00, 0.35):
	set(v):
		tint = v
		_update_shader_param("tint", v)

@export var border_width_px: float = 1.5:
	set(v):
		border_width_px = v
		_update_shader_param("border_width_px", v)

@export var border_color: Color = Color(1.0, 1.0, 1.0, 0.18):
	set(v):
		border_color = v
		_update_shader_param("border_color", v)

@export var rim_width_px: float = 14.0:
	set(v):
		rim_width_px = v
		_update_shader_param("rim_width_px", v)

@export var rim_intensity: float = 1.0:
	set(v):
		rim_intensity = v
		_update_shader_param("rim_intensity", v)

@export var rim_color: Color = Color(1.0, 1.0, 1.0, 0.45):
	set(v):
		rim_color = v
		_update_shader_param("rim_color", v)

var _shader_loaded := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color(1, 1, 1, 1)
	_update_shader_param("rect_size_px", size)
	resized.connect(_on_resized)

func _on_resized() -> void:
	_update_shader_param("rect_size_px", size)

func _update_shader_param(param_name: String, value) -> void:
	if material == null:
		return
	var mat = material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter(param_name, value)

func _get_shader_material() -> ShaderMaterial:
	if material == null:
		var mat = ShaderMaterial.new()
		mat.shader = load("res://assets/shaders/liquid_glass_ui.gdshader")
		material = mat
		_shader_loaded = true
		_apply_all_params()
	return material as ShaderMaterial

func _apply_all_params() -> void:
	_update_shader_param("corner_radius_px", corner_radius_px)
	_update_shader_param("opacity", opacity)
	_update_shader_param("tint", tint)
	_update_shader_param("border_width_px", border_width_px)
	_update_shader_param("border_color", border_color)
	_update_shader_param("rim_width_px", rim_width_px)
	_update_shader_param("rim_intensity", rim_intensity)
	_update_shader_param("rim_color", rim_color)
```

---

## Task 3: 创建 GlassButton 组件

**Files:**
- Create: `scenes/test/glass_components/glass_button.gd`

**Step 1: 创建 GlassButton 脚本**

```gdscript
extends Button
class_name GlassButton

enum ButtonType { PRIMARY, SECONDARY }
enum SizeVariant { MEDIUM, LARGE }

@export_group("Button Style")
@export var button_type: ButtonType = ButtonType.SECONDARY:
	set(v):
		button_type = v
		_apply_type_style()

@export var size_variant: SizeVariant = SizeVariant.MEDIUM:
	set(v):
		size_variant = v
		_apply_size()

@export_group("Glass Effect")
@export var corner_radius_px: float = 18.0:
	set(v):
		corner_radius_px = v
		_update_glass_param("corner_radius_px", v)

@export var border_width_normal: float = 1.0
@export var border_width_hover: float = 2.0
@export var border_width_pressed: float = 3.0
@export var border_width_disabled: float = 0.5

@export var normal_tint: Color = Color(0.95, 0.95, 0.98, 0.35)
@export var hover_tint: Color = Color(0.98, 0.98, 1.0, 0.38)
@export var pressed_tint: Color = Color(0.85, 0.88, 0.92, 0.40)
@export var disabled_tint: Color = Color(0.60, 0.60, 0.65, 0.25)

var _glass_panel: GlassPanel

func _ready() -> void:
	flat = true
	_pressed_tint = pressed_tint
	_apply_type_style()
	_apply_size()
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)
	released.connect(_on_released)

func _apply_type_style() -> void:
	match button_type:
		ButtonType.PRIMARY:
			normal_tint = Color(0.85, 0.92, 1.0, 0.35)
			hover_tint = Color(0.88, 0.94, 1.0, 0.38)
		ButtonType.SECONDARY:
			normal_tint = Color(0.95, 0.95, 0.98, 0.35)
			hover_tint = Color(0.98, 0.98, 1.0, 0.38)
	
	_update_glass_state()

func _apply_size() -> void:
	match size_variant:
		SizeVariant.MEDIUM:
			custom_minimum_size = Vector2(120, 40)
		SizeVariant.LARGE:
			custom_minimum_size = Vector2(160, 50)

func _update_glass_state() -> void:
	if disabled:
		_update_glass_params(normal_tint, 0.95, border_width_disabled)
	elif button_pressed:
		_update_glass_params(pressed_tint, 1.0, border_width_pressed)
	else:
		_update_glass_params(normal_tint, 1.0, border_width_normal)

func _update_glass_params(t: Color, opa: float, border_w: float) -> void:
	_update_glass_param("tint", t)
	_update_glass_param("opacity", opa)
	_update_glass_param("border_width_px", border_w)

func _update_glass_param(param_name: String, value) -> void:
	pass

func _on_mouse_entered() -> void:
	if disabled:
		return
	_update_glass_params(hover_tint, 1.0, border_width_hover)

func _on_mouse_exited() -> void:
	if disabled:
		return
	_update_glass_params(normal_tint, 1.0, border_width_normal)

func _on_pressed() -> void:
	_update_glass_params(pressed_tint, 1.0, border_width_pressed)

func _on_released() -> void:
	_update_glass_state()
```

---

## Task 4: 创建测试场景

**Files:**
- Create: `scenes/test/glass_components/glass_components_demo.tscn`

**Step 1: 创建场景节点结构**

在 Godot 编辑器中创建：
- Root: Control (name: "GlassComponentsDemo")
- Background: TextureRect
- CenterContainer: CenterContainer
-   MediumPopup: GlassPanel (size: 600x400)
-   LargePopup: GlassPanel (size: 800x600)

---

## Task 5: 运行测试

**Step 1: 在编辑器中运行测试场景**

运行 `glass_components_demo.tscn` 验证：
- 面板显示正常
- 按钮状态切换正常
- 尺寸符合预期

---

## 验收清单

- [ ] GlassPanel 组件可正常显示玻璃效果
- [ ] GlassButton 支持主/次类型切换
- [ ] GlassButton 四种状态（Normal/Hover/Pressed/Disabled）正常切换
- [ ] 尺寸变体（Medium/Large）正常工作
- [ ] 导出变量可调整
- [ ] 测试场景可独立运行
