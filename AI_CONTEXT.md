# AI_CONTEXT.md - ETN 启动器开发上下文文档

## 概述

本文档记录 ETN 游戏启动器的开发过程，包括需求分析、模块设计、代码实现及遇到的问题解决方案。

---

## 一、需求背景

### 1.1 项目目标

构建一个支持以下功能的游戏启动器：
- 版本检查
- 热更新（补丁下载与安装）
- 完整包更新
- 文件完整性校验（待实现）

### 1.2 参考文档

- `etn_启动器实施指南_v_1.md` - 实施指南
- `etn_版本系统_json_模板与职责划分.md` - JSON 模板与职责划分

### 1.3 关键文件模板

**本地版本文件（游戏本体）**：`游戏本体的version.json`
```json
{
  "game_name": "ETN_Farm",
  "base_version": "1.1.0.0",
  "base_patch_max": 0,
  "equal_version": "1.1.0.0"
}
```

**云端版本文件**：`模板_cloud_version.json`
```json
{
  "min_supported_version": "1.0.0",
  "target_version": "1.1.0",
  "target_patch": 3,
  "force_update": true,
  "force_full_package": false,
  "full_package": {
    "version": "1.1.0",
    "url": "https://xxx/full_1.1.0.zip"
  },
  "patches": [
    {
      "patch_id": 13,
      "from_patch": 12,
      "to_patch": 13,
      "url": "https://xxx/patch_13.zip",
      "notice": "修复UI闪退问题"
    }
  ]
}
```

---

## 二、模块设计

### 2.1 文件结构

```
script/check_version/
├── version_info.gd      # 本地版本信息
├── update_policy.gd     # 服务器更新策略
├── update_checker.gd    # 版本比较逻辑
├── version_utils.gd     # 版本工具（单例）
├── patch_install.gd     # 补丁下载与安装
└── full_install.gd      # 完整包下载与安装（继承 PatchInstall）
```

### 2.2 类说明

| 类名 | 用途 | 创建方式 |
|------|------|----------|
| VersionInfo | 本地版本信息数据类 | `new(Dictionary)` |
| UpdatePolicy | 服务器更新策略数据类 | `new(Dictionary)` |
| UpdateChecker | 版本比较逻辑 | `new()` |
| VersionUtils | 版本号转换工具（单例） | 直接调用方法 |
| PatchInstall | 补丁下载与安装 | `new()` + `add_child()` |
| FullInstall | 完整包下载与安装 | `new()` + `add_child()` |

---

## 三、代码实现

### 3.1 VersionInfo (version_info.gd)

```gdscript
extends Node
class_name VersionInfo

var base_version: String
var base_patch_max: int
var equal_version: String
var game_name: String

func _init(data: Dictionary = {}):
    base_version = data.get("base_version", "")
    base_patch_max = data.get("base_patch_max", 0)
    equal_version = data.get("equal_version", "")
    game_name = data.get("game_name", "")
```

### 3.2 UpdatePolicy (update_policy.gd)

```gdscript
extends Node
class_name UpdatePolicy

var min_supported_version: String
var target_version: String
var target_patch: int
var force_update: bool
var force_full_package: bool
var full_package: Dictionary
var patches: Array

func _init(data: Dictionary = {}):
    min_supported_version = data.get("min_supported_version", "")
    target_version = data.get("target_version", "")
    target_patch = data.get("target_patch", 0)
    force_update = data.get("force_update", false)
    force_full_package = data.get("force_full_package", false)
    full_package = data.get("full_package", {})
    patches = data.get("patches", [])
```

### 3.3 UpdateChecker (update_checker.gd)

```gdscript
class_name UpdateChecker
extends Node

func check(local: VersionInfo, server: UpdatePolicy) -> String:
    var base_version: int = VersionUtils.version_to_int(local.base_version)
    var min_supported_version: int = VersionUtils.version_to_int(server.min_supported_version)
    var equal_version: int = VersionUtils.version_to_int(local.equal_version)
    var target_version: int = VersionUtils.version_to_int(server.target_version)
    
    if equal_version >= target_version:
        return "UP_TO_DATE"
    
    if base_version < min_supported_version:
        server.force_full_package = true
        return "FULL_UPDATE_REQUIRED"
    
    if server.force_full_package:
        return "FULL_UPDATE_REQUIRED"
    
    if equal_version < target_version:
        return "NORMAL_UPDATE_REQUIRED"
    
    return "UNKNOWN_STATE"
```

### 3.4 VersionUtils (version_utils.gd)

已设置为全局单例，包含以下方法：

```gdscript
extends Node
##已设置为全局单例

const GITHUB_OWNER = "GlacierXiaowei"
const VERSION_FILE_NAME = "cloud_version.json"

func version_to_int(version: String) -> int
func int_to_version(num: int, part_count: int = 4) -> String
func get_update_policy(repo: String = "ETN_Farm") -> UpdatePolicy
func get_version_info(path: String = "") -> VersionInfo
```

### 3.5 PatchInstall (patch_install.gd)

继承自 Node，使用 `new()` 创建后需要 `add_child()` 添加到场景树。

**核心方法：**

- `init_installed_patch()` - 扫描已安装补丁
- `init_need_installed_patch()` - 计算需要下载的补丁
- `begin_download()` - 开始下载
- `begin_install()` - 开始安装
- `download_single_file(url, file_name)` - 下载单个文件（带进度）

**信号：**
```gdscript
signal download_progress_changed(current_bytes: int, total_bytes: int)
```

### 3.6 FullInstall (full_install.gd)

