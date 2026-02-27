# ETN Launcher 开发进度总结

> 最后更新: 2026-02-27

---

## 当前阶段

Phase 2: 场景框架搭建 - 进行中
Phase 3: 逐个场景实现 - 进行中

---

## 已完成

### 1. 基础框架 (Phase 1)
- [x] 创建项目目录结构
- [x] 配置 AutoLoad 单例
  - SceneManager
  - PopupManager
  - GameState
  - VersionUtils

### 2. 开屏场景 (SplashScreen)
- [x] 场景: `scenes/boot_scene/splash_screen.tscn`
- [x] 脚本: `scenes/boot_scene/splash_screen.gd`
- [x] Logo: `assets/image/boot_logo/logo_01.png`, `logo_02.png`
- [x] 动画: 硬切切换，每张1.5秒
- **TODO**: 连接 InstallComponent 信号，根据结果决定下一步

### 3. 启动器更新检查场景 (LauncherUpdateCheck)
- [x] 场景: `scenes/test/launcher_update_check.tscn`
- [x] 脚本: `scenes/test/launcher_update_check.gd`
- 功能:
  - [x] 检查中显示"请稍候"
  - [x] 根据结果动态生成按钮
  - [x] 支持重试
  - [x] 离线进入功能
- 按钮状态:
  - UP_TO_DATE: "进入"
  - FULL_UPDATE_REQUIRED / NORMAL_UPDATE_REQUIRED: "下载更新" + "离线进入"(可选)
  - ERROR: "重试" + "离线进入"

### 4. InstallComponent 修改
- [x] 添加 `is_force_update` 变量
- [x] 添加 `_on_下载_pressed()` 函数
- [x] 修复 `user_path` 在 `_ready()` 中重新计算

### 5. VersionUtils 修改
- [x] 超时从 2.5秒 改为 10秒
- [x] 添加 User-Agent 请求头
- [x] 错误信息改为显示 response_code

---

## 待完成

### 1. 开屏场景完善
- [ ] 连接 InstallComponent 信号
- [ ] 根据更新检查结果切换场景

### 2. 启动器更新检查完善
- [ ] 修复网络请求问题（可能是代理/网络问题）
- [ ] 测试下载功能

### 3. 主菜单场景
- [ ] 创建 `scenes/main/main_menu.tscn`
- [ ] 页面切换（鼠标滚轮）
- [ ] 页面指示器

### 4. 游戏卡面组件
- [ ] 创建 `component/game_card.tscn`
- [ ] 悬停效果
- [ ] 状态机集成

### 5. 弹窗系统
- [ ] 创建 `scenes/main/global_popup.tscn`
- [ ] 动态内容填充

---

## 已创建文件列表

```
scenes/
├── boot_scene/
│   ├── splash_screen.tscn
│   └── splash_screen.gd
├── test/
│   ├── launcher_update_check.tscn
│   └── launcher_update_check.gd
└── main/ (待创建)

script/
└── managers/
    ├── scene_manager.gd
    ├── popup_manager.gd
    └── game_state.gd
```

---

## 已知问题

1. **GitHub 网络访问失败**
   - 错误码: 0 (网络不通)
   - 可能原因: 代理未开启 / 网络被墙
   - 建议: 检查代理配置

2. **repo_name 未生效** (已修复)
   - 原因: user_path 在脚本加载时计算，未随 repo_name 更新
   - 修复: 在 _ready() 中重新计算 user_path

---

## 文档位置

- 主设计文档: `docs/项目设计与实践指南.md`
- 计划文档: `docs/plans/`
