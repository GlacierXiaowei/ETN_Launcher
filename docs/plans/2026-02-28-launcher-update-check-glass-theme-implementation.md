# LauncherUpdateCheck 液态玻璃主题实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**目标：** 新增一套可复用的"深色液态玻璃" UI 效果（Shader + 主题工厂），并通过运行时注入的方式应用到 `res://scenes/test/launcher_update_check.gd`（不直接编辑现有 `.tscn` 文本）。

**架构：**
- `liquid_glass_ui.gdshader`：负责玻璃底板（圆角矩形 mask + 边缘折射 + mip blur + rim + 内描边 + 可选色散）。
- `ETNThemeFactory`：负责加载 Theme（若资源不存在则回退到脚本内建主题）并创建玻璃卡片节点。
- `launcher_update_check.gd`：在 `_ready()` 注入主题与玻璃卡片，并在尺寸变化时同步 `rect_size_px`。

**技术栈：** Godot 4.x, GDScript, CanvasItem Shader。

---

### Task 1: 新增液态玻璃 Shader

**Files:**
- Create: `assets/shaders/liquid_glass_ui.gdshader`

**步骤：**
1. 新建 `canvas_item` shader，仅使用 `SCREEN_TEXTURE`。
2. 使用 `rect_size_px` + 圆角矩形 SDF 进行 mask。
3. 边缘增强折射（像素单位），模糊用 `textureLod`。
4. 色散可选：开启时 3 次采样合成 RGB。
5. 增加 rim 高光与内描边。

---

### Task 2: 主题工厂（Theme + GlassCard 创建）

**Files:**
- Create: `script/ui/theme/etn_theme_factory.gd`

**步骤：**
1. `apply_glass_theme(root)`：
   - 若存在 `res://assets/themes/etn_glass_dark.theme.tres` 则加载
   - 否则构建回退 Theme（最少保证按钮/文字有统一观感）
2. `create_glass_card()`：
   - 创建 `ColorRect`，挂 `ShaderMaterial(liquid_glass_ui.gdshader)`
   - 设置一组保守默认参数

---

### Task 3: 在 LauncherUpdateCheck 运行时注入

**Files:**
- Modify: `scenes/test/launcher_update_check.gd`

**步骤：**
1. `_ready()`：应用主题、创建 glass card、再初始化更新检查逻辑。
2. 将 glass card 作为 `CenterContainer` 子节点，放到最底层（index 0）。
3. 监听 `resized`，延迟一帧同步 `rect_size_px` 到 shader。

---

### Task 4: 验证

由于当前环境没有 Godot CLI，这里以"手动验证"为准：
1. 在 Godot 编辑器运行 `LauncherUpdateCheck` 测试场景。
2. 查看输出面板是否有 shader 编译错误。
3. 检查：圆角裁切、边缘高光、按钮层级、屏幕边缘是否有拉丝伪影。
