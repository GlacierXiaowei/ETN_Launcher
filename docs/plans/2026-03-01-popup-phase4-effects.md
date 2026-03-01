# Phase4:弹窗Shader动画与特效实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 实现完整的弹窗视觉效果，包括Shader模糊关闭动画、背景压暗、圆角同步、动画防点击。

**Architecture:** 
- 在GlobalPopup中添加BlurOverlay层实现模糊关闭效果
- 添加DimBackground实现背景压暗
- 使用liquid_glass_ui shader确保圆角一致性
- 通过mouse_filter防止动画过程中误触

**Tech Stack:** Godot4.x, GDScript, Shader (liquid_glass_ui.gdshader, transition_blur.gdshader)

---

## 当前状态（Phase3完成）

**GlobalPopup (res://component/GlassComponent/global_popup.gd)**
- 已实现：setup(), open(), close(), update(), update_with_fade()
- 已实现：set_title(), set_content(), set_buttons()
- 信号：button_pressed, closed, popup_opened

**PopupManager (res://script/managers/popup_manager.gd)**
- 已实现：show_popup(), close_popup(), is_popup_open()
- 已实现：update_popup(), close_and_show_new(), has_open_popup()
- 已实现：show_confirm(), show_alert()

**测试场景**
- res://scenes/test/test_popup_phase3.tscn

---

## 需要实现的内容

### Task 1: 添加背景压暗功能（DimBackground）

**Files:**
- Modify: `component/GlassComponent/global_popup.gd:1-206`
- Test: `scenes/test/test_popup_phase4.tscn`

**Step 1: 添加DimBackground节点创建方法**

在global_popup.gd中添加：

```gdscript
var _dim_bg: ColorRect = null
var _dim_alpha: float = 0.5

func _create_dim_background() -> void:
	if _dim_bg != null:
		return
	
	_dim_bg = ColorRect.new()
	_dim_bg.name = "DimBackground"
	_dim_bg.color = Color(0, 0, 0, _dim_alpha)
	_dim_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim_bg.visible = false
	add_child(_dim_bg)
	move_child(_dim_bg, 0)
```

**Step 2: 修改setup()方法支持dim_background配置**

在setup()方法开头添加：

```gdscript
func setup(config: Dictionary) -> void:
	_config = config
	
	# 创建背景压暗（如果启用）
	if config.get("dim_background", false):
		_create_dim_background()
		_dim_bg.visible = true
		_dim_bg.modulate.a = 0.0
		_dim_alpha = config.get("dim_color", Color(0, 0, 0, 0.5)).a
```

**Step 3: 修改open()方法添加背景淡入**

在open()方法的tween中添加：

```gdscript
func open() -> void:
	visible = true
	_is_opening = true
	_is_closing = false
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	glass_panel.scale = Vector2(0.8, 0.8)
	glass_panel.modulate.a = 0.0
	
	tween.tween_property(glass_panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(glass_panel, "modulate:a", 1.0, 0.25)
	
	# 添加背景压暗淡入
	if _dim_bg != null and _dim_bg.visible:
		tween.tween_property(_dim_bg, "modulate:a", _dim_alpha, 0.2)
	
	await tween.finished
	_is_opening = false
	popup_opened.emit()
```

**Step 4: 修改close()方法添加背景淡出**

```gdscript
func close() -> void:
	if _is_closing:
		return
	_is_closing = true
	if _is_opening:
		await get_tree().create_timer(0.1).timeout
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	# 背景压暗淡出
	if _dim_bg != null:
		tween.tween_property(_dim_bg, "modulate:a", 0.0, 0.15)
	
	tween.tween_property(glass_panel, "modulate:a", 0.0, 0.2)
	
	await tween.finished
	closed.emit()
	queue_free()
```

**Step 5: 测试验证**

运行test_popup_phase4.tscn，验证带dim_background的弹窗打开和关闭动画。

---

### Task 2: 添加BlurOverlay模糊关闭效果

**Files:**
- Modify: `component/GlassComponent/global_popup.gd`

**Step 1: 添加BlurOverlay节点和相关变量**

在变量声明区域添加：

```gdscript
var _blur_overlay: ColorRect = null
var _use_blur_close := false
```

添加创建方法：

```gdscript
func _create_blur_overlay() -> void:
	if _blur_overlay != null:
		return
	
	_blur_overlay = ColorRect.new()
	_blur_overlay.name = "BlurOverlay"
	_blur_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_blur_overlay.visible = false
	
	var blur_mat := ShaderMaterial.new()
	blur_mat.shader = load("res://assets/shaders/liquid_glass_ui.gdshader")
	blur_mat.set_shader_parameter("blur_lod_center", 4.0)
	blur_mat.set_shader_parameter("blur_lod_edge", 5.0)
	blur_mat.set_shader_parameter("tint", Color(1, 1, 1, 0.1))
	blur_mat.set_shader_parameter("opacity", 0.3)
	blur_overlay.material = blur_mat
	
	$PopupContainer.add_child(_blur_overlay)
	_blur_overlay.move_after($PopupContainer/GlassPanel)
```

**Step 2: 修改setup()方法支持blur_close配置**

在setup()末尾添加：

```gdscript
	# 创建模糊覆盖层（如果启用）
	if config.get("blur_close", false):
		_use_blur_close = true
		_create_blur_overlay()
		_update_blur_overlay_size()
```

添加尺寸同步方法：

```gdscript
func _update_blur_overlay_size() -> void:
	if _blur_overlay == null:
		return
	_blur_overlay.size = glass_panel.size
	_blur_overlay.position = glass_panel.position
```

在glass_panel位置变化时需要调用_update_blur_overlay_size()。

**Step 3: 添加close_with_blur()方法**

```gdscript
func close_with_blur(metadata: String = "") -> void:
	if _is_closing:
		return
	_is_closing = true
	if _is_opening:
		await get_tree().create_timer(0.1).timeout
	
	if _blur_overlay != null:
		_blur_overlay.visible = true
		_blur_overlay.modulate.a = 0.0
		_blur_overlay.size = glass_panel.size
		_blur_overlay.position = glass_panel.position
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	# 第一阶段：模糊效果
	if _blur_overlay != null:
		var blur_mat = _blur_overlay.material as ShaderMaterial
		if blur_mat != null:
			blur_mat.set_shader_parameter("blur_lod_center", 4.0)
			blur_mat.set_shader_parameter("blur_lod_edge", 5.0)
	
	# 第二阶段：淡出
	tween.tween_property(glass_panel, "modulate:a", 0.0, 0.15)
	if _blur_overlay != null:
		tween.tween_property(_blur_overlay, "modulate:a", 0.0, 0.15)
	
	await tween.finished
	
	button_pressed.emit(metadata)
	closed.emit()
	queue_free()
```

**Step 4: 修改_on_button_pressed()支持blur_close**

```gdscript
func _on_button_pressed(metadata: String) -> void:
	var stay_open := false
	if _last_pressed_btn != null:
		stay_open = _last_pressed_btn.get_meta("stay_open", false) as bool
	
	button_pressed.emit(metadata)
	_last_pressed_btn = null
	
	if stay_open:
		return
	
	if _use_blur_close:
		close_with_blur(metadata)
	else:
		close()
```

**Step 5: 测试验证**

创建测试用例验证：
- 标准关闭动画（无模糊）
- Shader模糊关闭动画

---

### Task 3: 动画防点击处理

**Files:**
- Modify: `component/GlassComponent/global_popup.gd`

**Step 1: 添加动画状态标志**

确保已有变量声明：

```gdscript
var _is_animating := false
```

**Step 2: 修改open()方法设置动画状态**

在open()开头添加：

```gdscript
func open() -> void:
	visible = true
	_is_opening = true
	_is_closing = false
	_is_animating = true
	button_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# ... 现有代码 ...
```

在open()末尾添加：

```gdscript
	await tween.finished
	_is_opening = false
	_is_animating = false
	button_container.mouse_filter = Control.MOUSE_FILTER_PASS
	popup_opened.emit()
```

**Step 3: 修改close()和close_with_blur()方法**

在close()开头添加：

```gdscript
func close() -> void:
	if _is_closing:
		return
	_is_closing = true
	_is_animating = true
	button_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# ... 现有代码 ...
```

在close()末尾添加：

```gdscript
	await tween.finished
	closed.emit()
	queue_free()
```

同样处理close_with_blur()方法。

---

### Task 4: 创建Phase4测试场景

**Files:**
- Create: `scenes/test/test_popup_phase4.tscn`
- Create: `scenes/test/test_popup_phase4.gd`

**Step 1: 创建测试场景**

创建新的测试场景，包含：
- 4个测试按钮：
  1. "标准关闭动画" - 测试无模糊的标准关闭
  2. "模糊关闭动画" - 测试blur_close效果
  3. "带背景压暗" - 测试dim_background效果
  4. "快速连续点击" - 测试防误触

**Step 2: 编写测试脚本**

```gdscript
extends Control

@onready var popup_manager = preload("res://script/managers/popup_manager.gd")

func _ready():
	# 连接信号
	PopupManager.popup_button_pressed.connect(_on_popup_button_pressed)
	PopupManager.popup_closed.connect(_on_popup_closed)

func _on_test_standard_close_pressed():
	PopupManager.show_popup({
		"title": "标准关闭动画",
		"content": "这是标准关闭动画测试",
		"buttons": [
			{"text": "关闭", "type": "primary", "metadata": "close"}
		]
	})

func _on_test_blur_close_pressed():
	PopupManager.show_popup({
		"title": "模糊关闭动画",
		"content": "这是模糊关闭动画测试",
		"blur_close": true,
		"buttons": [
			{"text": "关闭", "type": "primary", "metadata": "close"}
		]
	})

func _on_test_dim_background_pressed():
	PopupManager.show_popup({
		"title": "背景压暗",
		"content": "这是背景压暗效果测试",
		"dim_background": true,
		"buttons": [
			{"text": "关闭", "type": "primary", "metadata": "close"}
		]
	})

func _on_test_rapid_click_pressed():
	PopupManager.show_popup({
		"title": "快速点击测试",
		"content": "快速连续点击按钮，验证动画中按钮不可点击",
		"buttons": [
			{"text": "按钮1", "type": "primary", "metadata": "btn1"},
			{"text": "按钮2", "type": "secondary", "metadata": "btn2"}
		]
	})

func _on_popup_button_pressed(metadata: String):
	print("Button pressed: ", metadata)

func _on_popup_closed():
	print("Popup closed")
```

---

### Task 5: 验收测试

**Files:**
- Test: `scenes/test/test_popup_phase4.tscn`

**验收标准：**

- [ ] 关闭时Shader模糊效果流畅（如果启用blur_close）
- [ ] 背景压暗正确显示在所有弹窗后方（如果启用dim_background）
- [ ] 圆角边缘没有穿帮（BlurOverlay使用liquid_glass_ui shader）
- [ ] 动画过程中按钮不可点击
- [ ] 打开和关闭动画时间符合设计（共约0.5s）
- [ ] 测试场景展示所有特效组合

---

## 技术实现注意事项

1. **BlurOverlay位置同步**：需要在弹出窗体大小变化时更新位置和大小
2. **性能考虑**：Shader模糊在低端设备可能卡顿，提供降级方案
3. **层级关系**：确保 DimBackground < BlurOverlay < GlassPanel 的绘制顺序
4. **配置兼容性**：dim_background和blur_close都是可选配置，默认行为保持不变
