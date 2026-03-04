# InstallComponent API 参考

> 游戏更新与安装管理系统 - 支持全量更新、补丁更新、版本检查

**版本：** 1.1  
**最后更新：** 2026-03-04

---

## 🚀 快速开始

### 30 秒上手

**InstallComponent** 是一个封装完整的更新管理组件，外部只需**监听 2 个信号**、**调用 3 个方法**即可。

---

### 第一步：获取组件引用

```gdscript
# 在你的场景脚本中
@onready var install_component: InstallComponent = $InstallComponent
```

---

### 第二步：连接信号（只需 2 个）

```gdscript
func _ready() -> void:
    # 核心信号：更新状态变化
    install_component.update_state_changed.connect(_on_update_state)
    
    # 错误信号：运行时错误（可选）
    install_component.update_error_occurred.connect(_on_update_error)
```

---

### 第三步：监听状态变化

```gdscript
func _on_update_state(state: InstallSignalHub.InstallState) -> void:
    match state:
        # 游戏未安装
        InstallSignalHub.InstallState.NOT_INSTALLED:
            print("游戏未安装")
            _show_install_ui()
        
        # 正在检查更新
        InstallSignalHub.InstallState.CHECKING_UPDATE:
            print("正在检查更新...")
            _show_loading()
        
        # 已是最新版
        InstallSignalHub.InstallState.UP_TO_DATE:
            print("已是最新版")
            _show_launch_button()
        
        # 需要更新（全量或补丁）
        InstallSignalHub.InstallState.NEED_UPDATE:
            print("发现新版本")
            _show_update_button()
        
        # 检查更新失败
        InstallSignalHub.InstallState.CHECK_FAILED:
            print("检查更新失败")
            var error_msg = install_component._server.err_notes
            _show_error_dialog(error_msg)
        
        # 下载/安装流程
        InstallSignalHub.InstallState.DOWNLOAD_STARTED:
            _show_loading("下载中...")
        InstallSignalHub.InstallState.DOWNLOAD_FINISHED:
            _hide_loading()
        InstallSignalHub.InstallState.INSTALL_STARTED:
            _show_loading("安装中...")
        InstallSignalHub.InstallState.INSTALL_FINISHED:
            _show_launch_button()
```

---

### 第四步：调用方法

| 方法 | 说明 | 调用时机 |
|------|------|---------|
| `re_ready()` | 重新检查更新 | 用户点击"刷新"按钮 |
| `reset_version()` | 重置版本信息 | 强制重新检查版本 |
| `check_game_installation()` | 检查游戏是否已安装 | 初始化时（`_ready` 已自动调用） |

```gdscript
# 用户点击"刷新"按钮
func _on_refresh_pressed() -> void:
    install_component.re_ready()

# 用户点击"下载"按钮
func _on_download_pressed() -> void:
    install_component._on_下载_pressed()

# 用户点击"安装"按钮
func _on_install_pressed() -> void:
    install_component._on_开始安装_pressed()
```

---

### 完整示例

```gdscript
extends Control
class_name GameLauncher

@onready var install_component: InstallComponent = $InstallComponent
@onready var status_label: Label = $StatusLabel
@onready var download_button: Button = $DownloadButton
@onready var launch_button: Button = $LaunchButton

func _ready() -> void:
    install_component.update_state_changed.connect(_on_update_state)
    install_component.update_error_occurred.connect(_on_update_error)

func _on_update_state(state: InstallSignalHub.InstallState) -> void:
    match state:
        InstallSignalHub.InstallState.NOT_INSTALLED:
            status_label.text = "游戏未安装"
            download_button.visible = true
            launch_button.visible = false
        
        InstallSignalHub.InstallState.CHECKING_UPDATE:
            status_label.text = "正在检查更新..."
        
        InstallSignalHub.InstallState.UP_TO_DATE:
            status_label.text = "已是最新版"
            download_button.visible = false
            launch_button.visible = true
        
        InstallSignalHub.InstallState.NEED_UPDATE:
            status_label.text = "发现新版本"
            download_button.visible = true
            launch_button.visible = false
        
        InstallSignalHub.InstallState.CHECK_FAILED:
            var error = install_component._server.err_notes
            status_label.text = "检查失败：" + error
        
        InstallSignalHub.InstallState.DOWNLOAD_FINISHED:
            status_label.text = "下载完成，请点击安装"
        
        InstallSignalHub.InstallState.INSTALL_FINISHED:
            status_label.text = "安装完成"
            launch_button.visible = true

func _on_update_error(error_message: String) -> void:
    printerr("更新错误：", error_message)

func _on_refresh_pressed() -> void:
    install_component.re_ready()
```

