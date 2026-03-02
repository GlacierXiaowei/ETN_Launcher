# Game Card Component - Phase 3: 选中状态与 UI 反馈

> **开发模式:** 助手提供代码和指导，用户手动创建和修改文件
> **重要原则:** 未经用户许可，助手绝不直接修改 .tscn 场景文件

**Goal:** 实现单击选中/取消选中功能、白色边框显示、选中时停止漂浮、点击空白处或滚轮取消选中。

**Architecture:** 
- 选中状态管理在 GameCard 主脚本中
- 组件化架构：漂浮、阴影、拖拽、3D 视觉分离
- 白色边框使用 StyleBoxFlat 实现
- 点击空白处取消选中通过 GUI 输入检测实现
- 发射 `card_selected`和`card_confirmed` 信号供外部使用

**Tech Stack:** Godot 4.x, GDScript, Tween 动画，StyleBoxFlat

---

## Phase 2 交接文档

### ✅ Phase 2 完成清单

#### 1. 组件脚本（全部位于 `component/Card/`）
| 文件 | 状态 | 功能 |
|------|------|------|
| `oscillator.gd` | ✅ 已完成 | 简谐振子物理模拟 |
| `card_float_component.gd` | ✅ 已完成 | 漂浮 + 视差效果 |
| `card_shadow_component.gd` | ✅ 已完成 | 动态阴影偏移 |
| `card_drag_component.gd` | ✅ 已完成 | 拖拽 + 边界限制 |
| `card_3d_visual_component.gd` | ✅ 已完成 | 伪 3D 倾斜效果 |

#### 2. GameCard 主场景
| 文件 | 状态 |
|------|------|
| `scenes/card/game_card.gd` | ✅ 已优化 (147 行) |
| `scenes/card/game_card.tscn` | ✅ 已配置 |

#### 3. 测试场景
| 文件 | 状态 |
|------|------|
| `scenes/test/game_card/test_phase_2.gd` | ✅ 已创建 |
| `scenes/test/game_card/test_phase_2.tscn` | ✅ 已创建 |

### 📐 Phase 2 核心功能验收

| 功能 | 实现方式 | 状态 |
|------|----------|------|
| 空闲漂浮 | Oscillator ±12px 水平，±10px 垂直 | ✅ |
| 鼠标视差 | 视差强度 Vector2(42, 30) | ✅ |
| 动态阴影 | 基于屏幕中心距离计算偏移 | ✅ |
| 拖拽功能 | 边界限制 + 恢复中心 | ✅ |
| 伪 3D 倾斜 | fake_3d.gdshader + Card3DVisualComponent | ✅ |
| 悬停缩放 | Tween + TRANS_ELASTIC | ✅ |
| 信号系统 | 4 个自定义信号 | ✅ |

### 🔧 Phase 2 代码质量优化（已完成）

#### 优化内容
1. **删除未使用变量**: 移除 `_is_selected`, `_current_rot_x`, `_current_rot_y`
2. **删除重复代码**: `_center_in_viewport()` 中重复的 `set_base_position` 调用
3. **删除未使用函数**: `deselect()`, `is_selected()`, `_update_hover_tilt()`
4. **统一接口调用**: 使用 `visual_component.set_rotation_3d()` 而非直接操作 material
5. **精简注释**: 保留必要的功能说明，删除冗余注释

#### 代码统计
| 文件 | 优化前 | 优化后 | 减少 |
|------|--------|--------|------|
| game_card.gd | 184 行 | 147 行 | -37 行 |

### ⚠️ 重要注意事项

#### 1. 组件依赖关系
```
GameCard (主脚本)
├── CardFloatComponent (漂浮 + 视差)
├── CardShadowComponent (阴影)
├── CardDragComponent (拖拽)
│   ├── 信号 drag_started → CardFloatComponent.disable_float()
│   └── 信号 drag_ended → CardFloatComponent.enable_float()
└── Card3DVisualComponent (伪 3D 倾斜)
    └── 内部管理 ShaderMaterial
```

#### 2. 信号连接（TSCN 文件中）
```ini
[connection signal="drag_started" from="CardDragComponent" to="." method="_on_card_drag_component_drag_started"]
[connection signal="drag_ended" from="CardDragComponent" to="." method="_on_card_drag_component_drag_ended"]
[connection signal="gui_input" from="." to="." method="_on_gui_input"]
[connection signal="mouse_entered" from="." to="." method="_on_mouse_entered"]
[connection signal="mouse_exited" from="." to="." method="_on_mouse_exited"]
```

#### 3. Shader 材质配置
`game_card.tscn` 中 CardTexture 的 ShaderMaterial 必须正确引用 `fake_3d.gdshader`，否则 3D 倾斜效果不会显示。

