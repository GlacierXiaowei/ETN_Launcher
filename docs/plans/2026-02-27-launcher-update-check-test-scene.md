# LauncherUpdateCheck Test Scene Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 记录并固化 `res://scenes/test/launcher_update_check.tscn` 的测试用途、运行方式与验收点，方便后续迭代时快速回归。

**Architecture:** 该测试场景通过 `res://scenes/test/launcher_update_check.gd` 在运行时实例化 `res://component/UpdateManager/install_component.tscn`，等待其发出 `update_needed_state_signal` 后，根据结果展示按钮并触发对应流程（进入/离线进入/下载/重试）。

**Tech Stack:** Godot 4.x, GDScript

---

### Task 1: 明确测试场景定位与入口

**Files:**
- Reference: `res://scenes/test/launcher_update_check.tscn`
- Reference: `res://scenes/test/launcher_update_check.gd`
- Reference: `res://component/UpdateManager/install_component.tscn`

**Step 1: 确认场景用途**

该场景用于验证启动器“更新检查/下载更新/离线进入”的 UI 与触发链路是否正常，属于开发阶段的回归测试入口（不是最终用户界面）。

**Step 2: 确认运行入口**

在 Godot Editor 中运行：
- 方式A：直接打开并运行 `res://scenes/test/launcher_update_check.tscn`
- 方式B：临时将 Project Settings 的 Main Scene 指向 `res://scenes/test/launcher_update_check.tscn`

---

### Task 2: 记录 UI 结构与信号连接

**Files:**
- Reference: `res://scenes/test/launcher_update_check.tscn`

**Step 1: UI 节点结构要点**

场景核心控件：
- `StatusLabel`：显示“正在检查更新...”以及检查结果状态提示
- `UpdateNotes`：显示更新内容（目前可为空）
- `PrimaryButton`：主按钮（进入/下载更新/重试）
- `SecondaryButton`：次按钮（离线进入，或隐藏）
- `LoadingSpinner`：检查中加载动画（显示/隐藏）

**Step 2: 按钮信号连接**

场景文件内已连接：
- `PrimaryButton.pressed -> LauncherUpdateCheck._on_primary_button_pressed`
- `SecondaryButton.pressed -> LauncherUpdateCheck._on_secondary_button_pressed`

验收点：点击按钮必须触发对应脚本函数（可用断点验证）。

---

### Task 3: 记录状态机/按钮策略（基于 update_needed_state_signal）

**Files:**
- Reference: `res://scenes/test/launcher_update_check.gd`
- Reference: `res://component/UpdateManager/install_component.gd`

**Step 1: 检查完成后 UI 切换**

当 `InstallComponent.update_needed_state_signal` 发出时：
- 关闭 loading
- 显示 button_container
- 根据 result 配置按钮文案与 action meta

**Step 2: 约定的 result 值与按钮表现**

当前脚本约定：
- `UP_TO_DATE` -> 主按钮“进入”，无次按钮
- `FULL_UPDATE_REQUIRED` / `NORMAL_UPDATE_REQUIRED` -> 主按钮“下载更新”；非强制更新时显示次按钮“离线进入”
- `ERROR` -> 主按钮“重试”，次按钮“离线进入”

验收点：不同 result 下按钮显示/隐藏/禁用状态正确。

---

### Task 4: 记录“离线进入 / 下载更新 / 重试”的触发链路

**Files:**
- Reference: `res://scenes/test/launcher_update_check.gd`
- Reference: `res://script/managers/scene_manager.gd`
- Reference: `res://component/UpdateManager/install_component.gd`

**Step 1: 离线进入**

触发：`SecondaryButton` action 为 `skip`
- 调用：`SceneManager.switch_scene("res://scenes/main/main_menu.tscn")`

验收点：点击“离线进入”可以切换场景（即便网络不可用）。

**Step 2: 下载更新**

触发：`PrimaryButton` action 为 `download`
- UI：主按钮禁用并改为“下载中...”，次按钮禁用
- 调用：`install_component._on_下载_pressed()`

验收点：点击“下载更新”确实进入下载流程（用断点/日志验证 `_on_下载_pressed` 被调用）。

**Step 3: 重试**

触发：`PrimaryButton` action 为 `retry`
- 行为：释放旧 InstallComponent，重新创建并开始检查

验收点：点击“重试”后能重新进入“正在检查更新...”状态。

---

### Task 5: 回归测试清单（手工）

**Files:**
- Reference: `res://scenes/test/launcher_update_check.tscn`

**Step 1: 最基本回归**

运行场景，观察：
- 初始：显示“正在检查更新...”，按钮区隐藏，Loading 显示
- 完成：Loading 隐藏，按钮区显示

**Step 2: 交互回归**

逐个点击并验证：
- “离线进入”能进入主菜单
- “下载更新”能触发 install_component 的下载入口
- “重试”会重新拉起检查流程

---

### Task 6: 可选（测试加速）- 使用本地 mock cloud_version

**Files:**
- Reference: `res://script/class/check_version/version_utils.gd`

**Step 1: 开启 mock（仅开发测试使用）**

将：
- `VersionUtils.use_mock_cloud_version = true`
- `VersionUtils.mock_cloud_version_path = "res://data/mock_cloud_version.json"`（或你指定的路径）

**Step 2: 预期**

更新检查阶段不再走网络请求，直接读取本地 JSON 并解析为 `UpdatePolicy`，从而稳定复现：
- 强制更新
- 非强制更新
- 无需更新