继承自 PatchInstall，复用父类方法，新增：
- `begin_download()` - 下载完整包
- `begin_install()` - 解压并安装
- `unzip_file(zip_path, dest_path)` - ZIP 解压

---

## 四、下载进度实现

### 4.1 问题描述

在实现下载进度功能时，遇到以下问题：
- 使用 `await http_request.request_completed` 导致进度循环只执行一次
- 使用 `get_http_client_status()` 判断完成状态不可靠
- 进度到达 100% 后卡住

### 4.2 最终解决方案

使用 Timer 定时器轮询进度 + request_completed 信号确认完成：

```gdscript
func download_single_file(url: String, file_name: String) -> bool:
    var http_request = HTTPRequest.new()
    add_child(http_request)
    
    var timer = Timer.new()
    timer.wait_time = 0.25
    timer.autostart = true
    timer.one_shot = false
    add_child(timer)
    
    var download_complete = false
    var final_code = -1
    var final_body = PackedByteArray()
    
    http_request.request_completed.connect(
        func(result: int, code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
            final_code = code
            final_body = body
            download_complete = true
    )
    
    var error = http_request.request(url)
    if error != OK:
        _remove_http_request(http_request, timer)
        return false
    
    # 轮询进度
    while not download_complete:
        var current_bytes = http_request.get_downloaded_bytes()
        var total_bytes = http_request.get_body_size()
        if total_bytes > 0:
            download_progress_changed.emit(current_bytes, total_bytes)
        await timer.timeout
    
    timer.stop()
    _remove_http_request(http_request, timer)
    
    # 处理结果...
    return download_success

func _remove_http_request(http_request: HTTPRequest, timer: Timer) -> void:
    if timer:
        timer.stop()
        if timer.get_parent() == self:
            remove_child(timer)
        timer.queue_free()
    
    if http_request:
        if http_request.get_parent() == self:
            remove_child(http_request)
        http_request.queue_free()
```

### 4.3 使用方式

```gdscript
# 创建并添加到场景树
var installer = PatchInstall.new(local, server)
installer.install_path = user_path.path_join("patch")
add_child(installer)

# 连接进度信号
installer.download_progress_changed.connect(_on_download_progress)

# 开始下载
await installer.begin_download()

func _on_download_progress(current: int, total: int):
    var percent = float(current) / float(total) * 100.0
    label.text = "下载进度: %.1f%%" % percent
```

---

## 五、测试场景

### 5.1 install_test_scene.gd

测试场景位于 `scene/test/install_test_scene.gd`，包含：

- 自动获取本地版本信息
- 从 GitHub 获取服务器策略
- 版本比较
- 根据结果执行补丁更新或完整包更新
- 进度显示到 UI Label

---

## 六、TODO 待办事项

- [ ] **版本校验（Hash 验证）**
  - 在下载/安装完成后添加 SHA-256 哈希校验
  - 校验 version.json 中记录的 hash 值
  - 校验失败时重新下载
  - 优先级：中

---

## 七、使用示例

### 完整更新流程

```gdscript
extends Control

var game_dir = OS.get_environment("APPDATA")
var user_path = game_dir.path_join("ETN_Farm")

@onready var label: Label = $MarginContainer/VBoxContainer/Label

func _ready():
    await test_flow()

func test_flow():
    # 1. 获取本地版本
    var local = VersionUtils.get_version_info(user_path.path_join("version.json"))
    
    # 2. 获取服务器策略
    var server = await VersionUtils.get_update_policy("ETN_Farm")
    
    # 3. 版本比较
    var result = UpdateChecker.new().check(local, server)
    
    match result:
        "UP_TO_DATE":
            print("已是最新版本")
        "NORMAL_UPDATE_REQUIRED":
            await do_patch_update(local, server)
        "FULL_UPDATE_REQUIRED":
            await do_full_update(local, server)

func do_patch_update(local, server):
    var installer = PatchInstall.new(local, server)
    installer.install_path = user_path.path_join("patch")
    add_child(installer)
    installer.download_progress_changed.connect(_on_progress)
    
    installer.all_patch = server.patches
    installer.init_installed_patch()
    installer.init_need_installed_patch()
    
    await installer.begin_download()
    await installer.begin_install()
    
    installer.queue_free()

func do_full_update(local, server):
    var installer = FullInstall.new(local, server)
    add_child(installer)
    installer.download_progress_changed.connect(_on_progress)
    
    await installer.begin_download()
    await installer.begin_install()
    
    installer.queue_free()

func _on_progress(current: int, total: int):
    if total > 0:
        var percent = float(current) / float(total) * 100.0
        label.text = "下载进度: %.1f%%" % percent
        print("下载进度: %d / %d (%.1f%%)" % [current, total, percent])
```

---

## 八、注意事项

1. **HTTPRequest 需要添加到场景树**：使用 `new()` 创建后必须 `add_child()`
2. **资源清理**：使用 `queue_free()` 而非 `free()`，避免锁定对象
3. **GitHub API 限制**：每小时 60 次，建议使用 Release 下载链接
4. **补丁文件名格式**：`Patch_XXX.pck`（3位补零，如 Patch_001.pck）
5. **ZIP 解压**：完整包使用 ZIPReader 解压

---

## 九、相关文件路径

- 项目根目录：`D:\冰川小未\Godot ALL\项目文件\ETN_Launcher\`
- 脚本目录：`script/check_version/`
- 测试场景：`scene/test/install_test_scene.gd`
- 配置文件：`模板_cloud_version.json`、`游戏本体的version.json`

---

*本文档最后更新于 2026-02-23*
