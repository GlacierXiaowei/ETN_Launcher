# ETN 启动器 — 项目文档

---

## 1. 项目概述

ETN Launcher 是一个游戏启动器，支持多游戏管理、版本检查、热更新补丁下载与完整性校验。

### 适用范围
- Windows 平台
- Godot 项目结构（EXE + PCK）

---

## 2. 安装与运行

### 安装位置
```
%LOCALAPPDATA%/ETN/
```

### Godot 获取安装路径
```gdscript
var game_dir = OS.get_environment("LOCALAPPDATA") + "/ETN/"
```

### 文件结构
```
ETN/
├─ ETN.exe                # 主程序（引擎入口）
├─ ETN.pck                # 主资源包（永不覆盖）
├─ patches/
│    ├─ patch_001.pck
│    ├─ patch_002.pck
│    └─ ...
├─ version.json           # 本地版本信息
└─ launcher.exe           # 启动器
```

---

## 3. 模块说明

### LauncherCore
启动器核心流程控制，协调各模块工作。

### VersionCheck
版本检查服务，负责：
- 读取本地版本信息
- 获取服务器 Release JSON
- 对比版本判断是否需要更新

### PatchDownloader
补丁下载服务，负责：
- 下载补丁文件
- 支持断点续传
- 下载进度回调

### PatchManager
补丁管理，负责：
- 计算需要下载的补丁列表
- 管理本地补丁文件
- 应用补丁

### IntegrityVerifier
完整性校验，负责：
- SHA-256 哈希计算
- 文件完整性验证

### WindowsManager
窗口管理，负责：
- 窗口生命周期
- UI 交互

### Utils
通用工具，负责：
- 日志记录
- 文件操作
- 网络请求封装

---

## 4. API 参考

### VersionCheck

```gdscript
# 获取本地版本信息
func get_local_version() -> Dictionary

# 获取服务器版本信息
func get_remote_version(game_id: String) -> Dictionary

# 检查是否需要更新
func need_update(local: Dictionary, remote: Dictionary) -> bool
```

### PatchDownloader

```gdscript
# 下载文件
func download_file(url: String, save_path: String, progress_callback: Callable) -> int

# 取消下载
func cancel_download()

# 获取下载进度
func get_progress() -> float
```

### PatchManager

```gdscript
# 计算需要下载的补丁
func calculate_patches_needed(current_patch: int, target_patches: Array) -> Array

# 应用补丁
func apply_patch(patch_path: String) -> bool

# 获取已安装补丁列表
func get_installed_patches() -> Array
```

### IntegrityVerifier

```gdscript
# 计算文件哈希
func calculate_hash(file_path: String) -> String

# 验证文件完整性
func verify_file(file_path: String, expected_hash: String) -> bool
```

### Utils

```gdscript
# 获取安装路径
func get_install_path() -> String

# 保存安装路径到注册表
func save_install_path(path: String)

# 日志记录
func log(level: String, message: String)

# 文件操作
func ensure_dir(path: String) -> bool
func delete_file(path: String) -> bool
```

---

## 5. 数据结构

### 本地版本信息 (version.json)

```json
{
  "game_id": "embodied_now",
  "version": "1.0.3",
  "base_version": "1.0.0",
  "installed_patch": 3
}
```

### 服务器版本信息 (Release JSON)

详见 LAUNCHER_CONTEXT.md 中的设计文档。

---

## 6. 更新流程

### 启动器更新流程
1. 启动 launcher.exe
2. 检查自身版本
3. 若需更新 → 下载 → 重启

### 游戏更新流程
1. 用户选择游戏
2. 读取本地 version.json
3. 获取服务器 Release JSON
4. 判断更新类型
5. 执行更新
6. 启动游戏

### 更新类型判断

| 条件 | 更新类型 |
|------|----------|
| force_full_update = true | 全量更新 |
| base_version > 当前版本 | 全量更新 |
| 否则 | 补丁更新 |

---

## 7. 错误处理

| 错误 | 处理方式 |
|------|----------|
| 网络连接失败 | 重试 3 次，失败后允许跳过 |
| 哈希校验失败 | 删除文件，重新下载 |
| 文件写入失败 | 提示用户，记录日志 |
| 磁盘空间不足 | 提示用户清理空间 |

---

## 8. 日志规范

### 日志等级
- DEBUG：调试信息
- INFO：常规信息
- WARNING：警告信息
- ERROR：错误信息

### 日志格式
```
[时间] [等级] [模块] 消息内容
```

### 日志位置
```
%LOCALAPPDATA%/ETN/logs/launcher.log
```

---

## 9. 配置说明

### 注册表配置
```
HKEY_CURRENT_USER\Software\ETN\
├─ InstallPath    # 游戏安装路径
└─ Language       # 语言设置
```

---

## 10. 开发指南

### 环境要求
- Godot 4.x
- GDScript

