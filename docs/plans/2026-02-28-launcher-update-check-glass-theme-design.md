# LauncherUpdateCheck 液态玻璃主题设计

**目标：** 为测试场景 `LauncherUpdateCheck` 提供一套高质量的深色"液态玻璃"视觉风格（磨砂玻璃卡片 + 统一的字体/按钮层级），并尽量可复用到后续的弹窗/对话框 UI。

**约束 / 非目标：**
- 不直接修改仓库中现有的 `.tscn` 文本文件（场景改动由用户在 Godot 编辑器中完成）。
- 玻璃效果需要性能可控：以"单个弹窗卡片"为主要使用场景。
- 优先沉淀可复用资源（`.gdshader`、Theme/脚本）而不是每个场景写一套。

---

## 视觉方向

### 基调
- 深色背景氛围 + 居中的磨砂玻璃卡片。
- 卡片具有"透镜感"：边缘轻微折射、整体轻微模糊、边缘高光清晰但不刺眼。
- 色散（RGB 分离）可选，默认关闭或极低（避免花、避免晕）。

### 字体与层级
- 使用项目已有字体（默认建议 `res://assets/fonts/unifont-16.0.02.otf`）。
- 层级建议：
  - `StatusLabel` 24-28（更醒目）
  - `UpdateNotes` 14-16（更柔和）
  - 按钮 16-18

### 按钮
- 主按钮：填充强调色（冷色系），圆角、对比强。
- 次按钮：玻璃描边/更低对比。
- 禁用：对比降低但保持可读。

---

## 组件设计

### 玻璃卡片（核心）

玻璃卡片是一个独立的 UI 节点（推荐 `ColorRect`），挂载 ShaderMaterial。
它放在现有 `CenterContainer/VBoxContainer` 内容的后面作为底板。

**玻璃 Shader 需要包含：**
1) **模糊：** 基于 `SCREEN_TEXTURE` 的 mip blur（`textureLod`）
2) **折射：** 程序生成位移（不依赖 displacement map），边缘更强
3) **边缘高光：** 用 SDF 距离带做 rim
4) **描边：** 内描边
5) **染色/透明度：** tint 与 opacity 解耦
6) **可选色散：** 开启时 3 次采样合成 RGB

### 背景氛围

玻璃的折射/模糊需要"背后有东西"才明显。若场景中存在背景氛围层（如 `BackGround`），建议在运行时打开。

---

## 技术落地（不改 `.tscn` 文本）

### 新增资源
- Shader：`res://assets/shaders/liquid_glass_ui.gdshader`
- 主题工厂：`res://script/ui/theme/etn_theme_factory.gd`

### 场景接入
- 在 `res://scenes/test/launcher_update_check.gd`：
  - `_ready()` 时注入 Theme（若后续你在编辑器创建了主题资源 `res://assets/themes/etn_glass_dark.theme.tres`，会优先加载）
  - 运行时创建 GlassCard 并插到 `CenterContainer` 下面
  - 将 GlassCard 的 `size` 同步到 shader uniform `rect_size_px`

---

## 验收标准
- 场景启动后出现居中的磨砂玻璃卡片（圆角、边缘高光、内描边）。
- 按钮主次层级明显。
- 折射在边缘更明显，但整体不晃眼。
- 无明显采样越界伪影（屏幕边缘"拉丝"）。
