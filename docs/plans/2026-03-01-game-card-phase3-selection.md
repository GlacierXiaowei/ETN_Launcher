# Game Card Component - Phase 3: 选中状态与UI反馈

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 实现单击选中/取消选中功能、白色边框显示、选中时停止漂浮、点击空白处或滚轮取消选中。

**Architecture:** 
- 选中状态管理在GameCard主脚本中
- CardAnimationComponent提供选中/取消选中的动画过渡
- 白色边框使用StyleBoxFlat实现
- 点击空白处取消选中通过GUI输入检测实现
- 发射`card_selected`和`card_confirmed`信号供外部使用

**Tech Stack:** Godot 4.x, GDScript, Tween动画, StyleBoxFlat

---

## Task 1: 添加选中状态变量和信号

**Files:**
- Modify: `scenes/main_menu/game_card.gd`

**Step 1: 添加选中相关变量**

```gdscript
signal card_selected(selected: bool)
signal card_confirmed()

var _is_selected: bool = false
var _is_hovering: bool = false
```

**Step 2: 添加deselect方法**

```gdscript
func deselect() -> void:
	if not _is_selected:
		return
	
	_is_selected = false
	
	# 动画过渡
	if animation_component:
		animation_component.set_selected(false)
		animation_component.transition_to_idle_float()
		animation_component.scale_to_normal()
	
	# 隐藏白色边框
	_update_selected_style(false)
	
	card_selected.emit(false)

func select() -> void:
	if _is_selected:
		return
	
	_is_selected = true
	
	# 动画过渡
	if animation_component:
		animation_component.set_selected(true)
		animation_component.disable_floating()
		animation_component.scale_to_selected()
	
	# 显示白色边框
	_update_selected_style(true)
	
	card_selected.emit(true)
```

---

## Task 2: 实现白色边框样式

**Files:**
- Modify: `scenes/main_menu/game_card.tscn`

**Step 1: 添加选中边框样式**

在现有StyleBoxEmpty后添加：

```ini
[sub_resource type="StyleBoxFlat" id="selected_border"]
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
```

**Step 2: 创建边框节点**

在场景中添加：

```ini
[node name="SelectedBorder" type="Panel" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
theme_override_styles/panel = SubResource("selected_border")
```

---

## Task 3: 添加边框控制方法

**Files:**
- Modify: `scenes/main_menu/game_card.gd`

**Step 1: 添加边框节点引用**

```gdscript
@onready var selected_border: Panel = $SelectedBorder
```

**Step 2: 添加边框更新方法**

```gdscript
func _update_selected_style(show: bool) -> void:
	if selected_border:
		var target_modulate = Color(1, 1, 1, 1.0) if show else Color(1, 1, 1, 0.0)
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(selected_border, "modulate:a", target_modulate.a, 0.3)
```

---

## Task 4: 实现点击处理逻辑

**Files:**
- Modify: `scenes/main_menu/game_card.gd`

**Step 1: 修改点击处理函数**

```gdscript
func _on_card_clicked() -> void:
	if _is_selected:
		# 选中状态下点击 → 确认/触发操作
		card_confirmed.emit()
	else:
		# 未选中状态下点击 → 进入选中状态
		select()
```

---

## Task 5: 实现点击空白处取消选中

**Files:**
- Modify: `scenes/main_menu/game_card.gd`

**Step 1: 添加输入检测**

```gdscript
func _gui_input(event: InputEvent) -> void:
	# 点击空白处取消选中
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 检查是否点击在卡面区域外
		if not _is_at_card_area(event.position):
			if _is_selected:
				deselect()

func _is_at_card_area(local_pos: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(local_pos)
```

---

## Task 6: 更新CardAnimationComponent支持选中

**Files:**
- Modify: `scenes/main_menu/components/card_animation_component.gd`

**Step 1: 添加选中状态变量**

```gdscript
var _is_selected: bool = false

func set_selected(selected: bool) -> void:
	_is_selected = selected
```

**Step 2: 修改悬停处理以考虑选中状态**

在transition相关函数中检查_is_selected状态

---

## Task 7: 创建Phase 3测试场景

**Files:**
- Create: `scenes/test/game_card/test_phase3.tscn`
- Create: `scenes/test/game_card/test_phase3.gd`

**Step 1: 编写测试脚本**

```gdscript
extends Control

@onready var game_card = $GameCard

func _ready() -> void:
	# 连接信号
	game_card.card_selected.connect(_on_card_selected)
	game_card.card_confirmed.connect(_on_card_confirmed)
	
	print("=== Phase 3 测试 ===")
	print("测试内容：")
	print("1. 点击卡面 → 进入选中状态（显示白边框、停止漂浮、缩小到0.95）")
	print("2. 再次点击卡面 → 发出确认信号（card_confirmed）")
	print("3. 点击空白处 → 取消选中（隐藏白边框、恢复漂浮）")
	print("4. 滚轮滚动 → 取消选中")
	print("5. 鼠标悬停时仍保持选中状态")

func _on_card_selected(selected: bool) -> void:
	print("信号: card_selected(", selected, ")")

func _on_card_confirmed() -> void:
	print("信号: card_confirmed - 用户确认操作")

func _input(event: InputEvent) -> void:
	# 滚轮取消选中
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if game_card.is_selected():
				game_card.deselect()
				print("滚轮滚动 → 取消选中")
```

---

## Task 8: 创建点击空白测试区域

**Files:**
- Modify: `scenes/test/game_card/test_phase3.tscn`

**Step 1: 在场景中添加测试背景**

添加一个覆盖整个屏幕的不可见按钮用于检测点击空白区域

```ini
[node name="ClickOutsideDetector" type="Button" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
text = "点击这里取消选中"
```

---

## 验收标准

1. ✅ 点击卡面进入选中状态（白边框淡入）
2. ✅ 选中状态下漂浮停止，卡面缩小到0.95
3. ✅ 再次点击卡面触发card_confirmed信号
4. ✅ 点击空白处取消选中，白边框淡出
5. ✅ 滚轮滚动取消选中状态
6. ✅ 鼠标悬停时保持选中状态（不触发挥手动画）
7. ✅ 选中/取消动画平滑过渡

---

*Plan version: 2.0*
*Phase: 3/5 - 选中状态与UI反馈*
