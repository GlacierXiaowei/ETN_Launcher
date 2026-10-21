# State Machine API 参考

> 游戏卡面状态管理系统 - 7 种游戏状态切换与弹窗联动

**版本：** 1.1  
**最后更新：** 2026-03-05

---

## ⚠️ 重要约定：状态名称格式

**所有状态名称必须使用全小写（无下划线）格式！**

| 正确 ✅ | 错误 ❌ |
|--------|--------|
| `"notinstalled"` | `"NotInstalled"` |
| `"checkingupdate"` | `"CheckingUpdate"` |
| `"uptodate"` | `"UpToDate"` |
| `"runningstate"` | `"RunningState"` |

**原因：** `transition_to()` 方法内部会将传入的名称转为小写后匹配节点，但为了代码一致性和避免混淆，**调用时请直接使用小写格式**。

**状态名称转换规则：**
- 枚举名：`NOT_INSTALLED` → 状态名：`"notinstalled"`
- 节点名：`NotInstalled` → 状态名：`"notinstalled"`
- 转换函数：使用 `_to_lowercase()` 而非 `_to_pascal_case()`

---

## 🚀 快速开始

### 30 秒上手

**Game Card State Machine** 是一个基于节点的状态机系统，用于管理游戏卡面的 7 种状态（未安装/检查更新中/有可选更新/需要强制更新/检查失败/准备启动/运行中），每个状态对应不同的弹窗配置。

外部只需**监听 1 个信号**、**调用 1 个方法**即可控制所有状态。

---

### 第一步：获取状态机引用

```gdscript
# 在你的场景脚本中（如 CardPanel）
@onready var state_machine: NodeStateMachine = $StateMachine
```

---

### 第二步：连接信号

```gdscript
func _ready() -> void:
    # 状态变化信号
    state_machine.state_changed.connect(_on_state_changed)
```

---

### 第三步：监听状态变化

```gdscript
func _on_state_changed(old_state: String, new_state: String) -> void:
    match new_state:
        "notinstalledstate":
            print("游戏未安装")
            _show_install_button()

        "checkingupdatestate":
            print("正在检查更新...")
            _show_loading()

        "updateavailablestate":
            print("有可选更新")
            _show_update_button()

        "updaterequiredstate":
            print("需要强制更新")
            _show_force_update_button()

        "updatefailedstate":
            print("检查失败")
            _show_retry_button()

        "readytolaunchstate":
            print("准备启动")
            _show_launch_button()

        "runningstate":
            print("游戏运行中")
            _show_restart_button()
```

---

### 第四步：切换状态

```gdscript
# 方法 1：直接调用状态机的 transition_to
state_machine.transition_to("notinstalled")  # ← 注意：全小写，无下划线
state_machine.transition_to("checkingupdate")
state_machine.transition_to("uptodate")
state_machine.transition_to("runningstate")

# 方法 2：通过状态管理器（推荐）
card_panel.set_game_state("ready_to_launch")
```

**⚠️ 常见错误：**
```gdscript
# ❌ 错误：使用大驼峰
state_machine.transition_to("NotInstalled")  # 不会工作！
state_machine.transition_to("UpToDate")      # 不会工作！

# ✅ 正确：使用全小写
state_machine.transition_to("notinstalled")  # 正确
state_machine.transition_to("uptodate")      # 正确
```

---

### 完整示例

```gdscript
extends Control
class_name CardPanelController

@onready var state_machine: NodeStateMachine = $StateMachine
@onready var state_label: Label = $StateLabel
@onready var action_button: Button = $ActionButton
@onready var game_card: GameCard = $GameCard

func _ready() -> void:
    state_machine.state_changed.connect(_on_state_changed)
    action_button.pressed.connect(_on_action_button_pressed)

    # 初始化状态
    state_machine.transition_to("checkingupdatestate")

func _on_state_changed(old_state: String, new_state: String) -> void:
    match new_state:
        "notinstalled":
            state_label.text = "游戏未安装"
            action_button.text = "获取"
            action_button.visible = true

        "checkingupdate":
            state_label.text = "正在检查更新..."
            action_button.visible = false

        "needupdate":
            state_label.text = "需要注意"
            action_button.text = "更新"
            action_button.visible = true

        "checkfailed":
            state_label.text = "检查失败"
            action_button.text = "重试"
            action_button.visible = true

        "uptodate":
            state_label.text = "启动游戏"
            action_button.text = "启动"
            action_button.visible = true

        "runningstate":
            state_label.text = "游戏运行中"
            action_button.text = "重新启动"
            action_button.visible = true

func _on_action_button_pressed() -> void:
    # 获取当前状态的弹窗配置
    var current_state = state_machine.current_node_state
    if current_state and current_state.has_method("get_popup_config"):
        var config = current_state.get_popup_config()
        PopupManager.show_popup(config)
```

