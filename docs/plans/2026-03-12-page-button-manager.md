# Page Button Manager 实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 实现页面按钮管理器，支持 4 个按钮互斥选中并触发翻页。

**Architecture:** 
- `GlassIconPanel` 添加 `is_selected` 和 `page_index` 属性
- `PageButtonManager` 管理按钮状态，监听点击，调用翻页
- 用户在编辑器配置 `page_index` 元数据

**Tech Stack:** GDScript, Godot 4.x

---

## Task 1: 修改 GlassIconPanel 添加选中属性

**Files:**
- Modify: `component/GlassComponent/glass_icon_panel.gd`

**Step 1: 添加 is_selected 属性**

在 `@export_group("State")` 下添加：

```gdscript
@export var is_selected: bool = false:
	set(v):
		is_selected = v
		_is_pressed = v
		_update_glass_state()
```

**Step 2: 添加 page_index 元数据属性**

在属性区域添加：

```gdscript
@export var page_index: int = 0
```

**Step 3: 修改 button_up 逻辑防止弹起**

找到 `_hit_button.button_up.connect` 的位置，修改为：

```gdscript
_hit_button.button_up.connect(func() -> void:
	if is_selected:
		return
	_is_pressed = false
	_update_glass_state()
)
```

---

## Task 2: 编写 PageButtonManager 脚本

**Files:**
- Modify: `component/MainMenu/page_button_manager.gd`

**Step 1: 编写完整脚本**

```gdscript
extends Node

signal page_selected(page_index: int)

@export var buttons: Array[GlassIconPanel] = []
@export var initial_page: int = 1

var _current_page: int = -1
var _main_menu: Control = null

func _ready() -> void:
	await get_tree().process_frame
	_find_main_menu()
	_connect_buttons()
	_set_initial_page()

func _find_main_menu() -> void:
	var parent = get_parent()
	while parent:
		if parent.has_method("turn_to_page"):
			_main_menu = parent
			return
		parent = parent.get_parent()

func _connect_buttons() -> void:
	for i in range(buttons.size()):
		var btn = buttons[i]
		if btn == null:
			continue
		btn.pressed.connect(_on_button_pressed.bind(i))

func _set_initial_page() -> void:
	if buttons.size() == 0:
		return
	_select_page(initial_page)

func _on_button_pressed(index: int) -> void:
	if index == _current_page:
		return
	_select_page(index)

func _select_page(index: int) -> void:
	if index < 0 or index >= buttons.size():
		return
	
	if _current_page >= 0 and _current_page < buttons.size():
		buttons[_current_page].is_selected = false
	
	_current_page = index
	buttons[index].is_selected = true
	
	page_selected.emit(index)
	
	if _main_menu:
		_main_menu.turn_to_page(index)

func get_current_page() -> int:
	return _current_page
```

---

## Task 3: 用户在编辑器配置（手动操作）

**操作步骤：**

1. 打开 `main_menu.tscn`
2. 找到 `CanvasLayer/Node/MarginContainer/VBoxContainer/` 下的 4 个 PageButton
3. 为每个按钮配置：

| 节点 | page_index | 备注 |
|------|------------|------|
| PageButton1 | 0 | 设置页 |
| PageButton2 | 1 | 游戏1（默认页） |
| PageButton3 | 2 | 游戏2 |
| PageButton4 | 3 | 游戏3/测试页 |

4. 在 `PageButtonManager` 节点的 `buttons` 数组中添加 4 个按钮引用
5. 设置 `initial_page = 1`

---

## Task 4: 测试验证

**Step 1: 运行场景**

运行 `main_menu.tscn`

**Step 2: 验证功能**

- [ ] PageButton2 默认显示按下样式（蓝色）
- [ ] 点击 PageButton1，PageButton2 弹起，PageButton1 按下
- [ ] 点击已选中的按钮，无变化
- [ ] 点击按钮触发翻页动画
- [ ] 滚轮翻页时按钮状态同步更新（可选功能，后续实现）

---

## Task 5: 创建 LauncherInstallComponent（启动器更新模块）

**Files:**
- Create: `component/InstallComponent/launcher_install_component.gd`

**说明：**
- 扩展 `InstallComponent`，专门处理启动器更新检测
- 设置 `game_name = "ETN_Launcher"`
- 路径使用 APPDATA（已确认）

**Step 1: 创建脚本**

```gdscript
extends InstallComponent
class_name LauncherInstallComponent

func _ready() -> void:
	game_name = "ETN_Launcher"
	super._ready()
```

**Step 2: 使用方式**

在场景中将需要启动器更新检测的节点脚本改为 `LauncherInstallComponent`。

---

*计划版本: v1.1*
*创建日期: 2026-03-12*