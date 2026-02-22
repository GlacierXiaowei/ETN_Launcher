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
