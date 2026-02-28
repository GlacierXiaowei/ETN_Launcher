# Phase2: 多按钮与布局系统实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 实现1-3个按钮的动态生成，全部使用右对齐，支持灵活的按钮尺寸配置。

**Architecture:** 修改现有 GlobalPopup 脚本的按钮构建逻辑，统一使用右对齐，并添加按钮级尺寸配置支持。

**Tech Stack:** Godot 4.x, GDScript, GlassButton 组件

---

## 当前状态（Phase1 已完成）
- ✅ GlobalPopup 可显示 1-3 个按钮
- ✅ 按钮布局：2个右对齐，3个左对齐
- ✅ metadata 回调机制
- ✅ show_confirm / show_alert 快捷方法

---

## 需要实现的功能

### 1. 按钮对齐方式修改
**当前逻辑：**
- 1个按钮：居中
- 2个按钮：右对齐
- 3个按钮：左对齐

**修改为：**
- 全部使用右对齐（BoxContainer.ALIGNMENT_END）

### 2. 按钮尺寸配置支持
在按钮配置中添加可选字段：
- `min_width`: 最小宽度（默认 140）
- `min_height`: 最小高度（默认 48）

配置示例：
```gdscript
{
  "text": "确定",
  "type": "primary",
  "metadata": "confirm",
  "min_width": 160,
  "min_height": 56
}
```

### 3. 测试场景
创建 `scenes/test/test_popup_phase2.tscn` 和对应的 `.gd` 脚本

---

## 实现步骤

### Task 1: 修改 GlobalPopup 按钮对齐逻辑

**Files:**
- Modify: `component/GlassComponent/global_popup.gd:94-97`

**Step 1: 查看当前代码**

当前代码（约第94-97行）：
```gdscript
if _buttons.size() == 2:
    button_container.alignment = BoxContainer.ALIGNMENT_END
elif _buttons.size() >= 3:
    button_container.alignment = BoxContainer.ALIGNMENT_BEGIN
```

**Step 2: 修改为全部右对齐**

```gdscript
# 全部使用右对齐
button_container.alignment = BoxContainer.ALIGNMENT_END
```

**Step 3: 提交更改**

---

### Task 2: 添加按钮尺寸配置支持

**Files:**
- Modify: `component/GlassComponent/global_popup.gd:71-92`

**Step 1: 在 _build_buttons 方法中添加尺寸配置**

在创建按钮后添加尺寸设置逻辑（约第91行后）：

```gdscript
# 设置自定义尺寸（如果配置了）
if btn_config.has("min_width") or btn_config.has("min_height"):
    var min_size := btn.custom_minimum_size
    if btn_config.has("min_width"):
        min_size.x = btn_config["min_width"]
    if btn_config.has("min_height"):
        min_size.y = btn_config["min_height"]
    btn.custom_minimum_size = min_size
```

**Step 2: 提交更改**

---

### Task 3: 创建测试场景

**Files:**
- Create: `scenes/test/test_popup_phase2.tscn`
- Create: `scenes/test/test_popup_phase2.gd`

**Step 1: 创建测试场景 TSCN**

参考 `test_popup_phase1.tscn`，创建类似的测试界面

**Step 2: 编写测试脚本**

测试内容：
1. 打开1个按钮的弹窗
2. 打开2个按钮的弹窗
3. 打开3个按钮的弹窗（验证右对齐）
4. 验证每个按钮返回正确的 metadata
5. 测试自定义尺寸按钮
6. 测试 show_confirm() 快捷方法

```gdscript
extends Control

@onready var status_label: Label = $VBox/StatusLabel

var _test_results: Array[String] = []

func _ready() -> void:
    PopupManager.popup_button_pressed.connect(_on_popup_button_pressed)
    _add_status("Phase2 测试就绪")

# 测试1: 单按钮弹窗
func test_single_button() -> void:
    _add_status("测试1: 单按钮弹窗")
    PopupManager.show_popup({
        "title": "单按钮测试",
        "content": "这是一个单按钮弹窗",
        "buttons": [
            {"text": "确定", "type": "primary", "metadata": "single_ok"}
        ]
    })

# 测试2: 双按钮弹窗
func test_two_buttons() -> void:
    _add_status("测试2: 双按钮弹窗")
    PopupManager.show_popup({
        "title": "双按钮测试",
        "content": "这是一个双按钮弹窗",
        "buttons": [
            {"text": "取消", "type": "secondary", "metadata": "cancel"},
            {"text": "确定", "type": "primary", "metadata": "confirm"}
        ]
    })

# 测试3: 三按钮弹窗
func test_three_buttons() -> void:
    _add_status("测试3: 三按钮弹窗")
    PopupManager.show_popup({
        "title": "三按钮测试",
        "content": "这是一个三按钮弹窗",
        "buttons": [
            {"text": "选项A", "type": "secondary", "metadata": "option_a"},
            {"text": "选项B", "type": "secondary", "metadata": "option_b"},
            {"text": "确定", "type": "primary", "metadata": "confirm"}
        ]
    })

# 测试4: 自定义尺寸按钮
func test_custom_size() -> void:
    _add_status("测试4: 自定义尺寸按钮")
    PopupManager.show_popup({
        "title": "自定义尺寸测试",
        "content": "按钮使用自定义尺寸",
        "buttons": [
            {"text": "大按钮", "type": "primary", "metadata": "big", "min_width": 200, "min_height": 60},
            {"text": "小按钮", "type": "secondary", "metadata": "small", "min_width": 100, "min_height": 36}
        ]
    })

# 测试5: show_confirm 快捷方法
func test_show_confirm() -> void:
    _add_status("测试5: show_confirm 快捷方法")
    PopupManager.show_confirm(
        "确认操作",
        "确定要执行此操作吗？",
        func(): _add_status("确认回调"),
        func(): _add_status("取消回调")
    )

func _on_popup_button_pressed(metadata: String) -> void:
    _add_status("收到回调: " + metadata)

func _add_status(msg: String) -> void:
    status_label.text = msg
    _test_results.append(msg)
    print("[TestPhase2] " + msg)
```

**Step 3: 在测试场景中添加按钮来触发各个测试**

创建多个按钮，每个触发不同的测试函数

**Step 4: 提交更改**

---

## 验收标准

- [ ] 全部按钮使用右对齐
- [ ] 支持按钮级尺寸配置（min_width, min_height）
- [ ] 测试场景覆盖所有测试用例
- [ ] 回调正确返回 metadata

---

## 计划完成

计划已保存至 `docs/plans/2026-03-01-popup-phase2-buttons.md`

**两个执行选项：**

1. **Subagent-Driven (当前会话)** - 每个任务分配新的子代理，任务间审查，快速迭代

2. **Parallel Session (单独会话)** - 在新会话中打开，使用 executing-plans，批量执行带检查点

请选择执行方式。
