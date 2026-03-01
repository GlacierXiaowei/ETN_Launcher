# Game Card Component - Phase 5: 完整测试与验收

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 创建完整的单卡面测试场景，验证所有功能的集成效果，包括视觉效果、状态机、交互流程的完整测试。

**Architecture:** 
- 单一测试场景覆盖所有功能点
- 详细的调试输出帮助定位问题
- 模拟不同场景的完整交互流程
- 验证与其他系统（PopupManager）的集成

**Tech Stack:** Godot 4.x, GDScript, 集成测试

---

## Task 1: 创建完整测试场景

**Files:**
- Create: `scenes/test/game_card/test_phase5.tscn`
- Create: `scenes/test/game_card/test_phase5.gd`

**Step 1: 编写完整测试脚本**

```gdscript
extends Control

@onready var game_card = $GameCard

var test_results: Dictionary = {}
var current_test: String = ""

func _ready() -> void:
	_connect_signals()
	_create_ui()
	_start_test_sequence()
	
	print("=" * 50)
	print("Phase 5: 完整功能测试")
	print("=" * 50)

func _connect_signals() -> void:
	# 连接卡面信号
	game_card.card_selected.connect(_on_card_selected)
	game_card.card_confirmed.connect(_on_card_confirmed)
	game_card.card_deselected.connect(_on_card_deselected)

func _create_ui() -> void:
	# 创建测试说明面板
	var info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.text = "Phase 5 完整测试\n\n测试项目:\n1. 视觉效果(漂浮/倾斜/阴影)\n2. 选中状态\n3. 状态机切换\n4. 弹窗集成\n\n按 空格键 运行自动测试"
	info_label.position = Vector2(20, 20)
	info_label.add_theme_font_size_override("font_size", 18)
	add_child(info_label)
	
	# 创建结果显示面板
	var result_label = Label.new()
	result_label.name = "ResultLabel"
	result_label.text = "等待测试..."
	result_label.position = Vector2(20, 250)
	result_label.add_theme_font_size_override("font_size", 16)
	add_child(result_label)

func _start_test_sequence() -> void:
	# 自动测试序列（用户触发）
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_run_auto_tests()

func _run_auto_tests() -> void:
	print("\n开始自动测试序列...")
	
	# Test 1: 视觉效果测试
	_test_visual_effects()
	await get_tree().create_timer(2.0).timeout
	
	# Test 2: 选中状态测试
	_test_selection()
	await get_tree().create_timer(2.0).timeout
	
	# Test 3: 状态机测试
	_test_state_machine()
	await get_tree().create_timer(2.0).timeout
	
	# Test 4: 取消选中测试
	_test_deselection()
	await get_tree().create_timer(2.0).timeout
	
	_print_results()

func _test_visual_effects() -> void:
	current_test = "视觉效果测试"
	print("\n[Test 1] ", current_test)
	
	# 检查组件是否存在
	var has_animation = game_card.has_node("CardAnimationComponent")
	var has_shadow = game_card.has_node("CardShadowComponent")
	var has_visual = game_card.has_node("CardVisualComponent")
	
	test_results["视觉效果"] = has_animation and has_shadow and has_visual
	print("  - CardAnimationComponent存在: ", has_animation)
	print("  - CardShadowComponent存在: ", has_shadow)
	print("  - CardVisualComponent存在: ", has_visual)

func _test_selection() -> void:
	current_test = "选中状态测试"
	print("\n[Test 2] ", current_test)
	
	# 模拟点击选中
	game_card.select()
	await get_tree().create_timer(0.5).timeout
	
	var is_selected = game_card.is_selected()
	test_results["选中状态"] = is_selected
	print("  - 卡面已选中: ", is_selected)
	print("  - 状态: ", game_card.get_game_state())

func _test_state_machine() -> void:
	current_test = "状态机测试"
	print("\n[Test 3] ", current_test)
	
	# 切换不同状态
	var states = ["ready_to_launch", "not_installed", "update_available", "running"]
	
	for state in states:
		game_card.set_game_state(state)
		await get_tree().create_timer(0.3).timeout
		var current = game_card.get_game_state()
		test_results["状态机_" + state] = (current == state)
		print("  - 切换到", state, ": ", current == state)

func _test_deselection() -> void:
	current_test = "取消选中测试"
	print("\n[Test 4] ", current_test)
	
	# 取消选中
	game_card.deselect()
	await get_tree().create_timer(0.5).timeout
	
	var is_not_selected = not game_card.is_selected()
	test_results["取消选中"] = is_not_selected
	print("  - 卡面已取消选中: ", is_not_selected)

func _on_card_selected(selected: bool) -> void:
	print("[信号] card_selected(", selected, ")")

func _on_card_confirmed() -> void:
	print("[信号] card_confirmed - 确认操作已触发")

func _on_card_deselected() -> void:
	print("[信号] card_deselected")

func _print_results() -> void:
	print("\n" + "=" * 50)
	print("测试结果汇总:")
	print("=" * 50)
	
	var passed = 0
	var failed = 0
	
	for test_name in test_results:
		var result = test_results[test_name]
		var status = "✓ PASS" if result else "✗ FAIL"
		print(test_name, ": ", status)
		if result:
			passed += 1
		else:
			failed += 1
	
	print("\n总计: ", passed, " 通过, ", failed, " 失败")
	print("=" * 50)
	
	# 更新UI显示
	var result_label = get_node_or_null("ResultLabel")
	if result_label:
		result_label.text = "测试完成\n通过: %d\n失败: %d" % [passed, failed]
```

