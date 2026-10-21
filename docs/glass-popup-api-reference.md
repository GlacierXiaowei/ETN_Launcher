# 全局弹窗系统 API 参考

> Glass Popup System - 基于液态玻璃效果的全局弹窗系统

**实用提示：**

- 90% 的情况下直接用 `show_confirm()` 和 `show_alert()` 快捷方法即可
- 按钮会根据文字自动调整尺寸，通常不需要设置 `min_width/min_height`  
- 目前仅支持单弹窗（后开窗自动关闭旧弹窗）

---

## 1. PopupManager 信号

```gdscript
signal popup_button_pressed(metadata: String)  # 按钮被按下
signal popup_opened                            # 弹窗打开完成
signal popup_closed                            # 弹窗关闭完成
```

---

## 2. PopupManager 方法

### 2.1 show_popup(config: Dictionary) -> void

显示弹窗。`config` 可以完全为空（使用默认值）。

**`config` 可选字段：**

| 字段             | 类型     | 默认值        | 说明  |
| -------------- | ------ | ---------- | --- |
| `size`         | String | "medium"   | "med|
| `title`        | String | ""         | 标题  |
| `content`      | String | ""         | 内容  |
| `content_type` | String | "richtext" | "lab|
| `buttons`      | Array  | []         | 按钮数组|
| `clear_on_new` | bool   | true       | 打开新弹|

**按钮配置字段：**

- `text`(String): 按钮文字
- `type`(String): "primary" / "secondary" / "third"  
- `metadata`(String): 回调标识
- `stay_open`(bool, 可选): 点击后是否保持弹窗打开
- `disabled`(bool, 可选): 是否禁用按钮
- `min_width`/`min_height`(float, 可选): **通常不需设置，按钮会根据文本自动调整尺寸**

**说明：** Dictionary 填充顺序不影响功能，按键值对填充即可。

**示例：**

```gdscript
PopupManager.show_popup({
  "title": "确认操作", 
  "content": "确定要继续吗？",
  "buttons": [
    {"text": "取消", "type": "secondary", "metadata": "cancel"},
    {"text": "确定", "type": "primary", "metadata": "confirm"}
    # min_width/min_height 通常不需要设置，按钮会根据"确定"/"取消"等文字自动调整到合适的宽度
  ]
})
```

---

### 2.2 close_popup() -> void

关闭当前弹窗（如有）。

**示例：**

```gdscript
# 手动关闭弹窗
PopupManager.close_popup()

# 带检查的关闭
func _on_cancel_button_pressed() -> void:
    if PopupManager.has_open_popup():
        PopupManager.close_popup()
```

---

### 2.3 update_popup(config: Dictionary) -> bool

更新当前弹窗内容（不关闭）。

**`config` 可选字段：** `title`, `content`, `content_type`, `buttons`, `transition_animation`(bool)

**返回值：** `true`=成功，`false`=无弹窗

**示例：**

```gdscript
# 更新标题和内容（带淡入淡出动画）
PopupManager.update_popup({
    "title": "更新后的标题",
    "content": "内容已更新！",
    "transition_animation": true
})

# 更新按钮
PopupManager.update_popup({
    "buttons": [
        {"text": "重新开始", "type": "primary", "metadata": "restart"},
        {"text": "退出", "type": "secondary", "metadata": "exit"}
    ]
})

# 检查更新是否成功
var success = PopupManager.update_popup({"content": "新内容"})
if not success:
    print("当前没有弹窗，无法更新")
```

---

### 2.4 has_open_popup() -> bool

是否有弹窗显示。返回 `true`/`false`。

> **注：** 当前为单弹窗模式，同一时间最多只有一个弹窗。

**示例：**

```gdscript
# 避免重复弹窗
func _on_show_popup_pressed() -> void:
    if PopupManager.has_open_popup():
        print("已有弹窗显示中")
        return
    PopupManager.show_popup({"title": "新弹窗"})

# 条件判断
func _check_popup_status() -> void:
    if PopupManager.has_open_popup():
        print("弹窗正在显示")
    else:
        print("没有弹窗")
```

---

### 2.5 close_and_show_new(config: Dictionary) -> void

关闭当前弹窗，等待关闭动画完成后打开新弹窗。

> **注：** 单弹窗模式下，推荐使用此方法安全替换弹窗内容。

**示例：**

