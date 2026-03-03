# Install Signal System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为 PatchInstall/FullInstall/UpdateChecker 设计完整的信号系统，通过 InstallSignalHub 汇聚信号并传递到 InstallTestScene，再向外传递。

**Architecture:** 
- InstallSignalHub 作为信号汇聚中心，定义 InstallState 枚举和两个核心信号
- PatchInstall/FullInstall/UpdateChecker 发出 state_changed 和 error_occurred 信号
- InstallTestScene 接收 Hub 的信号并重新 emit 向外传递
- 保留所有 push_error 用于调试

**Tech Stack:** Godot 4.x GDScript

---

## Task 1: InstallSignalHub 核心实现

**Files:**
- Modify: `component/UpdateManager/install_signal_hub.gd`

**Step 1: 定义 InstallState 枚举和信号**

```gdscript
extends Node
class_name InstallSignalHub

enum InstallState {
    CHECKING_UPDATE,
    CHECK_FAILED,
    UP_TO_DATE,
    DOWNLOAD_STARTED,
    DOWNLOAD_FINISHED,
    INSTALL_STARTED,
    INSTALL_FINISHED
}

signal state_changed(state: InstallState)
signal error_occurred(error_message: String)
```

**Step 2: 添加注册/注销安装器的方法**

```gdscript
var _connected_installers: Array = []

func register_installer(installer: Node) -> void:
    if installer in _connected_installers:
        return
    _connected_installers.append(installer)
    
    if installer.has_signal("state_changed"):
        installer.state_changed.connect(_on_installer_state_changed.bind(installer))
    if installer.has_signal("error_occurred"):
        installer.error_occurred.connect(_on_installer_error)

func unregister_installer(installer: Node) -> void:
    if not installer in _connected_installers:
        return
    _connected_installers.erase(installer)
    
    if installer.has_signal("state_changed"):
        installer.state_changed.disconnect(_on_installer_state_changed.bind(installer))
    if installer.has_signal("error_occurred"):
        installer.error_occurred.disconnect(_on_installer_error)

func _on_installer_state_changed(state: InstallState, installer: Node) -> void:
    state_changed.emit(state)

func _on_installer_error(error_message: String) -> void:
    error_occurred.emit(error_message)
```

**Step 3: 添加清理方法（防止内存泄漏）**

```gdscript
func _exit_tree() -> void:
    for installer in _connected_installers:
        if is_instance_valid(installer):
            unregister_installer(installer)
```

**Step 4: 验证语法**
- 在 Godot 编辑器中打开 `install_signal_hub.tscn`
- 确认无脚本错误

---

## Task 2: PatchInstall 信号集成

**Files:**
- Modify: `script/class/check_version/patch_install.gd`

**Step 1: 添加信号定义（在 class_name 下方）**

```gdscript
signal state_changed(state: InstallState)
signal error_occurred(error_message: String)
```

**Step 2: 修改 _init 中的错误处理**

```gdscript
func _init(local: VersionInfo, server: UpdatePolicy) -> void:
    if local == null:
        push_error("[PatchInstall] Error: local VersionInfo is null")
        error_occurred.emit("Initialization failed: local VersionInfo is null")
        return
    
    if server == null:
        push_error("[PatchInstall] Error: server UpdatePolicy is null")
        error_occurred.emit("Initialization failed: server UpdatePolicy is null")
        return
    # ... 其余代码保持不变
```

**Step 3: 修改 begin_download 添加状态信号**

```gdscript
func begin_download() -> void:
    is_download_successful = false
    state_changed.emit(InstallState.DOWNLOAD_STARTED)
    
    if not VersionUtils.clear_folder(download_path):
        push_error("[PatchInstall] begin_download: Failed to clear download folder")
        error_occurred.emit("Failed to clear download folder")
        return
    # ... 其余代码
```

**Step 4: 修改 begin_install 添加状态信号**

