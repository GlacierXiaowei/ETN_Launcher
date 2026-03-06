# 主菜单场景设计方案

> ETN Launcher 主菜单场景完整设计文档

**版本：** 1.0  
**日期：** 2026-03-06  
**状态：** 待实现

---

## 1. 概述

### 1.1 设计目标

实现一个具有专业视觉效果的游戏选择主菜单，支持：
- 鼠标滚轮翻页切换
- 流畅的双卡面滑动动画
- 动态背景过渡效果
- 可扩展的多游戏支持（2→3→N）

### 1.2 核心特性

| 特性 | 说明 |
|------|------|
| 翻页方式 | 鼠标滚轮（上下滚动） |
| 动画风格 | 双卡面滑动 + 背景缩放模糊 |
| 页面指示 | 右侧垂直排列圆形按钮（GlassIconPanel） |
| 延迟反馈 | 0.25s 顿挫感（先悬停再滑动） |
| 滚轮锁 | 布尔变量控制（弹窗/设置页打开时禁止） |

---

## 2. 场景架构

### 2.1 节点层级

```
MainMenu (Control)
├── BackgroundContainer (Node2D)
│   ├── Background1 (TextureRect + background_blur.gdshader)
│   └── Background2 (TextureRect + background_blur.gdshader)
├── PageContainer (Node2D)
│   ├── CardPanel1 (Control) - 第 1 页
│   ├── CardPanel2 (Control) - 第 2 页
│   └── CardPanel3 (Control) - 第 3 页
├── PageIndicatorContainer (VBoxContainer)
│   ├── Indicator1 (GlassIconPanel)
│   ├── Indicator2 (GlassIconPanel)
│   └── Indicator3 (GlassIconPanel)
├── TopShadowArc (TextureRect)
├── BottomShadowArc (TextureRect)
├── GameTitle (Label)
└── StatusLabel (Label)
```

### 2.2 关键设计决策

| 决策 | 说明 |
|------|------|
| **背景独立于 CardPanel** | 背景放在主菜单场景下，不做 Y 轴滑动，只做缩放 + 模糊过渡 |
| **CardPanel 预布局** | 所有 CardPanel 预先排好 Y 轴位置，跨页时中间页快速穿过 |
| **右侧指示器** | 垂直排列，使用 GlassIconPanel，可点击跳转任意页 |
| **滚轮监听全局** | 整个 MainMenu 监听 `_input()`，不区分区域 |

---

## 3. 翻页动画设计

### 3.1 时间轴

```
T=0.00s  : 检测到滚轮 → 设置 is_hover=true（卡片悬停效果）
T=0.25s  : 延迟结束 → 开始翻页动画
T=0.25-0.55s : 当前页滑出（EASE_IN，前慢后快）
T=0.25-0.55s : 目标页滑入（EASE_OUT，前快后慢）
T=0.25-0.40s : 中间页快速穿过（LINEAR，跨页时）
T=0.55s  : 动画完成 → is_hover=false
```

### 3.2 卡片预布局位置

以 1080p 垂直分辨率为例：

```
初始状态（第 1 页为当前页）：
CardPanel1 Y = 0         (当前显示)
CardPanel2 Y = +1080     (屏幕下方)
CardPanel3 Y = +2160     (更下方)

第 2 页为当前页：
CardPanel1 Y = -1080     (屏幕上方)
CardPanel2 Y = 0         (当前显示)
CardPanel3 Y = +1080     (屏幕下方)

第 3 页为当前页：
CardPanel1 Y = -2160     (更上方)
CardPanel2 Y = -1080     (屏幕上方)
CardPanel3 Y = 0         (当前显示)
```

### 3.3 跨页动画处理（第 1 页 → 第 3 页）

| CardPanel | 起始 Y | 目标 Y | 时长 | 缓动 |
|-----------|--------|--------|------|------|
| CardPanel1 | 0 | -1080 | 0.3s | EASE_IN |
| CardPanel2 | +1080 | -1080 | 0.15s | LINEAR |
| CardPanel3 | +2160 | 0 | 0.3s | EASE_OUT |

**中间页（CardPanel2）快速穿过，产生视觉连贯性。**

### 3.4 Tween 缓动配置

```gdscript
# 滑出动画（当前页向上）
tween.tween_property(card, "position:y", target_y, 0.3)\
    .set_trans(Tween.TRANS_CUBIC)\
    .set_ease(Tween.EASE_IN)

# 滑入动画（目标页向上）
tween.tween_property(card, "position:y", 0, 0.3)\
    .set_trans(Tween.TRANS_CUBIC)\
    .set_ease(Tween.EASE_OUT)

# 中间页（跨页时）
tween.tween_property(mid_card, "position:y", target_y, 0.15)\
    .set_trans(Tween.TRANS_LINEAR)\
    .set_ease(Tween.EASE_IN)
```

---

## 4. 背景过渡设计（方案 D+A 结合）

### 4.1 效果描述

- **背景不滑动**，保持在原地
- 翻页时背景做**缩放 + 模糊联动**（呼吸感）
- 跨页时过渡强度×1.5

### 4.2 动画参数

| 阶段 | 缩放 | 模糊强度 | 时长 |
|------|------|----------|------|
| 初始 | 1.0 | 2.0 | - |
| 过渡峰值 | 1.1 | 5.0 | 0.15s |
| 恢复 | 1.0 | 2.0 | 0.15s |