---

## 1. 系统架构

### 1.1 节点层级

```
InstallComponent (主组件 - 你只需要和它交互)
├── InstallSignalHub (信号汇聚中心 - 内部管理)
├── UpdateFlow (更新流程控制器 - 内部管理)
├── UpdateUiManager (UI 管理器 - 内部管理)
└── UpdateChooseFile (文件选择器 - 内部管理)

动态创建的节点（自动管理，无需关心）:
├── PatchInstall (补丁安装器)
└── FullInstall (全量安装器)
```

### 1.2 信号流向

```
外部场景
    │
    │ 只需监听这 2 个信号
    ▼
InstallComponent.update_state_changed
InstallComponent.update_error_occurred
    │
    │ 转发
    ▼
InstallSignalHub (汇聚所有内部信号)
    │
    ▼
动态创建的 PatchInstall / FullInstall / UpdateChecker
```

---

## 2. InstallState 枚举

所有状态定义在 `InstallSignalHub.InstallState`：

| 状态 | 值 | 说明 | 何时触发 | UI 建议 |
|------|-----|------|---------|---------|
| `NOT_INSTALLED` | 0 | 游戏未安装 | `check_game_installation()` 返回 false | 显示"安装游戏"按钮 |
| `CHECKING_UPDATE` | 1 | 正在检查更新 | `init_check_version()` 开始 | 显示加载动画 |
| `NEED_UPDATE` | 2 | 需要更新 | 版本比较结果为 FULL/NORMAL | 显示"更新"按钮 |
| `CHECK_FAILED` | 3 | 检查失败 | 网络错误/JSON 解析失败/未知结果 | 显示错误信息 + "重试"按钮 |
| `UP_TO_DATE` | 4 | 已是最新版 | 版本比较结果为 UP_TO_DATE | 显示"启动游戏"按钮 |
| `DOWNLOAD_STARTED` | 5 | 开始下载 | 用户点击下载按钮 | 显示下载进度 |
| `DOWNLOAD_FINISHED` | 6 | 下载完成 | 所有文件下载成功 | 显示"安装"按钮 |
| `INSTALL_STARTED` | 7 | 开始安装 | 用户点击安装按钮 | 显示安装进度 |
| `INSTALL_FINISHED` | 8 | 安装完成 | 所有文件安装成功 | 显示"启动游戏"按钮 |

---

## 3. InstallComponent 信号

### 3.1 核心信号（必须监听）

```gdscript
## 更新状态变化（最重要！所有状态变化都通过它）
signal update_state_changed(state: InstallSignalHub.InstallState)
```

**触发时机：**

| 时机 | 状态 | 说明 |
|------|------|------|
| `_ready()` 自动检查 | `NOT_INSTALLED` / `CHECKING_UPDATE` / `UP_TO_DATE` / `NEED_UPDATE` | 初始化时自动触发 |
| `re_ready()` 调用 | 同上 | 用户手动刷新 |
| 下载开始 | `DOWNLOAD_STARTED` | 调用 `_on_下载_pressed()` |
| 下载完成 | `DOWNLOAD_FINISHED` | 所有文件下载成功 |
| 安装开始 | `INSTALL_STARTED` | 调用 `_on_开始安装_pressed()` |
| 安装完成 | `INSTALL_FINISHED` | 所有文件安装成功 |
| 检查失败 | `CHECK_FAILED` | 网络错误/未知结果 |