```gdscript
# 安全替换：关闭旧弹窗，显示新弹窗
func _show_next_popup() -> void:
    PopupManager.close_and_show_new({
        "title": "第二步",
        "content": "这是新的弹窗内容",
        "buttons": [
            {"text": "完成", "type": "primary", "metadata": "done"}
        ]
    })

# 从确认弹窗切换到结果弹窗
func _on_confirm_response(metadata: String) -> void:
    if metadata == "confirm":
        PopupManager.close_and_show_new({
            "title": "操作完成",
            "content": "您的操作已成功执行！",
            "buttons": [
                {"text": "确定", "type": "primary", "metadata": "ok"}
            ]
        })
```

---

### 2.6 show_confirm(title, content, on_ok, on_cancel?) -> void

快捷方法：显示确认对话框（确定/取消两个按钮）。

**参数：**

- `title`(String): 标题
- `content`(String): 内容
- `on_ok`(Callable): 点击确定的回调
- `on_cancel`(Callable, 可选): 点击取消的回调

**回调语义：** 只触发一次（自动断开连接，不会累积）

**示例：**

```gdscript
PopupManager.show_confirm(
  "删除存档",
  "确定要删除吗？",
  func(): _delete_save(),
  func(): print("用户取消了")
)
```

---

### 2.7 show_alert(title, content, on_ok?) -> void

快捷方法：显示提示对话框（一个"确定"按钮）。

**参数：**

- `title`(String): 标题
- `content`(String): 内容
- `on_ok`(Callable, 可选): 点击确定的回调

**回调语义：** 只触发一次（自动断开连接，不会累积）

**示例：**

```gdscript
# 最简单用法：只显示提示
PopupManager.show_alert("提示", "操作已完成。")

# 带回调的用法
PopupManager.show_alert(
    "下载完成",
    "文件已保存到下载目录。",
    func(): print("用户已知晓")
)

# 在回调中执行后续操作
func _on_export_finished() -> void:
    PopupManager.show_alert(
        "导出成功",
        "游戏已成功导出！",
        func(): _navigate_to_export_folder()
    )
```

---

### 2.8 show_loading(title?, label_text?, use_fade?) -> void

**Phase5 新增**：让弹窗进入"强制等待"状态（按钮不可点击）。

**参数：**

- `title`(String, 默认"请稍候"): 标题（无弹窗时创建新弹窗使用）
- `label_text`(String, 默认"请稍候..."): label 文案（**空字符串表示不修改原有 label**）
- `use_fade`(bool, 默认 true): 是否使用淡入淡出动画

**行为语义：**

- **当前有弹窗：** 保存快照，替换按钮为一个 disabled 的"请稍候..."按钮；**不修改 richtext 内容**；若 `label_text` 为空则不修改 label
- **当前无弹窗：** 自动创建一个等待弹窗（`content_type="richtext"`, `content=""`）

**示例：**

```gdscript
# 不修改原有 richtext 和 label
PopupManager.show_loading("", "", true)

# 自定义标题和 label
PopupManager.show_loading("加载中", "正在处理...", true)
```

---

### 2.9 hide_loading(restore_config?, use_fade?) -> void

**Phase5 新增**：退出 loading/等待态，恢复可交互。

**参数：**

- `restore_config`(Dictionary, 默认{}): 恢复配置（**为空则恢复快照**）
- `use_fade`(bool, 默认 true): 是否使用淡入淡出动画

**行为语义：**

- **`restore_config` 非空：** 用该配置更新弹窗（常用于"操作完成"进入下一步）
- **`restore_config` 为空：** 恢复 `show_loading()` 前保存的快照

**示例：**

```gdscript
# 恢复快照
PopupManager.hide_loading()

# 恢复到指定状态
PopupManager.hide_loading({
  "title": "完成",
  "content_type": "label",
  "content": "现在可以继续操作了",
  "buttons": [
    {"text": "继续", "type": "primary", "metadata": "continue"}
  ],
  "transition_animation": true
}, true)
```

---

## 3. GlobalPopup 可调参数

在 `res://component/GlassComponent/global_popup.gd` 中：

| 常量                         | 默认值  | 说明  |
| -------------------------- | ---- | --- |
| `DEFAULT_CORNER_RADIUS_PX` | 24.0 | 圆角半径|
| `DIM_ALPHA`                | 0.5  | 背景压暗|
| `CLOSE_BLUR_PEAK`          | 4.0  | 关闭模糊|
| `CLOSE_T_BLUR_IN`          | 0.15 | 模糊上升|
| `CLOSE_T_MAIN`             | 0.4  | 主关闭时|

---

## 4. 动画时长参考

| 动画   | 时长  |
| ---- | --- |
| 打开动画 | ~0.3|
| 标准关闭 | ~0.1|
| 模糊关闭 | ~0.5|
| 内容切换（| ~0.3|

---

