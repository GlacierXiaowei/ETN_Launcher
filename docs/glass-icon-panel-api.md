# GlassIconPanel API 参考

> 液态玻璃效果圆形/圆角矩形按钮组件 - 支持文本/图标两种模式

**版本：** 1.0  
**最后更新：** 2026-03-06  
**路径：** `res://component/GlassComponent/glass_icon_panel.gd`

---

## 🚀 快速开始

### 30 秒上手

**GlassIconPanel** 是一个基于液态玻璃效果的按钮组件，与 `GlassButton` 类似，但更适合制作**圆形功能按钮**（如关闭按钮、设置按钮等）。

---

### 第一步：创建实例

```gdscript
# 代码创建
var close_btn = GlassIconPanel.new()
close_btn.custom_minimum_size = Vector2(48, 48)
close_btn.corner_radius_px = 24  # 正圆（半径 = 尺寸一半）
add_child(close_btn)
```

---

### 第二步：设置内容

```gdscript
# 模式 1：文本模式（默认）
close_btn.content_type = GlassIconPanel.ContentType.TEXT
close_btn.text = "×"
close_btn.font_size = 20

# 模式 2：图标模式
close_btn.content_type = GlassIconPanel.ContentType.ICON
close_btn.icon = preload("res://assets/icons/close.png")
close_btn.icon_scale = 0.5  # 图标占按钮尺寸的 50%
```

---

### 第三步：连接信号

```gdscript
close_btn.pressed.connect(_on_close_pressed)

func _on_close_pressed() -> void:
    print("关闭按钮被点击")
```

---

### 完整示例

```gdscript
extends Control

func _ready() -> void:
    # 创建圆形关闭按钮
    var close_btn = GlassIconPanel.new()
    close_btn.position = Vector2(752, 20)  # 右上角
    close_btn.custom_minimum_size = Vector2(48, 48)
    close_btn.corner_radius_px = 24  # 正圆
    close_btn.content_type = GlassIconPanel.ContentType.TEXT
    close_btn.text = "×"
    close_btn.font_size = 20
    close_btn.button_type = GlassIconPanel.ButtonType.SECONDARY
    close_btn.pressed.connect(_on_close_pressed)
    add_child(close_btn)

func _on_close_pressed() -> void:
    get_tree().quit()
```

---

## 1. 节点结构

```
GlassIconPanel (Control)
├── GlassBackground (ColorRect + liquid_glass_ui shader)
├── Label / TextureRect (内容，动态创建)
│   ├── Label (TEXT 模式)
│   └── TextureRect (ICON 模式)
└── HitButton (Button - 透明点击区)
```

---

## 2. 导出属性

### 2.1 Content 组

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `content_type` | `ContentType` | `TEXT` | `TEXT`=文本 / `ICON`=图标 |
| `text` | `String` | `"×"` | 文本内容（TEXT 模式） |
| `font_size` | `int` | `20` | 字体大小（TEXT 模式） |
| `icon` | `Texture2D` | `null` | 图标纹理（ICON 模式） |
| `icon_scale` | `float` | `0.5` | 图标缩放比例（相对于按钮尺寸） |

### 2.2 State 组

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `disabled` | `bool` | `false` | 是否禁用（禁用时按钮变灰） |

### 2.3 Button Style 组

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `button_type` | `ButtonType` | `SECONDARY` | `PRIMARY`/`SECONDARY`/`THIRD`（颜色区分） |

### 2.4 Glass Effect 组

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `corner_radius_px` | `float` | `24.0` | 圆角半径（=尺寸一半时为正圆） |

---

## 3. 信号

```gdscript
signal pressed  # 按钮被点击
```

---

## 4. 枚举类型

### ContentType

| 值 | 说明 |
|----|------|
| `TEXT` (0) | 文本模式，显示 `text` 属性 |
| `ICON` (1) | 图标模式，显示 `icon` 属性 |

### ButtonType

| 值 | 说明 | 颜色特征 |
|----|------|----------|
| `PRIMARY` (0) | 主要操作 | 蓝色系 |
| `SECONDARY` (1) | 次要操作 | 灰色系 |
| `THIRD` (2) | 第三选项 | 绿色系 |

---

## 5. 使用示例

### 5.1 圆形关闭按钮（文本模式）

```gdscript
var close_btn = GlassIconPanel.new()
close_btn.custom_minimum_size = Vector2(48, 48)
close_btn.corner_radius_px = 24  # 正圆：半径 = 48/2
close_btn.content_type = GlassIconPanel.ContentType.TEXT
close_btn.text = "×"
close_btn.font_size = 20
close_btn.button_type = GlassIconPanel.ButtonType.SECONDARY
close_btn.pressed.connect(_on_close_pressed)
```

