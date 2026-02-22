# ETN 启动器 · 设计文档

---

## 设计目标

构建结构清晰、可维护、具专业感的启动器体系，支持：
- 热更新补丁下载
- 版本校验
- 完整性校验
- 多游戏管理

---

## 核心设计原则

1. 不追求过度 DRM，强调秩序与一致性
2. 结构清晰、可测试、可扩展
3. 内容更新与程序更新分离
4. 系统信任与品牌信任分离

---

## 已确认的决策

### 1. 安装位置

| 组件 | 位置 |
|------|------|
| 启动器 | 任意位置（如 `C:\Program Files\ETN Launcher\`） |
| 游戏本体 | `%LOCALAPPDATA%/ETN/` |

**Godot 获取方式**：
```gdscript
var game_dir = OS.get_environment("LOCALAPPDATA") + "/ETN/"
```

**自定义路径**：
- 首次启动时用户选择
- 写入注册表：`HKEY_CURRENT_USER\Software\ETN\InstallPath`

---

### 2. 多游戏支持

- 每个游戏独立 GitHub 仓库
- 每个仓库一个 Release JSON 文件
- Launcher 切换游戏时读取对应 JSON
- 默认选中 ETN (Embodied Now)

---

### 3. 补丁链计算

**维护状态**：
- 当前版本 (version)
- 已应用补丁号 (installed_patch)

**计算逻辑**：
```
当前补丁号 = 1
目标补丁号 = 5
需要下载 = patch_002, patch_003, patch_004, patch_005
```

**边界条件**：
- `force_full_update = true` → 全量更新
- `base_version > 当前版本` → 全量更新
- 否则 → 计算补丁差值

---

### 4. 强制更新策略

| 字段 | 含义 |
|------|------|
| force_update | 更新不可跳过，必须执行 |
| force_full_update | 必须全量下载完整包 |

**使用场景**：
- 功能更新 → `force_update = false`（可跳过）
- 重要修复 → `force_update = true`（不可跳过）
- 大版本更新 → `force_full_update = true`（全量更新）

---

### 5. 离线模式

- 网络错误时可跳过更新检查
- 正常情况必须检查更新
- 作为后门功能存在

---

## 文件结构设计

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

## 模块设计

### LauncherCore
启动器核心流程控制

### VersionCheck
版本检查服务

### PatchDownloader
补丁下载服务

### PatchManager
补丁管理与覆盖逻辑

### IntegrityVerifier
完整性校验（SHA-256）

### WindowsManager
窗口管理与生命周期

### Utils
通用工具与日志

---

## 数据契约

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

| 字段 | 类型 | 说明 |
|------|------|------|
| game_id | string | 游戏标识 |
| version | string | 目标版本号 |
| base_version | string | 最低基础版本 |
| force_update | bool | 是否强制更新 |
| force_full_update | bool | 是否强制全量更新 |
| install_path | string | 安装路径 |
| full_package | object | 完整包信息 |
| patches | array | 补丁列表 |
| release_date | string | 发布日期 |
| notes | string | 更新说明 |

### 补丁字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| patch_number | int | 补丁序号 |
| name | string | 补丁文件名 |
| type | string | 文件类型（PCK/ZIP） |
| hash | string | SHA-256 哈希 |
| url | string | 下载链接 |
| size | int | 文件大小（字节） |
| applies_from | string | 适用起始版本 |
| applies_to | string | 适用目标版本 |

---

## 更新流程设计

### 启动器更新
1. 启动 launcher.exe
2. 检查自身版本
3. 若需更新 → 下载 → 重启
4. 进入主界面

### 游戏更新
1. 用户选择游戏
2. 读取本地 version.json
3. 获取服务器 Release JSON
4. 判断更新类型
5. 执行更新
6. 启动游戏

### 更新类型判断流程

```
开始
  ↓
force_full_update == true?
  ├─ 是 → 全量更新
  └─ 否 ↓
base_version > 当前版本?
  ├─ 是 → 全量更新
  └─ 否 → 补丁更新
```

---

## 完整性校验设计

- **算法**：SHA-256
- **校验对象**：ETN.exe, ETN.pck, patch_xxx.pck
- **校验时机**：下载完成后、启动游戏前

### 异常处理

| 异常 | 处理 |
|------|------|
| 哈希不匹配 | 提示重新下载 |
| 文件缺失 | 强制更新 |

---

## 风险与对策

| 风险 | 对策 |
|------|------|
| 网络波动 | 断点续传、重试机制 |
| 哈希校验失败 | 重新下载、备份回滚 |
| 版本冲突 | 清晰回滚路径、版本标记 |
| 补丁覆盖顺序问题 | 明确加载顺序、幂等性测试 |

---

## 待解决问题

### 服务器端
- [ ] GitHub Release 命名规范
- [ ] JSON 文件具体命名
- [ ] 错误码定义

### 客户端
- [ ] 补丁覆盖的具体实现
- [ ] 回滚策略的技术实现
- [ ] 日志系统的详细规范

---

## 里程碑

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

## 参考资源

- 项目配置：project.godot
- 现有脚本：script/version_check.gd, script/PatchManager.gd, script/windows_manager.gd