---

## 1. 系统架构

### 1.1 节点层级

```
CardPanel (测试场景主节点)
├── GameCard (游戏卡面)
├── StateMachine (NodeStateMachine - 状态机管理器)
│   ├── NotInstalledState (未安装)
│   ├── CheckingUpdateState (检查更新中)
│   ├── UpdateAvailableState (有可选更新)
│   ├── UpdateRequiredState (需要强制更新)
│   ├── UpdateFailedState (检查失败)
│   ├── ReadyToLaunchState (准备启动)
│   └── RunningState (运行中)
├── StateLabel (Label - 状态文字显示)
└── ActionButton (Button - 交互操作)
```

### 1.2 信号流向

```
InstallTestScene (检查更新流程)
    │
    │ state_changed(state, error_message)
    ▼
CardPanel (汇聚信号)
    │
    │ transition_to(state_name)
    ▼
StateMachine (状态机管理器)
    │
    │ 切换到对应状态节点
    ▼
状态节点 (NotInstalledState 等)
    │
    │ get_popup_config()
    ▼
PopupManager (显示弹窗)
```

---

## 2. 7 种游戏状态

| 状态名 (全小写)         | 类名                   | 说明     | 弹窗标题    | 弹窗按钮|
| ---------------------- | -------------------- | ------ | ------- | --- |
| `notinstalled`         | NotInstalled         | 游戏未安装  | "游戏未安装" | [取消] [安装]|
| `checkingupdate`       | CheckingUpdate       | 检查更新中  | "检查更新"  | [等待]|
| `needupdate`           | NeedUpdate           | 有可选更新  | "需要注意"  | [更新] [取消]|
| `checkfailed`          | CheckFailed          | 检查失败   | "检查失败"  | [重试] [离线进入]|
| `uptodate`             | UpToDate             | 准备启动   | -       | 无弹窗 (直接启动)|
| `downloadstarted`      | DownloadStarted      | 开始下载   | -       | - |
| `installstarted`       | InstallStarted       | 开始安装   | -       | - |
| `installfinished`      | InstallFinished      | 安装完成   | -       | - |
| `runningstate`         | RunningState         | 游戏运行中  | "游戏运行中" | [取消] [重新启动]|

**注意：**
- `uptodate` 状态**不显示弹窗**，直接启动游戏（Phase 4 设计变更）
- `downloadstarted`、`installstarted`、`installfinished` 是中间过渡状态，不响应点击

---

## 3. NodeStateMachine 信号

### 3.1 核心信号

```gdscript
## 状态变化信号（最重要！）
signal state_changed(old_state: String, new_state: String)
```

**触发时机：**