---

### 3.2 错误信号（可选监听）

```gdscript
## 运行时错误（HTTP 请求失败、文件操作失败等）
signal update_error_occurred(error_message: String)
```

**注意：** `CHECK_FAILED` 状态**不通过**此信号发出，而是通过 `update_state_changed` 发出。

**此信号触发的场景：**
- 下载文件时 HTTP 错误
- 安装文件时文件操作失败
- 解压 zip 文件失败

---

## 4. InstallComponent 方法

### 4.1 常用方法

#### `re_ready() -> void`

重新执行完整的检查流程。

**调用时机：**
- 用户点击"刷新"按钮
- 网络恢复后重试

**示例：**
```gdscript
func _on_refresh_button_pressed() -> void:
    install_component.re_ready()
```

---

#### `reset_version() -> bool`

删除 version.json，重置版本信息。

**返回值：** `true`=成功，`false`=失败

**调用时机：**
- 版本文件损坏
- 强制重新检查版本

**示例：**
```gdscript
func _on_reset_version_pressed() -> void:
    if install_component.reset_version():
        print("版本已重置")
        install_component.re_ready()
```

---

#### `check_game_installation() -> bool`

检查游戏是否已安装。

**返回值：** `true`=已安装，`false`=未安装

**注意：** `_ready()` 中已自动调用，无需手动调用。

---

### 4.2 内部变量（可访问）

| 变量 | 类型 | 说明 |
|------|------|------|
| `_server` | `UpdatePolicy` | 服务器策略（包含 `err_notes` 错误信息） |
| `_local` | `VersionInfo` | 本地版本信息 |
| `is_installed` | `bool` | 游戏是否已安装 |
| `is_up_to_data` | `bool` | 版本检查缓存（避免重复检查） |

**获取错误信息示例：**
```gdscript
func _on_update_state(state: InstallSignalHub.InstallState) -> void:
    if state == InstallSignalHub.InstallState.CHECK_FAILED:
        var error_msg = install_component._server.err_notes
        print("错误详情：", error_msg)
```

---

## 5. 内部类 API（参考）

> 以下类由系统内部管理，通常不需要直接操作。

### 5.1 InstallSignalHub

**路径：** `component/UpdateManager/install_signal_hub.gd`

**职责：** 信号汇聚中心。

#### 信号
```gdscript
signal state_changed(state: InstallState)
signal error_occurred(error_message: String)
```

---

### 5.2 UpdateFlow

**路径：** `component/UpdateManager/update_flow.gd`

**职责：** 执行更新流程。

#### 方法
| 方法 | 说明 |
|------|------|
| `test_patch_download(local, server)` | 下载补丁 |
| `test_patch_install(local, server)` | 安装补丁 |
| `test_full_download(local, server)` | 下载全量包 |
| `test_full_install(local, server)` | 安装全量包 |

---

### 5.3 PatchInstall

**路径：** `script/class/check_version/patch_install.gd`

**职责：** 补丁包下载与安装。

#### 信号
```gdscript
signal state_changed(state: InstallSignalHub.InstallState)
signal error_occurred(error_message: String)
signal download_finished
signal install_finished
```

---

### 5.4 FullInstall

**路径：** `script/class/check_version/full_install.gd`

**职责：** 全量包下载与安装（继承 `PatchInstall`）。

---

### 5.5 UpdateChecker

**路径：** `script/class/check_version/update_checker.gd`

**职责：** 纯逻辑版本比较。

#### 方法
```gdscript
func check(local: VersionInfo, server: UpdatePolicy) -> String:
    # 返回："UP_TO_DATE" / "FULL_UPDATE_REQUIRED" / "NORMAL_UPDATE_REQUIRED" / "UNKNOWN"
```

---

### 5.6 UpdatePolicy

**路径：** `script/class/check_version/update_policy.gd`

**职责：** 服务器更新策略数据类。

