# Glass Components API指南

> 玻璃面板和按钮组件的完整使用说明

---

##目录

1. [GlassPanel -玻璃面板](#glasspanel)
2. [GlassButton -玻璃按钮](#glassbutton)
3. [颜色调试指南](#颜色调试指南)
4. [常见问题](#常见问题)

---

## GlassPanel

### 概述

基于 `ColorRect`的玻璃效果面板，用于弹窗底板。

### 导出变量

#### 基础参数

|变量名 |类型 |默认值 |说明 |
|-------|------|--------|------|
| `corner_radius_px` | float |22.0 |圆角半径（像素） |
| `opacity` | float |1.0 |整体不透明度 |
| `tint` | Color | (0.80,0.90,1.00,0.35) |染色颜色和强度 |

####边框参数
|变量名 |类型 |默认值 |说明 |
|-------|------|--------|------|
| `border_width_px` | float |1.5 |内描边宽度 |
| `border_color` | Color | (1.0,1.0,1.0,0.18) |边框颜色 |

####边缘高光参数
|变量名 |类型 |默认值 |说明 |
|-------|------|--------|------|
| `rim_width_px` | float |14.0 |边缘高光宽度 |
| `rim_intensity` | float |1.0 |高光强度 |
| `rim_color` | Color | (1.0,1.0,1.0,0.45) |高光颜色 |

####尺寸设置
|变量名 |类型 |默认值 |说明 |
|-------|------|--------|------|
| `medium_size` | Vector2 | (600,400) |中等弹窗尺寸 |
| `large_size` | Vector2 | (800,600) |大弹窗尺寸 |
| `size_variant` | enum | MEDIUM |尺寸变体 (MEDIUM/LARGE) |

###使用示例

```gdscript
#代码创建面板
var panel = GlassPanel.new()
panel.size_variant = GlassPanel.SizeVariant.MEDIUM #或 LARGE
panel.corner_radius_px =28.0
panel.tint = Color(0.9,0.95,1.0,0.4)
add_child(panel)

#调整已有面板
$MyPanel.border_width_px =2.0
$MyPanel.opacity =0.9
```

---

## GlassButton

###概述
自定义 Control实现的玻璃效果按钮，支持主次类型和多状态切换。

###导出变量

####内容
|变量名 |类型 |默认值 |说明 |
|-------|------|--------|------|
| `text` | String | "Button" |按钮文字 |

####状态
|变量名 |类型 |默认值 |说明 |
|-------|------|--------|------|
| `disabled` | bool | false |是否禁用 |

####按钮样式
|变量名 |类型 |默认值 |说明 |
|-------|------|--------|------|
| `button_type` | enum | SECONDARY |按钮类型 (PRIMARY/SECONDARY) |
| `size_variant` | enum | MEDIUM |尺寸变体 (MEDIUM/LARGE) |

####边框宽度（各状态）
|变量名 |类型 |默认值 |说明 |
|-------|------|--------|------|
| `border_width_normal` | float |1.0 |正常状态边框 |
| `border_width_hover` | float |2.0 |悬停状态边框 |
| `border_width_pressed` | float |3.0 |按下状态边框 |
| `border_width_disabled` | float |0.5 |禁用状态边框 |

#### Tint颜色（各状态）

| 变量名            | 类型    | 默认值                   | 说明  |
| -------------- | ----- | --------------------- | --- |
| `normal_tint`  | Color | (0.95,0.95,0.98,0.35) | 正常状态|
| `hover_tint`   | Color | (0.98,0.98,1.0,0.38)  | 悬停状态|
| `pressed_tint` | Color | (0.85,0.88,0.92,0.40) | 按下状态|
| `disabled_tint`| Color | (0.60,0.60,0.65,0.25) | 禁用状态|

####圆角
|变量名 |类型 |默认值 |说明 |
|-------|------|--------|------|
| `corner_radius_px` | float |18.0 |圆角半径 |

###信号

```gdscript
signal pressed #按钮被点击时触发
```

###使用示例

```gdscript
#创建主按钮
var primary_btn = GlassButton.new()
primary_btn.text = "确定"
primary_btn.button_type = GlassButton.ButtonType.PRIMARY
primary_btn.size_variant = GlassButton.SizeVariant.LARGE
primary_btn.pressed.connect(_on_confirm)
add_child(primary_btn)

#创建次按钮
var secondary_btn = GlassButton.new()
secondary_btn.text = "取消"
secondary_btn.button_type = GlassButton.ButtonType.SECONDARY
secondary_btn.disabled = true #禁用状态
add_child(secondary_btn)
```

---

##颜色调试指南

###如何增强状态对比度

当前颜色对比不明显，可以通过以下方式增强：

####方案1：增大 RGB差异

```gdscript
#主按钮 -更强的蓝色
normal_tint = Color(0.70,0.85,1.0,0.50) #更蓝更深
hover_tint = Color(0.80,0.92,1.0,0.55) #亮一点
pressed_tint = Color(0.55,0.75,0.95,0.60) #深蓝

#次按钮 -更强的灰色
normal_tint = Color(0.75,0.75,0.82,0.50) #深灰
hover_tint = Color(0.88,0.88,0.92,0.55) #亮灰
pressed_tint = Color(0.60,0.60,0.68,0.58) #深灰
```

####方案2：增大 Alpha差异（染色强度）

```gdscript
normal_tint.a =0.50 #更强的染色
hover_tint.a =0.60
pressed_tint.a =0.70
```

####方案3：增大边框差异

```gdscript
border_width_normal =1.0
border_width_hover =3.0 #更明显
border_width_pressed =5.0 #非常粗
```

###实时调试方法

在 Godot编辑器中：
1.运行场景
2.选中要调试的按钮
3.在 Remote面板中找到该节点
4.修改 Inspector中的 tint值，观察实时变化

---

##常见问题

### Q:按钮显示为白色方块，没有玻璃效果

**A**:检查：
-节点类型是否为 `Control`（不是 `Button`）
-脚本是否正确附加

- shader路径是否正确 `res://assets/shaders/liquid_glass_ui.gdshader`

### Q:文字不显示

**A**:检查 `text`属性是否设置，字体大小是否太小

### Q:点击没反应

**A**:检查 `disabled`是否为 true，或是否有其他节点遮挡

### Q:颜色太淡/太深

**A**:调整 tint的 alpha值（第4个分量），范围0.0-1.0

---

##文件位置

```
scenes/test/glass_components/
├── glass_panel.gd #面板脚本
├── glass_button.gd #按钮脚本
└── glass_components_demo.tscn #测试场景
```

---

*最后更新:2026-02-28*

---

## PopupManager

> 位于 `res://script/managers/popup_manager.gd`，通常以 AutoLoad 单例方式使用。

### show_popup(config: Dictionary) -> void

显示一个全局弹窗。

常用字段：
- `size`: `"medium" | "large"`
- `title`: 标题文本
- `content_type`: `"label" | "richtext"`
- `content`: 内容文本（label 或 richtext 的文本）
- `buttons`: Array[Dictionary]
  - `text`: 按钮文案
  - `type`: `"primary" | "secondary" | "third"`
  - `metadata`: 业务标识
  - `stay_open`: 是否保持弹窗不关闭
  - `disabled`: 是否禁用按钮

### show_confirm(...)

```gdscript
PopupManager.show_confirm(
  "删除存档",
  "确定要删除这个存档吗？",
  func(): _delete_save(),
  func(): print("用户取消")
)
```

注意：该快捷方法内部使用一次性回调，不会在多次调用后累积触发。

### show_alert(...)

```gdscript
PopupManager.show_alert(
  "保存成功",
  "您的游戏进度已保存。",
  func(): _return_to_menu()
)
```

### show_loading(title := "请稍候", label_text := "请稍候...", use_fade := true)

进入 loading/等待态：
- 若当前有弹窗：保存快照，替换按钮为一个 disabled 的“请稍候...”按钮；不修改 richtext 内容。
- 若当前无弹窗：自动创建一个等待弹窗作为载体。

### hide_loading(restore_config := {}, use_fade := true)

退出 loading/等待态：
- `restore_config` 非空：用该配置更新当前弹窗（常用于“操作完成”进入下一步）。
- `restore_config` 为空：恢复 show_loading 前保存的快照。
