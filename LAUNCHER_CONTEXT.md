# ETN 启动器 · 讨论记录与设计笔记

---

## 讨论目标

将设计阶段的 ideation、决策与待解决问题系统化，确保实现时有清晰的路径。

---

## 已确认的决策

### 1. 安装位置
- 启动器：可放任意位置
- 游戏本体：`%LOCALAPPDATA%/ETN/`
- Godot 获取：`OS.get_environment("LOCALAPPDATA") + "/ETN/"`
- 自定义路径：写入注册表 `HKEY_CURRENT_USER\Software\ETN\InstallPath`

### 2. 多游戏支持
- 每个游戏独立 GitHub 仓库
- 每个仓库一个 Release JSON 文件
- Launcher 切换游戏时读取对应 JSON

### 3. 补丁链计算
- 维护：当前版本 + 已应用补丁号
- 判断逻辑：
  - `force_full_update = true` → 全量更新
  - `base_version > 当前版本` → 全量更新
  - 否则 → 计算补丁差值，下载中间补丁

### 4. 强制更新策略
- `force_update`：更新不可跳过
- `force_full_update`：必须全量下载

### 5. 离线模式
- 网络错误时可跳过更新检查
- 正常情况必须检查更新

---

## Release JSON 模板

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

---

## 风险与应对

| 风险 | 对策 |
|------|------|
| 网络波动导致下载失败 | 断点续传、重试策略 |
| 哈希校验不匹配 | 提示重新下载、备份策略 |
| 版本冲突/回滚困难 | 清晰回滚路径、版本标记 |
| 补丁覆盖顺序问题 | 明确加载顺序、幂等性测试 |

---

## 待解决的问题

### 服务器端
- [ ] GitHub Release 命名规范
- [ ] JSON 文件具体命名
- [ ] 错误码定义

### 客户端
- [ ] 补丁覆盖的具体实现
- [ ] 回滚策略的技术实现
- [ ] 日志系统的详细规范

---

## 下一步计划

1. 确定 JSON 文件命名
2. 实现 VersionCheck 模块
3. 实现 PatchDownloader 模块
4. 实现 IntegrityVerifier 模块

---

> 本笔记将随讨论推进持续更新
