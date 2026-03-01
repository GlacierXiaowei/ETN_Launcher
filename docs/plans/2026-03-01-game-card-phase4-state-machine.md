# Game Card Component - Phase 4: 状态机集成

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 集成7个状态节点（未安装/检查更新中/有可选更新/需要强制更新/检查失败/准备启动/运行中），每个状态对应不同的弹窗配置，验证状态检测正确性。

**Architecture:** 
- 使用现有的NodeStateMachine框架
- 7个状态作为GameCard的子节点
- 每个状态实现`get_popup_config()`方法返回对应的弹窗配置
- 状态切换时发出信号供外部处理
- 选中状态下点击时根据当前状态显示对应弹窗

**Tech Stack:** Godot 4.x, GDScript, 状态机模式, PopupManager

---

## Task 1: 创建状态基类

**Files:**
- Create: `scenes/main_menu/states/card_state.gd`

**Step 1: 编写状态基类**

```gdscript
extends Node
class_name CardState

signal transition_to(state_name: String)

@export var card: Control

func _ready() -> void:
	# 子类实现
	pass

func _on_enter() -> void:
	# 进入状态时调用
	print("[状态] 进入: ", name)

func _on_exit() -> void:
	# 退出状态时调用
	print("[状态] 退出: ", name)

func get_popup_config() -> Dictionary:
	# 子类必须实现，返回弹窗配置
	return {}

func on_card_confirmed() -> void:
	# 选中状态下点击卡面时的处理
	pass
```

---

## Task 2: 创建7个状态脚本

**Files:**
- Create: `scenes/main_menu/states/not_installed_state.gd`
- Create: `scenes/main_menu/states/checking_update_state.gd`
- Create: `scenes/main_menu/states/update_available_state.gd`
- Create: `scenes/main_menu/states/update_required_state.gd`
- Create: `scenes/main_menu/states/update_failed_state.gd`
- Create: `scenes/main_menu/states/ready_to_launch_state.gd`
- Create: `scenes/main_menu/states/running_state.gd`

**Step 1: NotInstalledState (未安装)**

```gdscript
extends CardState
class_name NotInstalledState

func _on_enter() -> void:
	super._on_enter()
	print("状态: 未安装")

func get_popup_config() -> Dictionary:
	return {
		"title": "游戏未安装",
		"content": "该游戏尚未安装，是否开始安装？",
		"buttons": [
			{"text": "取消", "type": "secondary", "metadata": "cancel"},
			{"text": "安装", "type": "primary", "metadata": "install"}
		]
	}

func on_card_confirmed() -> void:
	# 显示安装确认弹窗
	PopupManager.show_popup(get_popup_config())
```

**Step 2: CheckingUpdateState (检查更新中)**

```gdscript
extends CardState
class_name CheckingUpdateState

func _on_enter() -> void:
	super._on_enter()
	print("状态: 检查更新中")

func get_popup_config() -> Dictionary:
	return {
		"title": "检查更新",
		"content": "正在检查游戏更新...",
		"buttons": []
	}

func on_card_confirmed() -> void:
	# 检查中不允许操作，提示用户等待
	PopupManager.show_alert("请稍候", "正在检查游戏更新，请稍后再试。")
```

**Step 3: UpdateAvailableState (有可选更新)**

```gdscript
extends CardState
class_name UpdateAvailableState

func _on_enter() -> void:
	super._on_enter()
	print("状态: 有可选更新")

func get_popup_config() -> Dictionary:
	return {
		"title": "有可用更新",
		"content": "发现新版本，是否更新？",
		"buttons": [
			{"text": "暂不更新", "type": "secondary", "metadata": "skip"},
			{"text": "更新", "type": "primary", "metadata": "update"}
		]
	}

func on_card_confirmed() -> void:
	PopupManager.show_popup(get_popup_config())
```

**Step 4: UpdateRequiredState (需要强制更新)**