```gdscript
func begin_install() -> void:
    is_install_successful = false
    state_changed.emit(InstallState.INSTALL_STARTED)
    
    if download_path == "" or download_path.is_empty():
        push_error("[PatchInstall] begin_install: download_path is empty")
        error_occurred.emit("Download path is empty")
        install_finished.emit(is_install_successful)
        return
    # ... 其余代码
```

**Step 5: 修改成功完成时 emit 状态**

在 begin_install 成功结束时：
```gdscript
is_install_successful = true
print("[PatchInstall] begin_install: All patches installed successfully")
state_changed.emit(InstallState.INSTALL_FINISHED)
install_finished.emit(is_install_successful)
```

**Step 6: 为其他关键错误点添加 error_occurred.emit**

需要添加的位置：
- `init_installed_patch()`: install_path empty/dir not exist/open failed
- `init_need_installed_patch()`: base_patch_max/target_patch invalid
- `get_patch_urls()`: all_patch empty/URL empty/patch_id not found
- `download_single_file()`: URL/file_name empty/request failed/create file failed/HTTP error
- `begin_install()`: download dir not exist/open failed/no files to install/move file failed
- `move_file()`: source/dest empty/open failed/rename failed

**Step 7: 验证语法**
- 在 Godot 编辑器中打开相关场景
- 确认无脚本错误

---

## Task 3: FullInstall 信号集成

**Files:**
- Modify: `script/class/check_version/full_install.gd`

**Step 1: 确认继承 PatchInstall 的信号**
- FullInstall 继承自 PatchInstall，自动继承信号定义

**Step 2: 修改 _init 中的错误处理**

```gdscript
func _init(local: VersionInfo, server: UpdatePolicy) -> void:
    if local == null:
        push_error("[FullInstall] Error: local VersionInfo is null")
        error_occurred.emit("Initialization failed: local VersionInfo is null")
        return
    # ... 其余代码
```

**Step 3: 修改 begin_download 添加状态信号**

```gdscript
func begin_download() -> void:
    is_download_successful = false
    state_changed.emit(InstallState.DOWNLOAD_STARTED)
    
    if not clear_download_folder():
        push_error("[FullInstall] begin_download: Failed to clear download folder")
        error_occurred.emit("Failed to clear download folder")
        return
    # ... 其余代码
```

**Step 4: 修改 begin_install 添加状态信号和成功状态**

```gdscript
func begin_install() -> void:
    is_install_successful = false
    state_changed.emit(InstallState.INSTALL_STARTED)
    # ... 在成功结束时添加:
    is_install_successful = true
    state_changed.emit(InstallState.INSTALL_FINISHED)
    install_finished.emit(is_install_successful)
```

**Step 5: 为 unzip_file 添加错误信号**

```gdscript
func unzip_file(zip_path: String, dest_path: String) -> Array:
    var extracted_files = []
    
    if not FileAccess.file_exists(zip_path):
        push_error("[FullInstall] unzip_file: zip file does not exist: " + zip_path)
        error_occurred.emit("Zip file does not exist: " + zip_path)
        return extracted_files
    # ... 其余错误点同理
```

**Step 6: 验证语法**

---

## Task 4: UpdateChecker 信号集成

**Files:**
- Modify: `script/class/check_version/update_checker.gd`

**Step 1: 添加信号定义**

```gdscript
class_name UpdateChecker
extends Node

signal state_changed(state: InstallState)
signal error_occurred(error_message: String)
```

**Step 2: 修改 check 方法添加状态信号**

```gdscript
func check(local: VersionInfo, server: UpdatePolicy) -> String:
    state_changed.emit(InstallState.CHECKING_UPDATE)
    
    var base_version : int = VersionUtils.version_to_int(local.base_version)
    # ... 其余变量
    
    if equal_version >= target_version:
        state_changed.emit(InstallState.UP_TO_DATE)
        return "UP_TO_DATE"
    
    if base_version < min_supported_version:
        server.force_full_package = true
        state_changed.emit(InstallState.CHECK_FAILED)
        error_occurred.emit("Base version below minimum supported version")
        return "FULL_UPDATE_REQUIRED"
    
    if server.force_full_package:
        state_changed.emit(InstallState.CHECK_FAILED)
        error_occurred.emit("Server requires full package update")
        return "FULL_UPDATE_REQUIRED"
    
    if equal_version < target_version:
        return "NORMAL_UPDATE_REQUIRED"
    
    return "UNKNOWN"
```