### 目录结构
```
ETN_Launcher/
├─ script/
│    ├─ version_check.gd
│    ├─ patch_manager.gd
│    ├─ integrity_verifier.gd
│    └─ utils.gd
├─ scenes/
│    └─ open/
│        ├─ main.tscn
│        └─ ui.tscn
├─ assets/
│    └─ ui/
└─ project.godot
```

## 11. 版本更新需要修改的文件
### 所有的version.json 以及哈希
### 等效版本
- 补丁包一定要修改GameVersion，修改等效版本，
- 完整包需要更改等效版本
- 启动器也别忘了

---

## 12. check_version 模块 API 文档

### 12.1 概述

位于 `script/check_version/` 目录下的版本控制模块，负责：
- 版本信息解析与比较
- 补丁下载与安装
- 完整包下载与安装

### 12.2 类列表

| 类名 | 文件 | 用途 |
|------|------|------|
| VersionInfo | version_info.gd | 本地版本信息数据类 |
| UpdatePolicy | update_policy.gd | 服务器更新策略数据类 |
| UpdateChecker | update_checker.gd | 版本比较逻辑 |
| VersionUtils | version_utils.gd | 版本号转换工具（单例） |
| PatchInstall | patch_install.gd | 补丁下载与安装 |
| FullInstall | full_install.gd | 完整包下载与安装（继承 PatchInstall） |

---

### 12.3 VersionInfo

**文件：** `script/check_version/version_info.gd`

**用途：** 存储和解析本地版本信息

**JSON 数据源：** 游戏本体的 `version.json`

```json
{
  "game_name": "ETN_Farm",
  "base_version": "1.1.0.0",
  "base_patch_max": 0,
  "equal_version": "1.1.0.0"
}
```

**使用方式：**
```gdscript
# 方式1：从 JSON 文件读取
var file = FileAccess.open("res://游戏本体的version.json", FileAccess.READ)
var content = file.get_as_text()
file.close()
var json = JSON.new()
json.parse(content)
var local = VersionInfo.new(json.data)

# 访问属性
print(local.base_version)      # "1.1.0.0"
print(local.base_patch_max)    # 0
print(local.equal_version)     # "1.1.0.0"
print(local.game_name)         # "ETN_Farm"
```

**属性说明：**
| 属性 | 类型 | 说明 |
|------|------|------|
| base_version | String | 基础版本号 |
| base_patch_max | int | 当前最高补丁等级 |
| equal_version | String | 对外显示版本 |
| game_name | String | 游戏名称 |

---

### 12.4 UpdatePolicy

**文件：** `script/check_version/update_policy.gd`

**用途：** 存储和解析服务器更新策略

**JSON 数据源：** 云端 `cloud_version.json`

```json
{
  "game_name": "ETN_Farm",
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

**使用方式：**
```gdscript
# 从 JSON 文件读取
var file = FileAccess.open("res://模板_cloud_version.json", FileAccess.READ)
var content = file.get_as_text()
file.close()
var json = JSON.new()
json.parse(content)
var server = UpdatePolicy.new(json.data)

# 访问属性
print(server.game_name)              # "ETN_Farm"
print(server.min_supported_version) # "1.0.0"
print(server.target_version)         # "1.1.0"
print(server.target_patch)            # 3
print(server.force_update)            # true
print(server.force_full_package)       # false
print(server.full_package)             # Dictionary
print(server.patches)                 # Array
```

**属性说明：**
| 属性 | 类型 | 说明 |
|------|------|------|
| game_name | String | 游戏名称 |
| min_supported_version | String | 最低支持版本 |
| target_version | String | 目标版本 |
| target_patch | int | 目标补丁等级 |
| force_update | bool | 是否强制更新 |
| force_full_package | bool | 是否强制完整包更新 |
| full_package | Dictionary | 完整包信息（version, url） |
| patches | Array | 可用补丁列表 |

---

### 12.5 VersionUtils

**文件：** `script/check_version/version_utils.gd`

**用途：** 版本号转换工具（单例）

**使用方式：**
```gdscript
# 转换为整数（用于比较）
var num = VersionUtils.version_to_int("1.0.0.0")   # 返回 1000
var num = VersionUtils.version_to_int("2.1.1.1")   # 返回 2111

# 转换回字符串
var str = VersionUtils.int_to_version(1000)         # 返回 "1.0.0.0"
var str = VersionUtils.int_to_version(2111)         # 返回 "2.1.1.1"
var str = VersionUtils.int_to_version(100, 3)       # 返回 "1.0.0" (3段)
```

**方法说明：**
| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| version_to_int | version: String | int | 将版本号转为整数 |
| int_to_version | num: int, part_count: int = 4 | String | 将整数转回版本号 |

---

### 12.6 UpdateChecker

**文件：** `script/check_version/update_checker.gd`

**用途：** 版本比较，判断更新类型

**使用方式：**
```gdscript
var checker = UpdateChecker.new()
var result = checker.check(local, server)