## 5. 按钮布局规则

- 居中对齐（`ALIGNMENT_CENTER`）
- 按钮间距：36px
- 自动排序：primary → secondary → third
- 自动根据文本长度调整宽度（长文本时额外增加 4px 余量）

---

## 6. 完整使用示例

### 6.1 PopupManager 是什么？

**PopupManager 是一个 AutoLoad 单例**（类似全局静态类），你可以在**任何节点、任何脚本**中直接调用它：

```gdscript
# 任何脚本中都可以直接使用
PopupManager.show_popup({...})
PopupManager.show_confirm(...)
```

**不需要** `@onready` 或 `get_node()`，它自动全局可用。

### 6.2 方式 1：快捷方法（推荐，90% 场景够用）

**场景：** 游戏卡面点击 → 弹出确认框 → 根据选择执行操作

```gdscript
extends Control
class_name GameCard

# ========== 使用快捷方法 ==========

func _on_start_button_pressed() -> void:
    # 直接调用快捷方法
    PopupManager.show_confirm(
        "启动游戏",
        "确定要启动这款游戏吗？",
        _on_game_start_confirmed,    # 点击"确定"时的回调
        _on_game_start_cancelled     # 点击"取消"时的回调（可选）
    )

# 回调函数：用户点击了"确定"
func _on_game_start_confirmed() -> void:
    print("用户确认启动游戏")
    _launch_game()

# 回调函数：用户点击了"取消"
func _on_game_start_cancelled() -> void:
    print("用户取消了启动")

func _launch_game() -> void:
    # 实际启动游戏的逻辑
    OS.create_process("path/to/game.exe", [])
```

### 6.3 方式 2：metadata 回调系统（高级用法）

**场景：** 需要统一的回调处理器，集中管理所有弹窗响应

```gdscript
extends Control

# ========== 使用 metadata 回调系统 ==========

func _on_delete_save_button_pressed() -> void:
    # 使用完整配置 + metadata 回调
    PopupManager.show_popup({
        "title": "删除存档",
        "content": "确定要删除这个存档吗？此操作不可恢复。",
        "buttons": [
            {"text": "取消", "type": "secondary", "metadata": "cancel"},
            {"text": "删除", "type": "primary", "metadata": "delete"}
        ]
    })

    # ⚠️ 连接信号到回调处理器
    # 推荐：在 _ready() 中只连接一次，避免重复连接导致累积触发
    PopupManager.popup_button_pressed.connect(_on_delete_save_response)

# 统一的回调处理器
func _on_delete_save_response(metadata: String) -> void:
    match metadata:
        "delete":
            print("用户确认删除")
            _perform_delete()
        "cancel":
            print("用户取消删除")

func _perform_delete() -> void:
    # 执行删除操作
    pass
```

---

#### 6.3.1 回调连接与断开指南（重要！）

**Q1: 窗口销毁后，新窗口需要重新连接回调吗？**

**答：** 需要分情况讨论：

| 场景                                     | 是否需要重新连接 | 说明  |
| -------------------------------------- | -------- | --- |
| **快捷方法** (`show_confirm`/`show_alert`) | ❌ 不需要    | 内部已自|
| **metadata 方式 + `_ready()` 全局连接**      | ❌ 不需要    | 信号处理|
| **metadata 方式 + 每次调用时 connect**        | ⚠️ 需要手动 d| 否则会累|

**提示**： 这里的disconnect是因为我们的信号是连接的Popmanager的信号，不是按钮本身的信号，同时disconnect的语法要求signal.disconnect(回调函数名称) 所以作为PopManager没办法自动销毁（或者不方便自动销毁）。如果不进行销毁，那么Popmanager的信号会持续链接到多个回调函数，这也许是大多数人不愿意看到的。

**CONNECT_ONE_SHOT**: <mark>如果回调函数只执行一次，可以使用这样的语法，回调一次就会销毁信号连接： </mark>

    popup.button_pressed.connect(回调函数（）, Object.CONNECT_ONE_SHOT)

**Q2: 弹窗被销毁后，我的回调函数会怎样？**

**答：** 回调函数在**你的节点脚本上执行**，与弹窗实例无关。弹窗销毁不影响回调函数存在。

```gdscript
# 在你的节点脚本中
func _ready() -> void:
    # 连接到你的回调函数（在你的节点上）
    PopupManager.popup_button_pressed.connect(_on_response)

func _on_response(metadata: String) -> void:
    # 这个函数在你的节点上执行，弹窗销毁了也不影响
    print("收到回调：", metadata)
```

**Q3: 只更新内容（不关闭弹窗），重置按钮后需要重新连接吗？**