```gdscript
extends CardState
class_name UpdateRequiredState

func _on_enter() -> void:
	super._on_enter()
	print("状态: 需要强制更新")

func get_popup_config() -> Dictionary:
	return {
		"title": "需要更新",
		"content": "游戏版本过旧，需要更新才能继续运行。",
		"buttons": [
			{"text": "更新", "type": "primary", "metadata": "update"}
		]
	}

func on_card_confirmed() -> void:
	PopupManager.show_popup(get_popup_config())
```

**Step 5: UpdateFailedState (检查失败)**

```gdscript
extends CardState
class_name UpdateFailedState

func _on_enter() -> void:
	super._on_enter()
	print("状态: 检查更新失败")

func get_popup_config() -> Dictionary:
	return {
		"title": "检查失败",
		"content": "无法连接到更新服务器，是否重试？",
		"buttons": [
			{"text": "重试", "type": "secondary", "metadata": "retry"},
			{"text": "取消", "type": "primary", "metadata": "cancel"}
		]
	}

func on_card_confirmed() -> void:
	PopupManager.show_popup(get_popup_config())
```

**Step 6: ReadyToLaunchState (准备启动)**

```gdscript
extends CardState
class_name ReadyToLaunchState

func _on_enter() -> void:
	super._on_enter()
	print("状态: 准备启动")

func get_popup_config() -> Dictionary:
	return {
		"title": "启动游戏",
		"content": "确定要启动这款游戏吗？",
		"buttons": [
			{"text": "取消", "type": "secondary", "metadata": "cancel"},
			{"text": "启动", "type": "primary", "metadata": "launch"}
		]
	}

func on_card_confirmed() -> void:
	PopupManager.show_popup(get_popup_config())
```

**Step 7: RunningState (运行中)**

```gdscript
extends CardState
class_name RunningState

func _on_enter() -> void:
	super._on_enter()
	print("状态: 运行中")

func get_popup_config() -> Dictionary:
	return {
		"title": "游戏运行中",
		"content": "游戏正在运行中，是否重新启动？",
		"buttons": [
			{"text": "取消", "type": "secondary", "metadata": "cancel"},
			{"text": "重新启动", "type": "primary", "metadata": "restart"}
		]
	}

func on_card_confirmed() -> void:
	PopupManager.show_popup(get_popup_config())
```

---

## Task 3: 创建状态机管理器

**Files:**
- Create: `scenes/main_menu/game_card_state_machine.gd`

**Step 1: 编写状态机脚本**

```gdscript
extends Node
class_name GameCardStateMachine

signal state_changed(old_state: String, new_state: String)

var states: Dictionary = {}
var current_state: CardState = null
var card: Control

func _ready() -> void:
	# 注册所有状态子节点
	for child in get_children():
		if child is CardState:
			states[child.name.to_lower()] = child
			child.card = card
	
	# 默认进入第一个状态
	if states.size() > 0:
		var first_state_name = states.keys()[0]
		transition_to(first_state_name)

func transition_to(state_name: String) -> void:
	var new_state = states.get(state_name.to_lower())
	if new_state == null:
		push_warning("状态不存在: ", state_name)
		return
	
	if current_state == new_state:
		return
	
	var old_state_name = ""
	if current_state:
		old_state_name = current_state.name
		current_state._on_exit()
	
	current_state = new_state
	current_state._on_enter()
	
	state_changed.emit(old_state_name, current_state.name)
	print("[状态机] ", old_state_name, " → ", current_state.name)

func get_current_state_name() -> String:
	if current_state:
		return current_state.name.to_lower()
	return ""

func get_current_popup_config() -> Dictionary:
	if current_state:
		return current_state.get_popup_config()
	return {}

func on_confirmed() -> void:
	if current_state:
		current_state.on_card_confirmed()
```

---

## Task 4: 更新GameCard集成状态机

**Files:**
- Modify: `scenes/main_menu/game_card.gd`

**Step 1: 添加状态机引用**

