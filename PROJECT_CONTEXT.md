# ETN 启动器 — 项目上下文

---

## 1. 背景与目标

- **目标**：构建结构清晰、可维护、具专业感的启动器体系
- **能力**：热更新、版本校验、完整性校验、启动控制
- **适用范围**：Windows 平台；Godot 项目结构（EXE + PCK）
- **设计原则**：不追求过度 DRM，强调秩序、一致性、可测试性

---

## 2. 文件结构

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

### 职责分离

| 组件 | 职责 |
|------|------|
| ETN.exe | 启动引擎，不承担版本/下载逻辑，不频繁更新 |
| ETN.pck | 完整初始内容，永不覆盖，作为基础层 |
| patch_xxx.pck | 只包含需覆盖的资源，路径与主包一致 |
| launcher.exe | 版本检查、补丁下载、完整性校验、启动决策 |

---

## 3. 安装位置

### 默认路径
```
%LOCALAPPDATA%/ETN/
```

### Godot 获取方式
```gdscript
var game_dir = OS.get_environment("LOCALAPPDATA") + "/ETN/"
```

### 自定义路径
- 首次启动时用户选择
- 路径写入注册表：`HKEY_CURRENT_USER\Software\ETN\InstallPath`

---

## 4. 核心模块

- **LauncherCore**：启动器核心流程控制
- **VersionCheck**：版本检查服务
- **PatchDownloader**：补丁下载服务
- **PatchManager**：补丁管理与覆盖逻辑
- **IntegrityVerifier**：完整性校验（SHA-256）
- **WindowsManager**：窗口管理与生命周期
- **Utils**：通用工具与日志

---

## 5. 多游戏支持

- 每个游戏独立 GitHub 仓库
- 每个仓库一个 Release JSON 文件
- Launcher 切换游戏时读取对应的 Release JSON

---

## 6. 数据契约

### Release JSON 模板

```json
{
  "game_id": "embodied_now",
  "version": "1.0.3",
  "base_version": "1.0.0",
  "force_update": false,
  "force_full_update": false,
  "install_path": "C:\\Users\\YourUser\\AppData\\Local\\ETN\\embodied_now",
  "full_package": {
    "filename": "ETN_v1.0.3_full.zip",
    "hash": "sha256:abcdef1234567890",
    "url": "https://github.com/yourorg/embodied_now/releases/download/v1.0.3/ETN_v1.0.3_full.zip",
    "size": 12345678
  },
  "patches": [
    {
      "patch_number": 1,
      "name": "patch_001.pck",
      "type": "PCK",
      "hash": "sha256:1111111111111111111",
      "url": "https://github.com/yourorg/embodied_now/releases/download/v1.0.3/patch_001.pck",
      "size": 2048000,
      "applies_from": "1.0.0",
      "applies_to": "1.0.1"
    },
    {
      "patch_number": 2,
      "name": "patch_002.pck",
      "type": "PCK",
      "hash": "sha256:2222222222222222222",
      "url": "https://github.com/yourorg/embodied_now/releases/download/v1.0.3/patch_002.pck",
      "size": 4096000,
      "applies_from": "1.0.1",
      "applies_to": "1.0.2"
    },
    {
      "patch_number": 3,
      "name": "patch_003.pck",
      "type": "ZIP",
      "hash": "sha256:3333333333333333333",
      "url": "https://github.com/yourorg/embodied_now/releases/download/v1.0.3/patch_003.pck",
      "size": 1024000,
      "applies_from": "1.0.2",
      "applies_to": "1.0.3"
    }
  ],
  "release_date": "2026-02-21",
  "notes": "Minor fixes and patch optimizations."
}
```

### 字段说明

| 字段 | 说明 |
|------|------|
| game_id | 游戏标识，用于 Launcher 切换游戏 |
| version | 目标版本号 |
| base_version | 最低基础版本，低于此版本需全量更新 |
| force_update | 是否强制更新（不可跳过） |
| force_full_update | 是否强制全量更新（必须下载完整包） |
| install_path | 游戏安装路径 |
| full_package | 完整包信息（用于全量更新） |
| patches | 补丁列表，按 patch_number 升序排列 |
| release_date | 发布日期 |
| notes | 更新说明 |

### 补丁字段说明

| 字段 | 说明 |
|------|------|
| patch_number | 补丁序号 |
| name | 补丁文件名 |
| type | 文件类型（PCK/ZIP） |
| hash | SHA-256 哈希 |
| url | 下载链接 |
| size | 文件大小（字节） |
| applies_from | 适用起始版本 |
| applies_to | 适用目标版本 |

---

## 7. 更新流程

### 启动器更新
1. 启动 launcher.exe
2. 检查自身版本
3. 若需更新 → 下载更新 → 重启

### 游戏更新
1. 用户选择游戏
2. 读取本地 version.json
3. 获取服务器 Release JSON
4. 判断更新类型：
   - `force_full_update = true` → 全量更新
   - `base_version > 当前版本` → 全量更新
   - 否则 → 补丁更新
5. 补丁更新：计算需要下载的补丁（当前补丁号 ~ 目标补丁号）
6. 下载 → 校验哈希 → 写入 patches/
7. 全部完成后允许启动游戏

---

## 8. 完整性校验

- **算法**：SHA-256
- **校验对象**：ETN.exe, ETN.pck, patch_xxx.pck
- **异常处理**：
  - 哈希不匹配 → 提示重新下载
  - 文件缺失 → 强制更新

---

## 9. 非功能性需求

- **性能**：异步操作，避免阻塞 UI
- **可测试性**：模块化设计，提供 Mock 接口
- **日志**：统一日志等级，错误可追踪
- **扩展性**：预留跨平台接口

---

## 10. 风险与对策

| 风险 | 对策 |
|------|------|
| 网络波动 | 断点续传、重试机制 |
| 哈希校验失败 | 重新下载、备份回滚 |
| 版本冲突 | 清晰回滚路径、版本标记 |

---

## 11. 里程碑

### 阶段 1 - MVP
- 版本检查
- 简单下载
- 哈希校验
- 启动控制

### 阶段 2 - 模块化
- 接口暴露
- 单元测试
- 日志系统

### 阶段 3 - 扩展
- 跨平台支持
- 多语言本地化
- 更多更新策略

---

## 12. 参考

- 项目配置：project.godot
- 现有脚本：script/version_check.gd, script/PatchManager.gd, script/windows_manager.gd
