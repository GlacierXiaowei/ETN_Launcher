# ETN Launcher 玻璃组件设计文档

> **版本**: v1.0  
> **日期**: 2026-02-28  
> **目标**: 基于 liquid_glass_ui.gdshader 创建可复用的弹窗 UI 组件

---

## 1. 概述

本文档定义了一套基于液态玻璃 Shader 的可复用 UI 组件，用于 ETN Launcher 的弹窗系统。

### 1.1 设计目标

- 提供统一的玻璃面板、按钮、文本等组件
- 支持多种尺寸（中弹窗、大弹窗）
- 通过 Shader 参数实现按钮状态变化
- 所有组件可通过导出变量快速调整参数

### 1.2 技术基础

- **Shader**: `res://assets/shaders/liquid_glass_ui.gdshader`
- **位置**: 先在 `scenes/test/glass_components/` 开发，验收后迁移到 `script/component/`

---

## 2. 组件清单

| 组件 | 文件 | 说明 |
|-----|------|-----|
| GlassPanel | glass_panel.gd | 玻璃面板底板 |
| GlassButton | glass_button.gd | 玻璃按钮（主/次） |
| GlassRichText | glass_rich_text.gd | 玻璃背景的富文本 |
| DemoScene | glass_components_demo.tscn | 测试展示场景 |

---

## 3. GlassPanel 组件

### 3.1 节点结构

```
GlassPanel (ColorRect)
└── ShaderMaterial (liquid_glass_ui.gdshader)
```

### 3.2 导出变量

| 变量 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| corner_radius_px | float | 22.0 | 圆角半径 |
| opacity | float | 1.0 | 整体透明度 |
| tint | Color | Shader默认 | 玻璃染色 |
| border_width_px | float | 1.5 | 边框宽度 |
| border_color | Color | Shader默认 | 边框颜色 |
| rim_width_px | float | 14.0 | 边缘高光宽度 |
| rim_intensity | float | 1.0 | 边缘高光强度 |

### 3.3 尺寸变体

| 变体 | 推荐尺寸 (1080p) |
|-----|-----------------|
| Medium (中) | 600 x 400 px |
| Large (大) | 800 x 600 px |

---

## 4. GlassButton 组件

### 4.1 节点结构

```
GlassButton (Button)
├── GlassPanel (ColorRect, 作为底板)
└── Label (按钮文字)
```

### 4.2 导出变量

| 变量 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| button_type | enum | SECONDARY | PRIMARY / SECONDARY |
| size_variant | enum | MEDIUM | MEDIUM / LARGE |
| corner_radius_px | float | 18.0 | 圆角半径 |
| normal_tint | Color | 浅灰色 | 正常状态染色 |
| hover_tint | Color | 亮度+5% | 悬停状态染色 |
| pressed_tint | Color | 亮度-10% | 按下状态染色 |
| disabled_tint | Color | 灰色 | 禁用状态染色 |
| border_width_normal | float | 1.0 | 正常边框 |
| border_width_hover | float | 2.0 | 悬停边框 |
| border_width_pressed | float | 3.0 | 按下边框 |
| border_width_disabled | float | 0.5 | 禁用边框 |

### 4.3 按钮状态与 Shader 参数

| 状态 | opacity | tint | border_width_px |
|-----|---------|------|-----------------|
| Normal | 1.0 | normal_tint | 1.0 |
| Hover | 1.0 | hover_tint | 2.0 |
| Pressed | 1.0 | pressed_tint | 3.0 |
| Disabled | 0.95 | disabled_tint | 0.5 |

### 4.4 主次按钮区别

- **主按钮 (Primary)**: tint 偏青蓝色 `Color(0.85, 0.92, 1.0, 0.35)`
- **次按钮 (Secondary)**: tint 偏灰色 `Color(0.95, 0.95, 0.98, 0.35)`

### 4.5 尺寸变体

| 变体 | 推荐尺寸 | 适用场景 |
|-----|---------|---------|
| Medium | 120 x 40 px | 中弹窗、大弹窗 |
| Large | 160 x 50 px | 主菜单、大按钮需求 |

---

## 5. GlassRichText 组件

### 5.1 节点结构

```
GlassRichText (RichTextLabel)
└── (无额外底板，文字直接显示)
```

### 5.2 导出变量

| 变量 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| text | String | "" | 显示文本 |
| panel_bg | bool | false | 是否显示面板背景 |

---

## 6. 测试场景设计

### 6.1 场景结构

```
glass_components_demo (Control)
├── Background (TextureRect, 背景图)
├── CenterContainer
│   ├── MediumPopup (GlassPanel, 中弹窗)
│   │   ├── Title (Label)
│   │   ├── Content (GlassRichText)
│   │   └── ButtonRow (HBoxContainer)
│   │       ├── SecondaryButton (GlassButton)
│   │       └── PrimaryButton (GlassButton)
│   └── LargePopup (GlassPanel, 大弹窗)
│       ├── Title (Label)
│       ├── Content (GlassRichText, 长文本)
│       └── ButtonRow
│           ├── SecondaryButton (GlassButton)
│           └── PrimaryButton (GlassButton)
└── ButtonSizes (VBoxContainer)
    ├── MediumButton (GlassButton, size=MEDIUM)
    └── LargeButton (GlassButton, size=LARGE)
```

### 6.2 交互演示

- 按钮各状态（Normal/Hover/Pressed/Disabled）
- 面板尺寸对比
- 按钮尺寸对比

---

## 7. 验收标准

1. ✅ 中弹窗在 1920x1080 分辨率下显示正常
2. ✅ 大弹窗在 1920x1080 分辨率下显示正常
3. ✅ 主/次按钮视觉区分明显
4. ✅ 按钮四种状态切换流畅
5. ✅ 组件导出变量可正常调整
6. ✅ 测试场景可独立运行

---

## 8. 后续扩展

- 进度条组件
- 开关组件
- 输入框组件
- 滑块组件

---

*文档版本: v1.0*