#### 变量
| 变量 | 类型 | 说明 |
|------|------|------|
| `game_name` | `String` | 游戏名称 |
| `target_version` | `String` | 目标版本 |
| `force_full_package` | `bool` | 是否强制全量更新 |
| `update_notes` | `String` | 更新公告 |
| `err_notes` | `String` | **错误信息（网络请求失败时填充）** |

---

### 5.7 VersionUtils

**路径：** `script/class/check_version/version_utils.gd`

**职责：** 版本工具类（全局单例）。

#### 方法
| 方法 | 说明 |
|------|------|
| `get_version_info(path) -> VersionInfo` | 从 JSON 文件读取版本信息 |
| `get_update_policy(repo) -> UpdatePolicy` | 从 GitHub 获取更新策略（**失败时填充 `err_notes`**） |
| `check_game_installed(game_name, path) -> bool` | 检查游戏是否已安装 |
| `reset_version(path) -> bool` | 重置版本文件 |

---

## 6. 错误处理策略

### 6.1 错误分类

| 错误类型 | 信号 | 错误信息位置 |
|---------|------|------------|
| 网络错误（获取更新策略失败） | `update_state_changed(CHECK_FAILED)` | `_server.err_notes` |
| JSON 解析失败 | `update_state_changed(CHECK_FAILED)` | `_server.err_notes` |
| 未知版本结果 | `update_state_changed(CHECK_FAILED)` | - |
| 下载文件失败 | `update_error_occurred` | 信号参数 |
| 安装文件失败 | `update_error_occurred` | 信号参数 |

### 6.2 错误处理示例

```gdscript
func _on_update_state(state: InstallSignalHub.InstallState) -> void:
    if state == InstallSignalHub.InstallState.CHECK_FAILED:
        # 检查更新失败，从 _server 获取错误详情
        var error_msg = install_component._server.err_notes
        _show_error_dialog("检查更新失败：" + error_msg)

func _on_update_error(error_message: String) -> void:
    # 下载/安装过程中的错误
    printerr("运行时错误：", error_message)
    _show_error_dialog(error_message)
```

---

## 7. 完整使用示例

### 7.1 基础 UI 控制器

```gdscript
extends Control
class_name UpdateUIController

@onready var install_component: InstallComponent = $InstallComponent
@onready var status_label: Label = $StatusLabel
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var download_button: Button = $DownloadButton
@onready var install_button: Button = $InstallButton
@onready var launch_button: Button = $LaunchButton

func _ready() -> void:
    install_component.update_state_changed.connect(_on_update_state)
    install_component.update_error_occurred.connect(_on_update_error)

func _on_update_state(state: InstallSignalHub.InstallState) -> void:
    match state:
        InstallSignalHub.InstallState.NOT_INSTALLED:
            _set_ui_state("未安装", true, false, false)
        
        InstallSignalHub.InstallState.CHECKING_UPDATE:
            _set_ui_state("正在检查更新...", false, false, false)
        
        InstallSignalHub.InstallState.UP_TO_DATE:
            _set_ui_state("已是最新版", false, false, true)
        
        InstallSignalHub.InstallState.NEED_UPDATE:
            _set_ui_state("发现新版本", true, false, false)
        
        InstallSignalHub.InstallState.CHECK_FAILED:
            var error = install_component._server.err_notes
            status_label.text = "检查失败：" + error
            _set_buttons(false, false, false)
        
        InstallSignalHub.InstallState.DOWNLOAD_STARTED:
            status_label.text = "下载中..."
            progress_bar.visible = true
            _set_buttons(false, false, false)
        
        InstallSignalHub.InstallState.DOWNLOAD_FINISHED:
            status_label.text = "下载完成，请点击安装"
            progress_bar.visible = false
            _set_buttons(false, true, false)
        
        InstallSignalHub.InstallState.INSTALL_STARTED:
            status_label.text = "安装中..."
            _set_buttons(false, false, false)
        
        InstallSignalHub.InstallState.INSTALL_FINISHED:
            status_label.text = "安装完成"
            _set_buttons(false, false, true)

func _on_update_error(error_message: String) -> void:
    status_label.text = "错误：" + error_message

func _set_buttons(show_download: bool, show_install: bool, show_launch: bool) -> void:
    download_button.visible = show_download
    install_button.visible = show_install
    launch_button.visible = show_launch

# 按钮回调
func _on_refresh_pressed() -> void:
    install_component.re_ready()

func _on_download_pressed() -> void:
    install_component._on_下载_pressed()

func _on_install_pressed() -> void:
    install_component._on_开始安装_pressed()

func _on_launch_pressed() -> void:
    _launch_game()
```