**Step 3: 验证语法**

---

## Task 5: UpdateFlow 信号连接

**Files:**
- Modify: `component/UpdateManager/update_flow.gd`

**Step 1: 添加 signal_hub 引用**

```gdscript
extends Node

@export var install_test_scene : Node
@export var signal_hub : InstallSignalHub  # 新增
# ... 其余变量
```

**Step 2: 修改 test_patch_download 连接信号**

```gdscript
func test_patch_download(local, server) -> void:
    print("\n========== 开始补丁更新流程 ==========")
    
    installer = PatchInstall.new(local, server) as PatchInstall
    installer.install_path = user_path.path_join("patch")
    add_child(installer)
    
    # 注册到 signal_hub
    if signal_hub:
        signal_hub.register_installer(installer)
    
    installer.all_patch = server.patches
    print("[步骤 1] 已设置 all_patch: ", installer.all_patch.size(), " 个补丁")
    
    installer.init_installed_patch()
    print("[步骤 2] 已安装补丁：", installer.installed_patch)
    
    installer.init_need_installed_patch()
    print("[步骤 3] 需要下载的补丁：", installer.need_installed_patch)
    
    print("\n[步骤 4] 开始下载补丁...")
    installer.begin_download()  # 改为直接调用，等待内部信号
    await installer.download_finished
    
    # 注销信号
    if signal_hub:
        signal_hub.unregister_installer(installer)
```

**Step 3: 修改 test_patch_install 连接信号**

```gdscript
func test_patch_install(local, server) -> void:
    installer = PatchInstall.new(local, server) as PatchInstall
    add_child(installer)
    
    if signal_hub:
        signal_hub.register_installer(installer)
    
    print("\n[步骤 5] 开始安装补丁...")
    installer.begin_install()
    await installer.install_finished
    
    if signal_hub:
        signal_hub.unregister_installer(installer)
    
    if not installer.is_install_successful:
        print("[错误] 补丁安装失败")
        installer.queue_free()
        return
    
    print("[成功] 补丁安装完成！")
    print("========== 补丁更新流程结束 ==========")
    
    installer.queue_free()
```

**Step 4: 修改 test_full_download 和 test_full_install 同理**

**Step 5: 验证语法**

---

## Task 6: InstallTestScene 信号传递

**Files:**
- Modify: `scenes/test/install/test/install_test_scene.gd`

**Step 1: 添加向外传递的信号定义**

```gdscript
extends Node

# 新增：向外传递的信号
signal update_state_changed(state: InstallState)
signal update_error_occurred(error_message: String)

@export var update_choose_file: Node
# ... 其余代码
```

**Step 2: 添加 signal_hub 引用并连接信号**

```gdscript
@onready var update_flow: Node = $Component/UpdateFlow
@onready var signal_hub: Node = $Component/InstallSignalHub  # 新增

func _ready() -> void:
    # 连接 Hub 的信号
    signal_hub.state_changed.connect(_on_hub_state_changed)
    signal_hub.error_occurred.connect(_on_hub_error)
    
    await init_check_version()
    # ... 其余代码
```

**Step 3: 实现信号转发方法**