# result 返回值：
# "UP_TO_DATE"                 - 无需更新
# "FULL_UPDATE_REQUIRED"       - 需要全量更新
# "NORMAL_UPDATE_REQUIRED"     - 需要普通更新
# "UNKNOWN_STATE"              - 未知状态
```

---

### 12.7 PatchInstall

**文件：** `script/check_version/patch_install.gd`

**用途：** 补丁下载与安装

**重要：** 需要加入场景树才能使用（因为使用了 HTTPRequest 子节点）

**使用方式：**
```gdscript
# 1. 创建实例并添加到场景树
var installer = PatchInstall.new(local, server, "user://patches/")
add_child(installer)

# 2. 初始化
installer.all_patch = server.patches  # 必须设置！
installer.init_installed_patch()      # 扫描已安装补丁
installer.init_need_installed_patch() # 计算需要下载的补丁

# 3. 下载
await installer.begin_download()

# 4. 安装
await installer.begin_install()

# 5. 检查结果
if installer.is_download_successful and installer.is_install_successful:
    print("补丁更新完成！")
else:
    print("更新失败")

# 访问属性
print(installer.installed_patch)       # 已安装的补丁列表
print(installer.need_installed_patch)  # 需要下载的补丁列表
```

**属性说明：**
| 属性 | 类型 | 说明 |
|------|------|------|
| all_patch | Array | 所有可用补丁（从服务器获取） |
| installed_patch | Array | 已安装的补丁 ID 列表 |
| need_installed_patch | Array | 需要下载的补丁 ID 列表 |
| download_path | String | 下载保存路径 |
| install_path | String | 安装目标路径 |
| is_download_successful | bool | 下载是否成功 |
| is_install_successful | bool | 安装是否成功 |

**方法说明：**
| 方法 | 说明 |
|------|------|
| init_installed_patch() | 扫描 install_path 下已安装的补丁 |
| init_need_installed_patch() | 计算需要下载的补丁列表 |
| begin_download() | 开始下载补丁（需 await） |
| begin_install() | 开始安装补丁（需 await） |

---

### 12.8 FullInstall

**文件：** `script/check_version/full_install.gd`

**用途：** 完整包下载与安装（继承自 PatchInstall）

**重要：** 需要加入场景树才能使用

**使用方式：**
```gdscript
# 1. 创建实例并添加到场景树
var installer = FullInstall.new(local, server)
add_child(installer)

# 2. 下载完整包
await installer.begin_download()

# 3. 解压并安装
await installer.begin_install()

# 4. 检查结果
if installer.is_download_successful and installer.is_install_successful:
    print("完整包安装完成！")
```

**继承自 PatchInstall 的方法：**
- begin_download()
- begin_install()
- clear_download_folder()
- download_single_file()
- move_file()

**新增方法：**
| 方法 | 说明 |
|------|------|
| unzip_file(zip_path, dest_path) | 解压 ZIP 文件 |

---

### 12.9 完整使用示例

```gdscript
extends Node

func _ready():
    # 1. 读取本地版本信息
    var local_file = FileAccess.open("res://游戏本体的version.json", FileAccess.READ)
    var local_json = JSON.new()
    local_json.parse(local_file.get_as_text())
    local_file.close()
    var local = VersionInfo.new(local_json.data)
    
    # 2. 读取服务器策略（实际项目中应从网络获取）
    var server_file = FileAccess.open("res://模板_cloud_version.json", FileAccess.READ)
    var server_json = JSON.new()
    server_json.parse(server_file.get_as_text())
    server_file.close()
    var server = UpdatePolicy.new(server_json.data)
    
    # 3. 版本比较
    var checker = UpdateChecker.new()
    var result = checker.check(local, server)
    
    match result:
        "UP_TO_DATE":
            print("已是最新版本")
            start_game()
        "NORMAL_UPDATE_REQUIRED":
            print("需要下载补丁")
            await download_patches(local, server)
        "FULL_UPDATE_REQUIRED":
            print("需要下载完整包")
            await download_full_package(local, server)

func download_patches(local, server):
    var installer = PatchInstall.new(local, server, "user://patches/")
    add_child(installer)
    
    installer.all_patch = server.patches
    installer.init_installed_patch()
    installer.init_need_installed_patch()
    
    await installer.begin_download()
    await installer.begin_install()
    
    if installer.is_download_successful and installer.is_install_successful:
        print("补丁更新成功！")
        start_game()

func download_full_package(local, server):
    var installer = FullInstall.new(local, server)
    add_child(installer)
    
    await installer.begin_download()
    await installer.begin_install()
    
    if installer.is_download_successful and installer.is_install_successful:
        print("完整包安装成功！")
        start_game()

func start_game():
    # 启动游戏
    pass
```

---

## TODO 待办事项

- [ ] **版本校验（Hash 验证）**
  - 在下载/安装完成后添加 SHA-256 哈希校验
  - 校验 version.json 中记录的 hash 值
  - 校验失败时重新下载
  - 优先级：中