### 4.3 跨页强度修正

```gdscript
var page_distance = abs(target_page - current_page)
var intensity_multiplier = 1.0 + (page_distance - 1) * 0.5

# 跨 2 页时：blur = 5.0 * 1.5 = 7.5
# 跨 1 页时：blur = 5.0 * 1.0 = 5.0
```

### 4.4 双背景切换策略

使用两个背景TextureRect，在背景过渡峰值时切换纹理：

```
帧 1-15 (0.0-0.15s): Background1 可见，模糊从 2.0→5.0
帧 16   (0.15s):     切换 Background2 的纹理为新页面海报
帧 17-30(0.15-0.3s): Background2 可见，模糊从 5.0→2.0
```

---

## 5. 滚轮锁设计

### 5.1 变量定义

```gdscript
# 在 MainMenu 脚本中
var page_turn_enabled: bool = true  # 外部可控制
var is_animating: bool = false      # 内部动画锁
```

### 5.2 检测方法

```gdscript
func _input(event: InputEvent) -> void:
    if not page_turn_enabled:
        return
    if is_animating:
        return
    
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _try_page_turn(-1)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _try_page_turn(1)
```

### 5.3 使用场景

| 场景 | 设置 |
|------|------|
| 弹窗打开时 | `page_turn_enabled = false` |
| 设置页打开时 | `page_turn_enabled = false` |
| 动画进行中 | `is_animating = true`（自动） |
| 正常状态 | 两者都为 `true` |

---

## 6. 页面指示器设计

### 6.1 布局

- **位置**：右侧垂直居中排列
- **间距**：24px
- **尺寸**：16x16（正圆）
- **内容**：文本"•"或图标

### 6.2 状态

| 状态 | button_type | 说明 |
|------|-------------|------|
| 当前页 | PRIMARY | 高亮（蓝色） |
| 其他页 | SECONDARY | 普通（灰色） |

### 6.3 点击跳转

```gdscript
func _on_indicator_pressed(page_index: int) -> void:
    if page_index == current_page:
        return
    # 直接跳转到指定页面（触发完整动画）
    switch_to_page(page_index)
```

---

## 7. 可扩展性设计

### 7.1 游戏配置数组

```gdscript
var game_configs: Array[Dictionary] = [
    {"name": "ETN_Farm", "poster": "res://assets/games/farm_poster.jpg"},
    {"name": "ETN_Adventure", "poster": "res://assets/games/adventure_poster.jpg"},
    # 未来添加...
]
```

### 7.2 动态生成 CardPanel

```gdscript
func _build_card_panels() -> void:
    for i in range(game_configs.size()):
        var panel = preload("res://scenes/main_menu/card_panel.tscn").instantiate()
        panel.name = "CardPanel%d" % (i + 1)
        panel.position = Vector2(0, i * 1080)
        page_container.add_child(panel)
```

### 7.3 动态生成指示器

```gdscript
func _build_indicators() -> void:
    for i in range(game_configs.size()):
        var indicator = GlassIconPanel.new()
        indicator.custom_minimum_size = Vector2(16, 16)
        indicator.corner_radius_px = 8
        # ...配置
        page_indicator_container.add_child(indicator)
```

---

## 8. 可调参数汇总

以下参数暴露在 `MainMenu` 脚本顶部，方便调整：

```gdscript
# 动画时序
@export var HOVER_DELAY: float = 0.25  # 滚轮延迟
@export var SLIDE_DURATION: float = 0.3  # 滑动动画时长
@export var MID_PAGE_DURATION: float = 0.15  # 中间页穿过时长

# 背景过渡
@export var BACKGROUND_SCALE_PEAK: float = 1.1  # 缩放峰值
@export var BACKGROUND_BLUR_BASE: float = 2.0  # 基础模糊
@export var BACKGROUND_BLUR_PEAK: float = 5.0  # 峰值模糊
@export var CROSS_PAGE_INTENSITY: float = 1.5  # 跨页强度倍率

# 页面指示器
@export var INDICATOR_SIZE: float = 16.0
@export var INDICATOR_SPACING: float = 24.0

# 卡片位置
@export var PAGE_HEIGHT: float = 1080.0  # 页面垂直间距
```

---

## 9. 文件列表

| 文件 | 路径 | 说明 |
|------|------|------|
| `main_menu.gd` | `scenes/main_menu/` | 主菜单脚本 |
| `main_menu.tscn` | `scenes/main_menu/` | 主菜单场景 |
| `card_panel.tscn` | `scenes/main_menu/` | 卡片面板场景 |
| `background_blur.gdshader` | `assets/shaders/` | 背景模糊 Shader |

---

## 10. 实现检查清单

- [ ] 创建 MainMenu 场景框架
- [ ] 实现滚轮检测 + 延迟逻辑
- [ ] 实现双卡面滑动动画（含跨页处理）
- [ ] 实现背景缩放 + 模糊过渡
- [ ] 实现双背景切换逻辑
- [ ] 实现页面指示器（GlassIconPanel）
- [ ] 实现滚轮锁变量
- [ ] 暴露可调参数
- [ ] 测试 2 页/3 页场景
- [ ] 性能优化

---

*文档版本：v1.0*  
*创建日期：2026-03-06*