### 5.2 圆形图标按钮（图标模式）

```gdscript
var settings_btn = GlassIconPanel.new()
settings_btn.custom_minimum_size = Vector2(56, 56)
settings_btn.corner_radius_px = 28  # 正圆
settings_btn.content_type = GlassIconPanel.ContentType.ICON
settings_btn.icon = preload("res://assets/icons/settings.png")
settings_btn.icon_scale = 0.5  # 图标占 50%
settings_btn.button_type = GlassIconPanel.ButtonType.PRIMARY
settings_btn.pressed.connect(_on_settings_pressed)
```

### 5.3 圆角矩形按钮

```gdscript
var play_btn = GlassIconPanel.new()
play_btn.custom_minimum_size = Vector2(120, 48)
play_btn.corner_radius_px = 12  # 圆角矩形（非正圆）
play_btn.content_type = GlassIconPanel.ContentType.ICON
play_btn.icon = preload("res://assets/icons/play.png")
play_btn.icon_scale = 0.6
play_btn.button_type = GlassIconPanel.ButtonType.PRIMARY
```

### 5.4 页面指示器（右侧垂直排列）

```gdscript
# 创建 3 个圆形指示器
var indicators: Array[GlassIconPanel] = []

for i in range(3):
    var indicator = GlassIconPanel.new()
    indicator.custom_minimum_size = Vector2(16, 16)
    indicator.corner_radius_px = 8  # 正圆
    indicator.content_type = GlassIconPanel.ContentType.TEXT
    indicator.text = "•"  # 或使用图标
    indicator.font_size = 12
    indicator.button_type = GlassIconPanel.ButtonType.SECONDARY if i != active_page else GlassIconPanel.ButtonType.PRIMARY
    indicator.position = Vector2(0, i * 24)
    indicator.pressed.connect(_on_indicator_pressed.bind(i))
    page_indicator_container.add_child(indicator)
    indicators.append(indicator)

func _on_indicator_pressed(page_index: int) -> void:
    # 跳转到指定页面
    main_menu.switch_to_page(page_index)
```

---

## 6. 常见问题解答

### Q1: 如何制作正圆形按钮？

**答：** 设置 `corner_radius_px = custom_minimum_size.x / 2`

```gdscript
var btn = GlassIconPanel.new()
btn.custom_minimum_size = Vector2(48, 48)
btn.corner_radius_px = 24  # 48/2 = 正圆
```

### Q2: 图标太大/太小怎么办？

**答：** 调整 `icon_scale` 属性（0.0-1.0）

```gdscript
btn.icon_scale = 0.4  # 图标占按钮尺寸的 40%
```

### Q3: 如何禁用按钮？

**答：** 设置 `disabled = true`

```gdscript
btn.disabled = true  # 按钮变灰，不可点击
```

### Q4: 三种按钮类型有什么区别？

**答：** 主要是颜色不同：

| 类型 | 用途 | 颜色 |
|------|------|------|
| `PRIMARY` | 主要操作（确定、启动） | 蓝色系 |
| `SECONDARY` | 次要操作（取消、返回） | 灰色系 |
| `THIRD` | 第三选项（不确定、稍后） | 绿色系 |

### Q5: 可以动态切换文本/图标模式吗？

**答：** 可以，修改 `content_type` 即可

```gdscript
btn.content_type = GlassIconPanel.ContentType.ICON
btn.icon = preload("res://assets/icons/new_icon.png")
# 或切换回文本
btn.content_type = GlassIconPanel.ContentType.TEXT
btn.text = "新文本"
```

---

## 7. 与 GlassButton 的区别

| 特性 | GlassIconPanel | GlassButton |
|------|----------------|-------------|
| 用途 | 圆形功能按钮 | 长条形文本按钮 |
| 尺寸 | 通常正方形 | 通常长方形 |
| 内容 | 单字符/图标 | 多字符文本 |
| 自动大小 | 不支持（手动设置） | 支持（根据文本） |
| 典型尺寸 | 48x48, 56x56 | 140x48, 180x56 |

---

## 8. 性能提示

- GlassIconPanel 使用 `liquid_glass_ui.gdshader`，与普通 GlassButton 相同
- 多个实例共享同一 Shader 资源，不会增加额外开销
- 建议：同一场景中使用相同 `corner_radius_px` 值，保持视觉一致性

---

## 9. 文件列表

| 文件 | 路径 | 说明 |
|------|------|------|
| `glass_icon_panel.gd` | `component/GlassComponent/` | **主脚本** |
| `liquid_glass_ui.gdshader` | `assets/shaders/` | 液态玻璃 Shader |

---

*文档版本：v1.0*  
*最后更新：2026-03-06*