---

## 8. 常见问题解答

### Q1: 如何获取检查更新失败的详细错误信息？

**答：** 通过 `_server.err_notes` 获取：

```gdscript
if state == InstallSignalHub.InstallState.CHECK_FAILED:
    var error = install_component._server.err_notes
    print("错误详情：", error)
```

---

### Q2: `CHECK_FAILED` 和 `update_error_occurred` 有什么区别？

**答：**
- `CHECK_FAILED` → 版本检查阶段失败（网络错误、JSON 解析失败），通过 `update_state_changed` 发出
- `update_error_occurred` → 下载/安装阶段错误，通过独立信号发出

---

### Q3: 如何强制重新检查版本？

**答：** 调用 `re_ready()`：

```gdscript
install_component.re_ready()
```

---

### Q4: 如何区分全量更新和补丁更新？

**答：** 检查 `_server.force_full_package`：

```gdscript
if state == InstallSignalHub.InstallState.NEED_UPDATE:
    if install_component._server.force_full_package:
        print("需要全量更新")
    else:
        print("需要补丁更新")
```

---

### Q5: 信号会重复触发吗？

**答：** 不会。`InstallSignalHub` 防止重复注册。

---

## 9. 文件列表

| 文件 | 路径 | 说明 |
|------|------|------|
| `install_component.gd` | `component/InstallComponent/` | **主组件（你只需要和它交互）** |
| `install_signal_hub.gd` | `component/UpdateManager/` | 信号汇聚中心 |
| `update_flow.gd` | `component/UpdateManager/` | 流程控制器 |
| `patch_install.gd` | `script/class/check_version/` | 补丁安装器 |
| `full_install.gd` | `script/class/check_version/` | 全量安装器 |
| `update_checker.gd` | `script/class/check_version/` | 版本比较器 |
| `update_policy.gd` | `script/class/check_version/` | 服务器策略（含 `err_notes`） |
| `version_utils.gd` | `script/class/check_version/` | 版本工具类 |

---

## 10. 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.1 | 2026-03-04 | 新增 `err_notes` 错误信息字段；统一使用 `update_state_changed` 调度所有状态；添加快速开始章节 |
| 1.0 | 2026-03-04 | 初始版本 |

---

## 附录 A：UpdateChooseFile 自定义文件选择

**路径：** `component/UpdateManager/update_choose_file.gd`

**用途：** 允许用户选择本地的 ZIP 文件作为自定义安装包（用于离线更新或测试）。

---

### A.1 核心方法

#### `select_zip_file() -> bool`

弹出文件选择对话框，让用户选择 ZIP 文件。

**返回值：**
| 返回值 | 说明 |
|--------|------|
| `true` | 用户成功选择了有效的 ZIP 文件 |
| `false` | 用户取消选择 或 选择的文件不是有效 ZIP |

**副作用：**
- 成功时，`selected_path` 变量会被设置为选中文件的路径
- 失败时，`selected_path` 为空字符串

**阻塞行为：**
- 此方法使用 `await file_dialog.file_selected`
- **会等待用户操作完成**（游戏不会卡住，只是代码暂停在这一行）
- 用户选择/取消后继续执行

**示例：**
```gdscript
func _on_select_custom_file_pressed() -> void:
    var result = await update_choose_file.select_zip_file()
    
    if result:
        # 用户成功选择了 ZIP 文件
        print("选择的文件：", update_choose_file.selected_path)
        # 可以继续复制文件等操作
    else:
        # 用户取消或文件无效
        print("选择失败")
```