| 时机             | 说明  |
| -------------- | --- |
| `_ready()` 初始化 | 进入 `|
| `transition_to(| 从当前状|

**示例：**

```gdscript
func _ready() -> void:
    state_machine.state_changed.connect(_on_state_changed)

func _on_state_changed(old_state: String, new_state: String) -> void:
    print("状态变化：", old_state, " → ", new_state)
```

---

## 4. NodeStateMachine 方法

### 4.1 常用方法

#### `transition_to(node_state_name: String) -> void`

切换到指定状态。

**参数：**

- `node_state_name`: 状态节点名称（小写，如 `"notinstalledstate"`）

**调用时机：**

- 检查更新完成后
- 用户手动切换状态（测试用）
- 游戏启动/关闭时

**示例：**

```gdscript
# 检查更新完成后切换到准备启动状态
func _on_check_update_finished() -> void:
    state_machine.transition_to("readytolaunchstate")

# 测试用按钮回调
func _on_test_button_pressed() -> void:
    state_machine.transition_to("updatefailedstate")
```

---

#### `get_current_state_name() -> String`

获取当前状态名称。

**返回值：** 当前状态名称（小写字符串）

**示例：**

```gdscript
func _on_action_button_pressed() -> void:
    var current = state_machine.get_current_state_name()
    print("当前状态：", current)
```

---

### 4.2 内部变量

| 变量                        | 类型           | 说明  |
| ------------------------- | ------------ | --- |
| `current_node_state`      | `NodeState`  | 当前状态|
| `current_node_state_name` | `String`     | 当前状态|
| `node_states`             | `Dictionary` | 所有注册|
| `initial_node_state`      | `NodeState`  | 初始状态|

---

## 5. 状态节点 API

### 5.1 NodeState 基类

**路径：** `script/state_machine/node_state.gd`

**所有状态节点的基类。**

#### 信号

```gdscript
signal transition
```

**用途：** 状态节点请求切换到其他状态。状态机在 `_ready()` 中自动连接此信号到 `transition_to` 方法。

**示例（在状态节点中使用）：**

```gdscript
func _on_next_transitions() -> void:
    # 满足条件时触发切换
    if some_condition:
        transition.emit("nextstatename")
```

---

#### 虚方法（子类可重写）

```gdscript
func _on_enter() -> void:
    # 进入状态时调用
    pass

func _on_exit() -> void:
    # 退出状态时调用
    pass

func _on_process(_delta: float) -> void:
    # 每帧调用（类似 _process）
    pass

func _on_physics_process(_delta: float) -> void:
    # 物理帧调用（类似 _physics_process）
    pass

func _on_next_transitions() -> void:
    # 每帧检查是否需要切换状态
    pass
```

---

### 5.2 状态节点模板

**创建新状态时的模板：**

```gdscript
extends NodeState
class_name YourStateName  # 必须：与文件名一致

func _on_enter() -> void:
    print("[状态] 进入：", name)

func _on_exit() -> void:
    print("[状态] 退出：", name)

func get_popup_config() -> Dictionary:
    return {
        "title": "弹窗标题",
        "content": "弹窗内容",
        "buttons": [
            {"text": "取消", "type": "secondary", "metadata": "cancel"},
            {"text": "确定", "type": "primary", "metadata": "confirm"}
        ]
    }

func on_card_confirmed() -> void:
    # 选中状态下点击卡面时的处理
    PopupManager.show_popup(get_popup_config())
```

---

### 5.3 7 个状态节点详解

#### NotInstalledState (未安装)

**路径：** `scenes/card/state/not_installed_state.gd`

**弹窗配置：**

```gdscript
{
    "title": "游戏未安装",
    "content": "该游戏尚未安装，是否开始安装？",
    "buttons": [
        {"text": "取消", "type": "secondary", "metadata": "cancel"},
        {"text": "安装", "type": "primary", "metadata": "install"}
    ]
}
```

---

#### CheckingUpdateState (检查更新中)

**路径：** `scenes/card/state/checking_update_state.gd`

**弹窗配置：**

```gdscript
{
    "title": "检查更新",
    "content": "正在检查游戏更新...",
    "buttons": []  # 无按钮，等待状态自动切换
}
```

**注意：** 此状态是临时状态，检查完成后应自动切换到其他状态。

---

#### UpdateAvailableState (有可选更新)

**路径：** `scenes/card/state/update_available_state.gd`

**弹窗配置：**

```gdscript
{
    "title": "有可用更新",
    "content": "发现新版本，是否更新？",
    "buttons": [
        {"text": "暂不更新", "type": "secondary", "metadata": "skip"},
        {"text": "更新", "type": "primary", "metadata": "update"}
    ]
}
```

---

#### UpdateRequiredState (需要强制更新)

**路径：** `scenes/card/state/update_required_state.gd`

**弹窗配置：**

```gdscript
{
    "title": "需要更新",
    "content": "游戏版本过旧，需要更新才能继续运行。",
    "buttons": [
        {"text": "更新", "type": "primary", "metadata": "update"}
    ]
}
```

**注意：** 只有一个按钮，用户必须更新。

---

#### UpdateFailedState (检查失败)

**路径：** `scenes/card/state/update_failed_state.gd`

**弹窗配置：**

```gdscript
{
    "title": "检查失败",
    "content": "无法连接到更新服务器，是否重试？",
    "buttons": [
        {"text": "重试", "type": "secondary", "metadata": "retry"},
        {"text": "取消", "type": "primary", "metadata": "cancel"}
    ]
}
```

---

#### ReadyToLaunchState (准备启动)

**路径：** `scenes/card/state/ready_to_launch_state.gd`

**弹窗配置：**

```gdscript
{
    "title": "启动游戏",
    "content": "确定要启动这款游戏吗？",
    "buttons": [
        {"text": "取消", "type": "secondary", "metadata": "cancel"},
        {"text": "启动", "type": "primary", "metadata": "launch"}
    ]
}
```

---

#### RunningState (运行中)

**路径：** `scenes/card/state/running_state.gd`

**弹窗配置：**

```gdscript
{
    "title": "游戏运行中",
    "content": "游戏正在运行中，是否重新启动？",
    "buttons": [
        {"text": "取消", "type": "secondary", "metadata": "cancel"},
        {"text": "重新启动", "type": "primary", "metadata": "restart"}
    ]
}
```

---

## 6. transition 信号详解

### 6.1 什么是 transition 信号？

`transition` 是 `NodeState` 基类中定义的信号，用于**状态节点主动请求切换到其他状态**。

```gdscript
# node_state.gd
signal transition
```

### 6.2 工作原理

```
状态节点内部
    │
    │ 满足切换条件
    │
    ▼
transition.emit("target_state_name")
    │
    │ 信号连接到状态机
    │ (在 NodeStateMachine._ready() 中自动连接)
    ▼
NodeStateMachine.transition_to("target_state_name")
    │
    │ 执行状态切换
    │ 1. 调用当前状态的 _on_exit()
    │ 2. 调用新状态的 _on_enter()
    │ 3. 更新 current_node_state
    │ 4. 发出 state_changed 信号
    ▼
状态切换完成
```

### 6.3 使用示例

**在状态节点中使用 transition 信号：**

```gdscript
extends NodeState
class_name CheckingUpdateState

func _on_enter() -> void:
    # 进入状态时开始检查更新
    check_update()

func check_update() -> void:
    # 异步检查更新
    var result = await VersionUtils.get_update_policy("ETN_Farm")

    # 根据结果切换到不同状态
    if result == null:
        transition.emit("updatefailedstate")
    elif result.force_full_package:
        transition.emit("updaterequiredstate")
    else:
        transition.emit("readytolaunchstate")
```

### 6.4 状态机自动连接

在 `NodeStateMachine._ready()` 中：

```gdscript
func _ready() -> void:
    for child in get_children():
        if child is NodeState:
            node_states[child.name.to_lower()] = child
            # 关键：将状态的 transition 信号连接到 transition_to 方法
            child.transition.connect(transition_to)
```

**这意味着：** 任何状态节点调用 `transition.emit("xxx")` 都会自动触发状态机切换。

---

## 7. 与 PopupManager 集成

### 7.1 弹窗显示流程

```
用户点击选中的卡面
    │
    ▼
GameCard.card_confirm 信号
    │
    ▼
CardPanel._on_card_confirm()
    │
    ▼
state_machine.current_node_state.on_card_confirmed()
    │
    ▼
状态节点.get_popup_config()
    │
    ▼
PopupManager.show_popup(config)
```

### 7.2 调用示例

```gdscript
# CardPanel.gd
func _on_game_card_card_confirm() -> void:
    var current_state = state_machine.current_node_state
    if current_state and current_state.has_method("on_card_confirmed"):
        current_state.on_card_confirmed()
```

---

## 8. 完整使用示例

### 8.1 CardPanel 完整脚本

```gdscript
extends Control
class_name CardPanel

@onready var state_machine: NodeStateMachine = $StateMachine
@onready var state_label: Label = $StateLabel
@onready var action_button: Button = $ActionButton
@onready var game_card: GameCard = $GameCard
@onready var install_test_scene: Node = $InstallTestScene

func _ready() -> void:
    # 连接状态机信号
    state_machine.state_changed.connect(_on_state_changed)

    # 连接按钮回调
    action_button.pressed.connect(_on_action_button_pressed)

    # 连接游戏卡面信号
    game_card.card_confirm.connect(_on_card_confirm)

    # 连接检查更新场景信号
    install_test_scene.state_changed.connect(_on_install_state_changed)

    # 初始化：进入检查更新状态
    state_machine.transition_to("checkingupdatestate")

func _on_state_changed(old_state: String, new_state: String) -> void:
    print("[CardPanel] 状态变化：", old_state, " → ", new_state)

    match new_state:
        "notinstalledstate":
            _update_ui("游戏未安装", "安装", true)

        "checkingupdatestate":
            _update_ui("正在检查更新...", "", false)

        "updateavailablestate":
            _update_ui("发现新版本", "更新", true)

        "updaterequiredstate":
            _update_ui("需要更新", "立即更新", true)

        "updatefailedstate":
            _update_ui("检查失败", "重试", true)

        "readytolaunchstate":
            _update_ui("准备启动", "启动游戏", true)

        "runningstate":
            _update_ui("游戏运行中", "重新启动", true)

func _update_ui(label_text: String, button_text: String, show_button: bool) -> void:
    state_label.text = label_text
    action_button.text = button_text
    action_button.visible = show_button

func _on_action_button_pressed() -> void:
    # 触发当前状态的弹窗
    var current_state = state_machine.current_node_state
    if current_state and current_state.has_method("on_card_confirmed"):
        current_state.on_card_confirmed()

func _on_card_confirm() -> void:
    # 游戏卡面确认时的处理（与 action_button 相同）
    _on_action_button_pressed()

func _on_install_state_changed(state: String, error_message: String) -> void:
    # 根据检查更新结果切换状态
    var state_map = {
        "not_installed": "notinstalledstate",
        "checking_update": "checkingupdatestate",
        "update_available": "updateavailablestate",
        "update_required": "updaterequiredstate",
        "update_failed": "updatefailedstate",
        "ready_to_launch": "readytolaunchstate",
        "running": "runningstate"
    }

    if state_map.has(state):
        state_machine.transition_to(state_map[state])
```

---

## 9. 常见问题解答

### Q1: 如何添加新状态？

**答：** 

1. 创建新脚本继承 `NodeState`
2. 实现 `get_popup_config()` 和 `on_card_confirmed()`
3. 在场景中将新节点添加为 `StateMachine` 的子节点
4. 在状态机的 Inspector 中设置 `initial_node_state`（可选）

---

### Q2: transition 和 transition_to 有什么区别？

**答：**

- `transition` 是 **信号**（Signal），在状态节点中发出
- `transition_to` 是 **方法**（Method），在状态机中调用

状态节点通过 `transition.emit()` 请求切换，状态机通过 `transition_to()` 执行切换。

---

### Q3: 如何在状态切换时播放动画？

**答：** 在 `_on_enter()` 或 `_on_exit()` 中播放：

```gdscript
func _on_enter() -> void:
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.3)
```

---

### Q4: 状态机可以嵌套吗？

**答：** 可以。状态机本身是 `Node`，可以作为其他状态机的子状态。

---

### Q5: 如何获取状态机的所有可用状态？

**答：** 访问 `node_states` 字典：

```gdscript
for state_name in state_machine.node_states:
    print("可用状态：", state_name)
```

---

## 10. 文件列表

| 文件                          | 路径                      | 说明  |
| --------------------------- | ----------------------- | --- |
| `node_state_machine.gd`     | `script/state_machine/` | **状态|
| `node_state.gd`             | `script/state_machine/` | **状态|
| `not_installed_state.gd`    | `scenes/card/state/`    | 未安装状|
| `checking_update_state.gd`  | `scenes/card/state/`    | 检查更新|
| `update_available_state.gd` | `scenes/card/state/`    | 有可选更|
| `update_required_state.gd`  | `scenes/card/state/`    | 需要强制|
| `update_failed_state.gd`    | `scenes/card/state/`    | 检查失败|
| `ready_to_launch_state.gd`  | `scenes/card/state/`    | 准备启动|
| `running_state.gd`          | `scenes/card/state/`    | 运行中状|

---

## 11. 版本历史

| 版本  | 日期  | 变更  |
| --- | --- | --- |
| 1.0 | 2026| 初始版本|

---

## 附录：状态切换流程图

```
┌─────────────────────────────────────────────────────────────┐
│                    游戏启动流程                              │
└─────────────────────────────────────────────────────────────┘

开始
  │
  ▼
[CheckingUpdateState]
  │ 检查游戏是否安装
  ├─ 未安装 ──────► [NotInstalledState]
  │                  │ 用户点击安装
  │                  ▼
  │              下载/安装流程
  │                  │
  │                  ▼
  └─────────────► [ReadyToLaunchState]
                   │ 用户点击启动
                   ▼
               [RunningState]
                   │ 游戏关闭
                   ▼
               [ReadyToLaunchState]

┌─────────────────────────────────────────────────────────────┐
│                    错误处理流程                              │
└─────────────────────────────────────────────────────────────┘

[CheckingUpdateState]
  │ 网络错误/JSON 解析失败
  ▼
[UpdateFailedState]
  │ 用户点击重试
  ▼
[CheckingUpdateState] (循环)
```