---

## Task 2: 创建键盘快捷键测试

**Files:**
- Modify: `scenes/test/game_card/test_phase5.gd`

**Step 1: 添加快捷键测试功能**

```gdscript
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _quick_test("not_installed")
			KEY_2: _quick_test("checking_update")
			KEY_3: _quick_test("update_available")
			KEY_4: _quick_test("update_required")
			KEY_5: _quick_test("update_failed")
			KEY_6: _quick_test("ready_to_launch")
			KEY_7: _quick_test("running")
			KEY_S: _simulate_click()  # 选中
			KEY_D: game_card.deselect()  # 取消选中
			KEY_SPACE: _run_auto_tests()

func _quick_test(state: String) -> void:
	game_card.set_game_state(state)
	print("快速测试: 切换到状态 -> ", state)

func _simulate_click() -> void:
	# 模拟用户点击
	game_card.select()
	print("快速测试: 选中卡面")
```

---

## Task 3: 创建调试信息面板

**Files:**
- Modify: `scenes/test/game_card/test_phase5.tscn`

**Step 1: 添加实时状态显示**

创建动态更新显示当前状态的UI元素：

```ini
[node name="DebugPanel" type="PanelContainer" parent="."]
layout_mode = 1
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -250.0
offset_top = 20.0
offset_right = -20.0
offset_bottom = 200.0
grow_horizontal = 0

[node name="DebugLabel" type="RichTextLabel" parent="DebugPanel"]
layout_mode = 2
bbcode_enabled = true
text = "[b]调试信息[/b]"
```

---

## Task 4: 创建交互流程测试

**Files:**
- Modify: `scenes/test/game_card/test_phase5.gd`

**Step 1: 添加完整交互流程测试**

```gdscript
func _test_complete_flow() -> void:
	"""
	完整用户流程测试:
	1. 用户看到卡面漂浮
	2. 鼠标移入 → 卡面抬起(放大+更大漂浮)
	3. 鼠标移动 → 3D倾斜跟随
	4. 点击 → 进入选中状态
	5. 再次点击 → 弹出对应状态的确认弹窗
	6. 点击空白处 → 取消选中
	"""
	print("\n=== 完整交互流程测试 ===")
	
	# Step 1: 观察漂浮（自动）
	print("1. 观察卡面自然漂浮...")
	await get_tree().create_timer(1.0).timeout
	
	# Step 2: 模拟鼠标移入
	print("2. 模拟鼠标移入（悬停效果）...")
	# 通过代码模拟鼠标进入区域
	await get_tree().create_timer(1.0).timeout
	
	# Step 3: 选中
	print("3. 点击选中...")
	game_card.select()
	await get_tree().create_timer(0.5).timeout
	
	# Step 4: 确认
	print("4. 再次点击触发确认...")
	game_card.card_confirmed.emit()
	await get_tree().create_timer(1.0).timeout
	
	# Step 5: 取消选中
	print("5. 点击空白处取消选中...")
	game_card.deselect()
	await get_tree().create_timer(0.5).timeout
	
	print("=== 流程测试完成 ===")
```

---

## Task 5: 添加性能监控

**Files:**
- Modify: `scenes/test/game_card/test_phase5.gd`

**Step 1: 添加帧率监控**

```gdscript
var _frame_times: Array[float] = []
var _last_time: int = 0

func _process(delta: float) -> void:
	# 记录帧时间用于性能分析
	var current_time = Time.get_ticks_msec()
	if _last_time > 0:
		_frame_times.append(current_time - _last_time)
		if _frame_times.size() > 60:
			_frame_times.pop_front()
	_last_time = current_time

func _get_average_fps() -> float:
	if _frame_times.size() == 0:
		return 0.0
	var avg = 0.0
	for t in _frame_times:
		avg += t
	avg /= _frame_times.size()
	return 1000.0 / avg if avg > 0 else 0.0
```

---

## Task 6: 创建测试报告生成

**Files:**
- Modify: `scenes/test/game_card/test_phase5.gd`

**Step 1: 生成测试报告**

```gdscript
func generate_test_report() -> String:
	var report = "GameCard 测试报告\n"
	report += "=" * 30 + "\n"
	report += "测试时间: " + Time.get_datetime_string_from_system() + "\n"
	report += "平均帧率: %.1f FPS\n" % _get_average_fps()
	report += "\n测试结果:\n"
	
	for test_name in test_results:
		var result = test_results[test_name]
		report += "- %s: %s\n" % [test_name, "PASS" if result else "FAIL"]
	
	report += "\n详细日志已输出到控制台"
	
	return report

func _print_final_report() -> void:
	print(generate_test_report())
```

---

## 验收标准

1. ✅ 场景能正常运行，无报错
2. ✅ 所有5个Phase的功能集成正常
3. ✅ 视觉效果测试通过（漂浮/倾斜/阴影）
4. ✅ 选中/取消选中功能正常
5. ✅ 7个状态可以切换
6. ✅ 弹窗系统集成正常
7. ✅ 帧率保持稳定（>30 FPS）
8. ✅ 调试信息清晰可见

---

## 调试检查清单

在每个Phase测试时确认以下日志输出：
- [ ] Phase 1: 场景加载成功，Shader编译成功
- [ ] Phase 2: 漂浮动画运行，阴影跟随
- [ ] Phase 3: 选中状态切换日志
- [ ] Phase 4: 状态切换日志
- [ ] Phase 5: 完整测试结果汇总

---

*Plan version: 2.0*
*Phase: 5/5 - 完整测试与验收*