**答：** 不需要！`popup_button_pressed` 信号是 **PopupManager 单例的信号**，不是弹窗实例的信号。只要你的节点还活着，连接就有效。

也就是说，我们收到的信号无非就只有metadata,所以我们要根据元数据的类型判断玩家按下了哪一个按钮哦。

```gdscript
func _ready() -> void:
    # 连接一次即可
    PopupManager.popup_button_pressed.connect(_on_response)

func _update_popup_content() -> void:
    # 更新按钮配置（metadata 可以不同）
    PopupManager.update_popup({
        "buttons": [
            {"text": "新按钮", "metadata": "new_action"}  # metadata 变了也没关系
        ]
    })
    # ✅ 不需要重新 connect，_on_response 仍然会收到回调

func _on_response(metadata: String) -> void:
    match metadata:
        "new_action":
            print("新按钮被点击")
```

**Q4: 如何正确管理 metadata 方式的连接？**

**最佳实践：在 `_ready()` 中全局连接一次**

```gdscript
extends Control

func _ready() -> void:
    # ✅ 推荐：只连接一次，全局处理
    PopupManager.popup_button_pressed.connect(_on_global_response)

func _on_button_a_pressed() -> void:
    PopupManager.show_popup({...})  # 不需要 connect

func _on_button_b_pressed() -> void:
    PopupManager.show_popup({...})  # 不需要 connect

func _on_global_response(metadata: String) -> void:
    # 统一处理所有弹窗回调
    match metadata:
        "action_a": _do_a()
        "action_b": _do_b()
```

---

#### 6.3.2 Lambda 回调语法解释

**你可能看到这样的代码：**

```gdscript
# 最简单用法：只显示提示
PopupManager.show_alert("提示", "操作已完成。")

# 带回调的用法
PopupManager.show_alert(
    "下载完成",
    "文件已保存到下载目录。",
    func(): print("用户已知晓")  # ← 这是啥？
)

# 在回调中执行后续操作
func _on_export_finished() -> void:
    PopupManager.show_alert(
        "导出成功",
        "游戏已成功导出！",
        func(): _navigate_to_export_folder()  # ← 这又是啥？
    )
```

**`func():` 是什么语法？**

这是 **GDScript 的 Lambda/匿名函数语法**，也叫 **Callable 字面量**。

```gdscript
# 传统方式：先定义函数，再传递引用
func _on_ok_clicked() -> void:
    print("用户点了确定")

PopupManager.show_alert("提示", "内容", _on_ok_clicked)

# Lambda 方式：直接内联定义（更简洁）
PopupManager.show_alert("提示", "内容", func(): print("用户点了确定"))
```

**语法格式：**

```gdscript
func 参数列表 -> 返回类型:
    函数体
```

**示例：**

```gdscript
# 无参数，无返回值
func(): print("Hello")

# 带参数，无返回值
func(name): print("Hello, ", name)

# 带参数，有返回值
func(a, b): return a + b
```

**弹窗的回调函数是谁？**

以这个为例：

```gdscript
PopupManager.show_alert(
    "下载完成",
    "文件已保存到下载目录。",
    func(): print("用户已知晓")
)
```

**执行流程：**

```
1. 用户点击弹窗"确定"按钮
        ↓
2. PopupManager 触发 popup_button_pressed 信号
        ↓
3. show_alert 内部注册的 one-shot 处理器被调用
        ↓
4. 处理器执行你传入的 Lambda: func(): print("用户已知晓")
        ↓
5. 打印 "用户已知晓"
        ↓
6. 自动 disconnect（one-shot，只触发一次）
```

**快捷方法的回调已经自动处理为 one-shot，不需要手动 disconnect！**

### 6.4 方式 3：Loading 锁使用示例

**场景：** 异步操作 → 显示等待状态 → 操作完成恢复

```gdscript
extends Control

func _on_export_game_button_pressed() -> void:
    # 先显示一个普通弹窗
    PopupManager.show_popup({
        "title": "导出游戏",
        "content": "正在导出游戏文件，请稍候...",
        "content_type": "label",
        "buttons": [
            {"text": "导出中", "type": "secondary", "disabled": true}
        ]
    })

    # 进入 loading 状态（按钮变灰不可点）
    PopupManager.show_loading("", "", true)

    # 执行异步操作
    var result = await _export_game_async()

    # 操作完成，恢复弹窗或更新为新状态
    if result:
        # 用新配置替换
        PopupManager.hide_loading({
            "title": "导出完成",
            "content": "游戏已成功导出到目标目录。",
            "content_type": "label",
            "buttons": [
                {"text": "确定", "type": "primary", "metadata": "ok"}
            ]
        }, true)
    else:
        # 导出失败，显示错误
        PopupManager.hide_loading({
            "title": "导出失败",
            "content": "导出过程中发生错误，请重试。",
            "buttons": [
                {"text": "重试", "type": "primary", "metadata": "retry"},
                {"text": "取消", "type": "secondary", "metadata": "cancel"}
            ]
        }, true)

func _export_game_async() -> bool:
    await get_tree().create_timer(2.0).timeout  # 模拟耗时操作
    return true
```