---

#### `copy_file_to_install(source_path: String) -> bool`

将选中的 ZIP 文件复制到安装目录。

**参数：**
- `source_path` - 源文件路径（通常用 `selected_path`）

**返回值：**
| 返回值 | 说明 |
|--------|------|
| `true` | 复制成功 |
| `false` | 复制失败（源文件不存在/无法打开/无法创建目标文件） |

**行为：**
1. 清空目标目录（`VersionUtils.clear_folder`）
2. 复制文件到 `copy_path` 目录
3. 使用 1MB 缓冲区逐块复制（适合大文件）

**示例：**
```gdscript
func _on_install_custom_pressed() -> void:
    if update_choose_file.selected_path.is_empty():
        print("请先选择文件")
        return
    
    var success = await update_choose_file.copy_file_to_install(
        update_choose_file.selected_path
    )
    
    if success:
        print("文件复制成功")
        # 继续安装流程...
    else:
        print("文件复制失败")
```

---

### A.2 完整使用流程

```gdscript
extends Control

@onready var update_choose_file: Node = $Component/UpdateChooseFile

# 步骤 1：设置目标目录
func _ready() -> void:
    update_choose_file.copy_path = "user://download/full/"

# 步骤 2：用户点击"选择文件"按钮
func _on_choose_file_pressed() -> void:
    var result = await update_choose_file.select_zip_file()
    
    if result:
        print("已选择：", update_choose_file.selected_path)
        _enable_install_button()
    else:
        print("选择已取消")

# 步骤 3：用户点击"安装"按钮
func _on_install_pressed() -> void:
    if update_choose_file.selected_path.is_empty():
        print("请先选择文件")
        return
    
    # 复制文件到安装目录
    var copied = await update_choose_file.copy_file_to_install(
        update_choose_file.selected_path
    )
    
    if copied:
        print("准备就绪，可以开始安装")
        # 触发安装流程...
```

---

### A.3 注意事项

| 项目 | 说明 |
|------|------|
| **文件验证** | `select_zip_file()` 会自动检查 ZIP 文件头（PK 标志） |
| **阻塞等待** | 方法会等待用户操作，无需额外 `await` 处理 |
| **路径设置** | 使用前必须设置 `copy_path`，否则复制会失败 |
| **大文件支持** | 使用 1MB 缓冲区复制，适合大型游戏包 |

---

## 附录 B：PopupManager 弹窗行为

### B.1 按钮点击后的关闭行为

**默认行为：** 点击任何按钮 → 弹窗**自动关闭**

**保持打开：** 设置 `stay_open: true`

```gdscript
# 默认：点击后关闭
PopupManager.show_popup({
    "buttons": [
        {"text": "确定", "type": "primary", "metadata": "ok"}
    ]
})

# 设置 stay_open：点击后不关闭
PopupManager.show_popup({
    "buttons": [
        {
            "text": "下一步",
            "type": "primary",
            "metadata": "next",
            "stay_open": true  # ← 保持打开
        }
    ]
})
```

---

### B.2 关闭场景总结

| 场景 | 是否关闭 |
|------|---------|
| 点击普通按钮 | ✅ 自动关闭 |
| 点击 `stay_open: true` 的按钮 | ❌ 不关闭 |
| 打开新弹窗 | ✅ 旧弹窗自动关闭（单弹窗模式） |
| 调用 `PopupManager.close_popup()` | ✅ 手动关闭 |

---

### B.3 多步骤弹窗示例

```gdscript
# 第一步
PopupManager.show_popup({
    "title": "步骤 1/3",
    "content": "这是第一步",
    "buttons": [
        {"text": "下一步", "type": "primary", "metadata": "next", "stay_open": true}
    ]
})

# 在回调中更新内容（不关闭）
func _on_next_button_pressed() -> void:
    PopupManager.update_popup({
        "title": "步骤 2/3",
        "content": "这是第二步"
    })
```