```gdscript
func _on_hub_state_changed(state: InstallState) -> void:
    # 转发给外部
    update_state_changed.emit(state)
    
    # 本地日志
    match state:
        InstallState.CHECKING_UPDATE:
            print("[InstallTestScene] 正在检查更新...")
        InstallState.CHECK_FAILED:
            print("[InstallTestScene] 检查更新失败")
        InstallState.UP_TO_DATE:
            print("[InstallTestScene] 已是最新版")
        InstallState.DOWNLOAD_STARTED:
            print("[InstallTestScene] 开始下载...")
        InstallState.DOWNLOAD_FINISHED:
            print("[InstallTestScene] 下载完成")
        InstallState.INSTALL_STARTED:
            print("[InstallTestScene] 开始安装...")
        InstallState.INSTALL_FINISHED:
            print("[InstallTestScene] 安装完成")

func _on_hub_error(error_message: String) -> void:
    # 转发给外部
    update_error_occurred.emit(error_message)
    
    # 本地日志
    printerr("[InstallTestScene] 错误：", error_message)
```

**Step 4: 修改 init_check_version 使用 UpdateChecker 的信号**

```gdscript
func init_check_version() -> void:
    print("========== 开始测试流程 ==========")
    print("用户目录：", user_path)
    
    print("\n[步骤 1] 获取本地版本信息...")
    var local = VersionUtils.get_version_info(user_path.path_join("version.json"))
    _local = local
    # ... 打印信息
    
    print("\n[步骤 2] 获取服务器更新策略...")
    var server = await VersionUtils.get_update_policy("ETN_Farm")
    _server = server
    # ... 打印信息
    
    print("\n[步骤 3] 版本比较...")
    var checker = UpdateChecker.new()
    
    # 连接 checker 的信号到 hub
    if signal_hub:
        signal_hub.register_installer(checker)
    
    var result = checker.check(local, server)
    print("  - 比较结果：", result)
    
    # 注销信号
    if signal_hub:
        signal_hub.unregister_installer(checker)
    
    checker.queue_free()
    
    update_needed_state.emit(result)
    # ... 其余 match 代码
```

**Step 5: 验证语法**

---

## Task 7: 场景文件更新

**Files:**
- Modify: `scenes/test/install/test/install_test_scene.tscn`

**Step 1: 添加 InstallSignalHub 节点到场景**

在 `[node name="Component" type="Node" parent="." ...]` 下方添加：

```
[node name="InstallSignalHub" parent="Component" unique_id=<new_id> instance=ExtResource("<hub_uid>")]
```

**Step 2: 更新 UpdateFlow 的 export 引用**

确保 UpdateFlow 的 signal_hub export 正确指向 InstallSignalHub

**Step 3: 验证场景加载**
- 在 Godot 编辑器中打开 `install_test_scene.tscn`
- 确认所有节点加载正常，无错误

---

## Task 8: 集成测试

**Step 1: 运行 InstallTestScene**
- 在 Godot 编辑器中运行场景
- 观察控制台输出，确认状态信号正确 emit

**Step 2: 测试各种状态流程**
- 测试 UP_TO_DATE 流程
- 测试 FULL_UPDATE_REQUIRED 流程
- 测试 NORMAL_UPDATE_REQUIRED 流程

**Step 3: 测试错误处理**
- 模拟网络错误，确认 error_occurred 信号正确触发
- 确认 push_error 仍然输出到控制台

**Step 4: 验证信号传递**
- 确认 InstallTestScene 的 update_state_changed 和 update_error_occurred 信号正确 emit

---

## Verification Checklist

- [ ] InstallSignalHub 定义 InstallState 枚举和两个信号
- [ ] InstallSignalHub 有 register/unregister_installer 方法
- [ ] PatchInstall 有 state_changed 和 error_occurred 信号
- [ ] PatchInstall 在关键节点 emit 状态和错误信号
- [ ] FullInstall 继承并正确使用信号
- [ ] UpdateChecker 有状态和错误信号
- [ ] UpdateFlow 正确连接/断开信号
- [ ] InstallTestScene 接收并转发信号
- [ ] InstallTestScene 场景包含 InstallSignalHub 节点
- [ ] 所有 push_error 保留用于调试
- [ ] 运行测试场景无报错