```gdscript
@onready var state_machine: GameCardStateMachine = $StateMachine
```

**Step 2: 修改确认处理**

```gdscript
func _on_card_clicked() -> void:
	if _is_selected:
		# 选中状态下点击 → 根据当前状态处理
		card_confirmed.emit()
		if state_machine:
			state_machine.on_confirmed()
	else:
		select()
```

**Step 3: 添加状态切换方法**

```gdscript
func set_game_state(state_name: String) -> void:
	if state_machine:
		state_machine.transition_to(state_name)

func get_game_state() -> String:
	if state_machine:
		return state_machine.get_current_state_name()
	return ""
```

---

## Task 5: 更新场景文件

**Files:**
- Modify: `scenes/main_menu/game_card.tscn`

**Step 1: 添加状态节点**

在场景中添加7个状态节点：

```ini
[node name="StateMachine" type="Node" parent="."]
script = ExtResource("7_statemachine")

[node name="NotInstalledState" type="Node" parent="StateMachine"]
script = ExtResource("8_notinstalled")

[node name="CheckingUpdateState" type="Node" parent="StateMachine"]
script = ExtResource("9_checking")

[node name="UpdateAvailableState" type="Node" parent="StateMachine"]
script = ExtResource("10_updateavail")

[node name="UpdateRequiredState" type="Node" parent="StateMachine"]
script = ExtResource("11_updatereq")

[node name="UpdateFailedState" type="Node" parent="StateMachine"]
script = ExtResource("12_updatefail")

[node name="ReadyToLaunchState" type="Node" parent="StateMachine"]
script = ExtResource("13_ready")

[node name="RunningState" type="Node" parent="StateMachine"]
script = ExtResource("14_running")
```

需要添加对应的ext_resource引用

---

## Task 6: 创建Phase 4测试场景

**Files:**
- Create: `scenes/test/game_card/test_phase4.tscn`
- Create: `scenes/test/game_card/test_phase4.gd`

**Step 1: 编写测试脚本**

```gdscript
extends Control

@onready var game_card = $GameCard

var state_buttons: Dictionary = {}

func _ready() -> void:
	_create_state_buttons()
	
	print("=== Phase 4 测试 ===")
	print("测试内容：")
	print("1. 点击按钮切换不同状态")
	print("2. 选中卡面后点击，查看各状态的弹窗配置")
	print("3. 验证状态切换日志")

func _create_state_buttons() -> void:
	var states = ["not_installed", "checking_update", "update_available", 
	              "update_required", "update_failed", "ready_to_launch", "running"]
	
	var y_offset = 150
	for state in states:
		var btn = Button.new()
		btn.text = "设置为: " + state
		btn.position = Vector2(50, y_offset)
		btn.pressed.connect(_on_state_button_pressed.bind(state))
		add_child(btn)
		state_buttons[state] = btn
		y_offset += 50

func _on_state_button_pressed(state: String) -> void:
	game_card.set_game_state(state)
	print("切换到状态: ", state)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# 快捷键测试各状态弹窗
		match event.keycode:
			KEY_1: game_card.set_game_state("not_installed")
			KEY_2: game_card.set_game_state("checking_update")
			KEY_3: game_card.set_game_state("update_available")
			KEY_4: game_card.set_game_state("update_required")
			KEY_5: game_card.set_game_state("update_failed")
			KEY_6: game_card.set_game_state("ready_to_launch")
			KEY_7: game_card.set_game_state("running")
```

---

## 验收标准

1. ✅ 7个状态可以正常切换
2. ✅ 每个状态有对应的get_popup_config()返回正确配置
3. ✅ 选中状态下点击卡面显示对应状态的弹窗
4. ✅ 状态切换时有日志输出
5. ✅ ReadyToLaunch状态点击显示启动确认
6. ✅ Running状态点击显示重启确认
7. ✅ 状态机正确初始化到第一个状态

---

*Plan version: 2.0*
*Phase: 4/5 - 状态机集成*