#### 4. 组件调用时序
```gdscript
# GameCard._process() 中
card_drag_component.process_drag()  # 每帧更新拖拽位置
if card_drag_component.is_dragging():
    _update_drag_rotation(delta)  # 拖拽时应用 3D 旋转

# GameCard._on_gui_input() 中
shadow_component.update_shadow_position()  # 每帧更新阴影
card_drag_component.handle_input(event)  # 处理拖拽输入
```

---

## Phase 3 上下文准备（新对话用）

### 📋 当前状态
- **开发阶段**: Phase 2 完成，准备进入 Phase 3
- **代码质量**: 已优化，无重复代码，组件职责清晰
- **待实现**: 选中状态、白色边框、点击确认逻辑

### 🔧 技术债务（无）
- 代码已精简，无明显技术债务
- 组件接口设计合理，易于扩展

### 📁 关键文件路径
```
component/Card/
├── oscillator.gd
├── card_float_component.gd
├── card_shadow_component.gd
├── card_drag_component.gd
└── card_3d_visual_component.gd

scenes/card/
├── game_card.gd (147 行，已优化)
└── game_card.tscn

docs/plans/
├── 2026-03-01-game-card-phase2-float.md (Phase 2 计划)
└── 2026-03-02-game-card-phase3-selection.md (Phase 3 计划 - 当前文件)
```

### 🎯 Phase 3 起始点
从 Task 1 开始执行，使用 `executing-plans` skill。

---

## Task 1: 添加选中状态变量和信号

**Files:**
- Modify: `scenes/card/game_card.gd`

**Step 1: 添加选中相关变量**

```gdscript
signal card_selected(selected: bool)
signal card_confirmed()

var _is_selected: bool = false
var _is_hovering: bool = false
```

**Step 2: 添加 deselect 方法**

```gdscript
func deselect() -> void:
	if not _is_selected:
		return
	
	_is_selected = false
	
	# 动画过渡
	if visual_component:
		visual_component.reset_rotation()
	
	# 隐藏白色边框
	_update_selected_style(false)
	
	card_selected.emit(false)

func select() -> void:
	if _is_selected:
		return
	
	_is_selected = true
	
	# 动画过渡
	if visual_component:
		visual_component.reset_rotation_immediate()
	
	# 显示白色边框
	_update_selected_style(true)
	
	card_selected.emit(true)
```

---

## Task 2: 实现白色边框样式

**Files:**
- Modify: `scenes/card/game_card.tscn`

**Step 1: 添加选中边框样式**

在现有 StyleBoxEmpty 后添加：

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
- Modify: `scenes/card/game_card.gd`

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
- Modify: `scenes/card/game_card.gd`

**Step 1: 修改点击处理函数**

```gdscript
func _check_click_event(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	
	if event.is_pressed():
		_is_potential_click = true
		_click_start_pos = get_global_mouse_position()
	elif event.is_released() and _is_potential_click:
		var moved = get_global_mouse_position().distance_to(_click_start_pos)
		if moved < _click_threshold:
			if _is_selected:
				# 选中状态下点击 → 确认/触发操作
				card_confirmed.emit()
			else:
				# 未选中状态下点击 → 进入选中状态
				select()
		_is_potential_click = false
```

---

## Task 5: 实现点击空白处取消选中

**Files:**
- Modify: `scenes/card/game_card.gd`

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

## Task 6: 创建 Phase 3 测试场景

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
	print("1. 点击卡面 → 进入选中状态（显示白边框、停止漂浮、缩小到 0.95）")
	print("2. 再次点击卡面 → 发出确认信号（card_confirmed）")
	print("3. 点击空白处 → 取消选中（隐藏白边框、恢复漂浮）")
	print("4. 滚轮滚动 → 取消选中")
	print("5. 鼠标悬停时仍保持选中状态")

func _on_card_selected(selected: bool) -> void:
	print("信号：card_selected(", selected, ")")

func _on_card_confirmed() -> void:
	print("信号：card_confirmed - 用户确认操作")

func _input(event: InputEvent) -> void:
	# 滚轮取消选中
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if game_card.is_selected():
				game_card.deselect()
				print("滚轮滚动 → 取消选中")
```

---

## Task 7: 创建点击空白测试区域

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
2. ✅ 选中状态下漂浮停止，卡面缩小到 0.95
3. ✅ 再次点击卡面触发 card_confirmed 信号
4. ✅ 点击空白处取消选中，白边框淡出
5. ✅ 滚轮滚动取消选中状态
6. ✅ 鼠标悬停时保持选中状态（不触发挥手动画）
7. ✅ 选中/取消动画平滑过渡

---

*Plan version: 3.0*
*Phase: 3/5 - 选中状态与 UI 反馈*
*Last Updated: 2026-03-02*