### 6.5 方式 4：弹窗内容动态更新（不关闭弹窗）

**特性**： 可保存多个状态，并在多个状态之间切换。建议搭配状态机处理

**场景：** 多步骤教程/向导流程

```gdscript
extends Control

var _current_step: int = 1

func _on_tutorial_button_pressed() -> void:
    _current_step = 1
    _show_tutorial_step()

func _show_tutorial_step() -> void:
    var step_config: Dictionary

    match _current_step:
        1:
            step_config = {
                "title": "步骤 1/3",
                "content": "这是第一步教程内容...",
                "buttons": [
                    {"text": "下一步", "type": "primary", "metadata": "next", "stay_open": true}
                ]
            }
        2:
            step_config = {
                "title": "步骤 2/3",
                "content": "这是第二步教程内容...",
                "buttons": [
                    {"text": "上一步", "type": "secondary", "metadata": "prev", "stay_open": true},
                    {"text": "下一步", "type": "primary", "metadata": "next", "stay_open": true}
                ]
            }
        3:
            step_config = {
                "title": "完成",
                "content": "教程已完成！",
                "buttons": [
                    {"text": "关闭", "type": "primary", "metadata": "close"}
                ]
            }

    if _current_step == 1:
        # 第一次显示弹窗
        PopupManager.show_popup(step_config)
        PopupManager.popup_button_pressed.connect(_on_tutorial_response)
    else:
        # 更新现有弹窗内容（带淡入淡出动画）
        step_config["transition_animation"] = true
        PopupManager.update_popup(step_config)

func _on_tutorial_response(metadata: String) -> void:
    match metadata:
        "next":
            _current_step += 1
            _show_tutorial_step()
        "prev":
            _current_step -= 1
            _show_tutorial_step()
        "close":
            PopupManager.close_popup()
```

### 6.6 实用工具函数

```gdscript
# 检查是否有弹窗正在显示（避免重复弹出）
func _try_show_warning() -> void:
    if PopupManager.has_open_popup():
        print("已有弹窗显示中，跳过本次警告")
        return

    PopupManager.show_alert("警告", "这是一条警告信息。")
```

---

## 7. 常见问题解答

### Q1: 我需要在 `_ready()` 中连接信号吗？

- **快捷方法** (`show_confirm`/`show_alert`)：不需要，内部已自动 one-shot 处理
- **metadata 方式** (`show_popup` + `popup_button_pressed.connect`)：建议在 `_ready()` 中连接一次，全局处理

### Q2: 回调会在哪个节点上执行？

回调在你**连接信号的那个节点的脚本上**执行。例如：

```gdscript
# 在 GameCard 节点上连接
PopupManager.popup_button_pressed.connect(_on_response)  # _on_response 在 GameCard.gd 中执行
```

### Q3: 多个弹窗同时弹出会怎样？

当前为**单弹窗模式**，<mark>新弹窗会自动关闭旧弹窗</mark>。

使用 `PopupManager.close_and_show_new()` 可确保动画完整。

### Q4: 如何防止用户疯狂点击导致弹窗乱跳？

使用 `PopupManager.has_open_popup()` 检查：

```gdscript
func _on_button_pressed() -> void:
    if PopupManager.has_open_popup():
        return  # 忽略重复点击
    PopupManager.show_alert(...)
```

### Q5: 弹窗销毁/更新后，需要重新连接回调吗？

**分情况讨论：**

| 场景                                     | 是否需要重新连接 | 说明  |
| -------------------------------------- | -------- | --- |
| **快捷方法** (`show_confirm`/`show_alert`) | ❌ 不需要    | 内部已自|
| **metadata 方式 + `_ready()` 全局连接**      | ❌ 不需要    | 信号处理|
| **metadata 方式 + 每次调用时 connect**        | ⚠️ 需要手动 d| 否则会累|

**或者使用 CONNECT_ONE_SHOT属性**：详见 ↓

**详细说明请参见：** [6.3.1 回调连接与断开指南](#631-回调连接与断开指南重要)

---
