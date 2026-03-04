# Shader API 参考

> 全局 Shader 效果系统

**实用提示：**
- 多数场景直接用代码动态创建 ColorRect 并应用 Shader Material
- ColorRect 默认会吸收输入事件，需注意层级管理
- 使用 `set_anchors_preset(Control.PRESET_FULL_RECT)` 覆盖父节点

---

## 1. Shader 文件列表

| Shader | 用途 | 推荐强度范围 |
|--------|------|--------------|
| `background_blur.gdshader` | 背景模糊效果 | 2.0-4.0 |
| `dissolve.gdshader` | 溶解/消融效果 | 0.0-1.0 |
| `transition_blur.gdshader` | 过渡模糊（支持圆角） | 0.0-10.0 |

---

## 2. 使用场景

### 场景 A：目标节点没有 ColorRect

需要新创建 ColorRect 并添加 Shader Material。

#### 基础创建流程

```gdscript
func create_blur_overlay(parent: Control, shader_path: String) -> ColorRect:
    # 1. 创建 ColorRect
    var overlay := ColorRect.new()
    overlay.name = "BlurOverlay"
    overlay.color = Color.TRANSPARENT
    
    # 2. 设置定位：覆盖父节点
    overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    overlay.offset_left = 0
    overlay.offset_right = 0
    overlay.offset_top = 0
    overlay.offset_bottom = 0
    
    # 3. 应用 Shader Material
    overlay.material = ShaderMaterial.new()
    overlay.material.shader = preload(shader_path)
    
    # 4. 添加到父节点
    parent.add_child(overlay)
    
    return overlay
```

#### 完整示例：创建全屏模糊过渡

```gdscript
extends Node

var blur_overlay: ColorRect

func transition_with_blur(duration: float = 0.5) -> void:
    # 创建全屏模糊层
    blur_overlay = ColorRect.new()
    blur_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    blur_overlay.color = Color.TRANSPARENT
    
    # 应用 transition_blur shader
    blur_overlay.material = ShaderMaterial.new()
    blur_overlay.material.shader = preload("res://assets/shaders/transition_blur.gdshader")
    
    # 如果需要圆角效果，设置 rect_size_px
    # blur_overlay.material.set_shader_parameter("rect_size_px", Vector2(600, 400))
    # blur_overlay.material.set_shader_parameter("corner_radius_px", 24.0)
    
    # 添加到场景根节点
    get_tree().root.add_child(blur_overlay)
    
    # 动画：从清晰到模糊
    var tween := create_tween()
    tween.tween_method(
        func(value): blur_overlay.material.set_shader_parameter("blur_amount", value),
        0.0,
        5.0,
        duration / 2
    )
    
    await tween.finished
    
    # 执行场景切换逻辑...
    
    # 动画：从模糊到清晰
    tween = create_tween()
    tween.tween_method(
        func(value): blur_overlay.material.set_shader_parameter("blur_amount", value),
        5.0,
        0.0,
        duration / 2
    )
    
    await tween.finished
    blur_overlay.queue_free()
```

#### 设置定位的几种方式

```gdscript
# 方式 1：覆盖父节点（最常用）
color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)

# 方式 2：覆盖同级节点（需手动设置锚点）
color_rect.anchor_left = 0.0
color_rect.anchor_right = 1.0
color_rect.anchor_top = 0.0
color_rect.anchor_bottom = 1.0
color_rect.offset_left = target_node.offset_left
color_rect.offset_right = target_node.offset_right
color_rect.offset_top = target_node.offset_top
color_rect.offset_bottom = target_node.offset_bottom

# 方式 3：固定像素尺寸
color_rect.custom_minimum_size = Vector2(800, 600)
color_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
color_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
```

---

### 场景 B：目标节点已有 ColorRect

**关键点：** ColorRect 默认会吸收输入事件（鼠标点击等），需注意层级管理。

#### 问题说明

```gdscript
# 场景结构示例
PanelContainer          # 容器
├── ColorRect          # 背景（已有）
├── VBoxContainer      # 内容
│   ├── Label
│   └── Button
```

如果 ColorRect 在最底层：
- ✅ 不会阻挡点击事件
- ❌ Shader 效果可能被其他节点遮挡

如果 ColorRect 在最顶层：
- ✅ Shader 效果最明显
- ❌ 会阻挡所有点击事件

#### 解决方案 1：使用 `mouse_filter` 属性

```gdscript
@onready var background_blur: ColorRect = $BackgroundBlur

func _ready() -> void:
    # 让 ColorRect 不响应鼠标事件（穿透）
    background_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    # 应用 shader
    background_blur.material = ShaderMaterial.new()
    background_blur.material.shader = preload("res://assets/shaders/background_blur.gdshader")
    background_blur.material.set_shader_parameter("blur_amount", 3.0)
    background_blur.material.set_shader_parameter("brightness", 0.8)
```

#### 解决方案 2：动态调整层级

```gdscript
extends Control

@onready var background_layer: ColorRect = $BackgroundBlur
@onready var content_layer: Control = $Content

var is_blur_active: bool = false

func activate_blur() -> void:
    """激活模糊效果（将 ColorRect 移到最顶层）"""
    is_blur_active = true
    background_layer.mouse_filter = Control.MOUSE_FILTER_STOP  # 阻挡点击
    move_child(background_layer, get_child_count() - 1)  # 移到最顶层
    
    # 动画模糊效果
    var tween := create_tween()
    tween.tween_method(
        func(value): background_layer.material.set_shader_parameter("blur_amount", value),
        0.0, 4.0, 0.3
    )

func deactivate_blur() -> void:
    """取消模糊效果（将 ColorRect 移回底层）"""
    is_blur_active = false
    background_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 允许穿透
    
    # 动画恢复
    var tween := create_tween()
    tween.tween_method(
        func(value): background_layer.material.set_shader_parameter("blur_amount", value),
        4.0, 0.0, 0.3
    )
    
    await tween.finished
    move_child(background_layer, 0)  # 移回底层
```

#### 解决方案 3：为特定节点创建独立 ColorRect

```gdscript
func add_blur_to_control(target: Control, blur_amount: float = 3.0) -> ColorRect:
    """为目标节点添加独立的模糊层"""
    var blur := ColorRect.new()
    blur.name = "BlurOverlay"
    
    # 复制目标节点的位置和尺寸
    blur.set_anchors_preset(Control.PRESET_FULL_RECT)
    blur.offset_left = target.offset_left
    blur.offset_right = target.offset_right
    blur.offset_top = target.offset_top
    blur.offset_bottom = target.offset_bottom
    
    # 应用 shader
    blur.material = ShaderMaterial.new()
    blur.material.shader = preload("res://assets/shaders/transition_blur.gdshader")
    blur.material.set_shader_parameter("blur_amount", blur_amount)
    blur.material.set_shader_parameter("rect_size_px", target.size)
    blur.material.set_shader_parameter("corner_radius_px", 12.0)
    
    # 插入到目标节点的父节点中（位于目标节点上方）
    var parent := target.get_parent()
    var target_index := target.get_index()
    parent.add_child(blur)
    parent.move_child(blur, target_index + 1)
    
    # 不阻挡鼠标事件
    blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    return blur
```

---

## 3. background_blur.gdshader

**用途：**
- 主菜单背景的实时模糊效果
- 弹窗背景的毛玻璃效果

**参数：**

| 参数 | 类型 | 范围 | 默认值 | 说明 |
|------|------|------|--------|------|
| `blur_amount` | float | 0.0-5.0 | 2.5 | 模糊强度，值越大越模糊 |
| `brightness` | float | 0.0-2.0 | 1.0 | 亮度调整，<1.0 变暗，>1.0 变亮 |

**示例：主菜单背景模糊**

```gdscript
extends Control

@onready var background_blur: ColorRect = $BackgroundBlur

func _ready() -> void:
    # 设置模糊强度和亮度
    var material := background_blur.material as ShaderMaterial
    material.set_shader_parameter("blur_amount", 3.0)
    material.set_shader_parameter("brightness", 0.9)  # 略微压暗

func _on_game_selected(poster_texture: Texture2D) -> void:
    # 动态切换背景（如果有 TextureRect 配合）
    background_blur.material.set_shader_parameter("SCREEN_TEXTURE", poster_texture)
```

**编辑器配置：**
1. 创建 `ColorRect` 节点作为背景
2. 将 `background_blur.gdshader` 拖到 Inspector 的 Material 属性
3. 勾选 "Local to Scene"（确保每个实例独立）
4. 调整 `blur_amount` 参数（推荐值：2.0-4.0）

---

## 4. dissolve.gdshader

**用途：**
- 游戏卡面的溶解/消融动画
- 场景切换的渐变效果
- 物品消失/出现的特效

**参数：**

| 参数 | 类型 | 范围 | 默认值 | 说明 |
|------|------|------|--------|------|
| `dissolve_texture` | sampler2D | - | - | 噪声纹理，控制溶解图案 |
| `dissolve_value` | float | 0.0-1.0 | - | 溶解进度，0=完整，1=完全消失 |
| `burn_size` | float | 0.0-1.0 | - | 燃烧边缘宽度 |
| `burn_color` | vec4 | - | - | 燃烧边缘颜色 |

**示例：游戏卡面溶解消失**

```gdscript
extends Control
class_name GameCard

@onready var card_texture: TextureRect = $CardTexture

func dissolve_card(duration: float = 1.0) -> void:
    # 创建溶解材质
    var dissolve_material := ShaderMaterial.new()
    dissolve_material.shader = preload("res://assets/shaders/dissolve.gdshader")
    
    # 设置噪声纹理（需要提前准备一张噪声图）
    dissolve_material.set_shader_parameter("dissolve_texture", preload("res://assets/textures/noise/dissolve_noise.png"))
    dissolve_material.set_shader_parameter("dissolve_value", 0.0)
    dissolve_material.set_shader_parameter("burn_size", 0.05)
    dissolve_material.set_shader_parameter("burn_color", Color(1.0, 0.5, 0.0, 1.0))  # 橙色火焰
    
    # 应用到卡面
    card_texture.material = dissolve_material
    
    # 执行溶解动画
    var tween := create_tween()
    tween.tween_method(
        func(value): card_texture.material.set_shader_parameter("dissolve_value", value),
        0.0, 1.0, duration
    )
    
    await tween.finished
    queue_free()

func appear_card(duration: float = 0.8) -> void:
    # 创建溶解材质（初始完全透明）
    var dissolve_material := ShaderMaterial.new()
    dissolve_material.shader = preload("res://assets/shaders/dissolve.gdshader")
    dissolve_material.set_shader_parameter("dissolve_texture", preload("res://assets/textures/noise/dissolve_noise.png"))
    dissolve_material.set_shader_parameter("dissolve_value", 1.0)  # 从消失状态开始
    dissolve_material.set_shader_parameter("burn_size", 0.03)
    dissolve_material.set_shader_parameter("burn_color", Color(0.5, 1.0, 0.8, 1.0))  # 青色光晕
    
    card_texture.material = dissolve_material
    
    # 执行出现动画（从 1.0 到 0.0）
    var tween := create_tween()
    tween.tween_method(
        func(value): card_texture.material.set_shader_parameter("dissolve_value", value),
        1.0, 0.0, duration
    )
```

**编辑器配置：**
1. 在 TextureRect 或 Sprite2D 上添加 Shader Material
2. 准备一张噪声纹理（推荐使用 Perlin Noise 或 Voronoi）
3. 设置 `burn_size`（推荐 0.02-0.1）
4. 设置 `burn_color`（推荐暖色调：橙/红/黄）

---

## 5. transition_blur.gdshader

**用途：**
- 场景切换时的全屏模糊过渡
- 页面切换的高级效果
- 弹窗显示时的背景模糊（支持圆角）

**参数：**

| 参数 | 类型 | 范围 | 默认值 | 说明 |
|------|------|------|--------|------|
| `blur_amount` | float | 0.0-10.0 | 0.0 | 模糊强度，0=清晰，10=重度模糊 |
| `rect_size_px` | vec2 | - | (256, 256) | ColorRect 的像素尺寸，**必须动态设置** |
| `corner_radius_px` | float | 0.0-256.0 | 0.0 | 圆角半径，0=无圆角 |

**示例：带圆角的弹窗背景模糊**

```gdscript
extends Control

var blur_overlay: ColorRect

func show_popup_with_blur(popup_size: Vector2, corner_radius: float = 24.0) -> void:
    # 创建模糊背景
    blur_overlay = ColorRect.new()
    blur_overlay.color = Color.TRANSPARENT
    blur_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    blur_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 允许穿透
    
    # 应用 shader
    blur_overlay.material = ShaderMaterial.new()
    blur_overlay.material.shader = preload("res://assets/shaders/transition_blur.gdshader")
    blur_overlay.material.set_shader_parameter("blur_amount", 0.0)
    blur_overlay.material.set_shader_parameter("rect_size_px", popup_size)
    blur_overlay.material.set_shader_parameter("corner_radius_px", corner_radius)
    
    # 添加到场景
    get_tree().root.add_child(blur_overlay)
    
    # 动画进入
    var tween := create_tween()
    tween.tween_method(
        func(value): blur_overlay.material.set_shader_parameter("blur_amount", value),
        0.0, 4.0, 0.3
    )

func hide_popup_with_blur() -> void:
    if not blur_overlay:
        return
    
    # 动画退出
    var tween := create_tween()
    tween.tween_method(
        func(value): blur_overlay.material.set_shader_parameter("blur_amount", value),
        4.0, 0.0, 0.3
    )
    
    await tween.finished
    blur_overlay.queue_free()
    blur_overlay = null
```

**示例：场景切换过渡**

```gdscript
extends Node

var transition_layer: ColorRect

func change_scene_with_blur(scene_path: String, duration: float = 0.5) -> void:
    # 创建过渡层
    transition_layer = ColorRect.new()
    transition_layer.color = Color.TRANSPARENT
    transition_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
    transition_layer.mouse_filter = Control.MOUSE_FILTER_STOP  # 阻挡输入
    
    transition_layer.material = ShaderMaterial.new()
    transition_layer.material.shader = preload("res://assets/shaders/transition_blur.gdshader")
    transition_layer.material.set_shader_parameter("blur_amount", 0.0)
    # 全屏过渡不需要圆角
    
    get_tree().root.add_child(transition_layer)
    
    # 模糊进入
    var tween := create_tween()
    tween.tween_method(
        func(value): transition_layer.material.set_shader_parameter("blur_amount", value),
        0.0, 8.0, duration / 2
    )
    
    await tween.finished
    
    # 切换场景
    get_tree().change_scene_to_file(scene_path)
    
    # 等待一帧确保新场景加载
    await get_tree().process_frame
    
    # 模糊退出
    tween = create_tween()
    tween.tween_method(
        func(value): transition_layer.material.set_shader_parameter("blur_amount", value),
        8.0, 0.0, duration / 2
    )
    
    await tween.finished
    transition_layer.queue_free()
```

---

## 6. 完整工具类示例

```gdscript
# res://utils/shader_utils.gd
extends Node
class_name ShaderUtils

## 为目标节点创建模糊叠加层
static func create_blur_overlay(
    parent: Control,
    shader_path: String,
    blur_amount: float = 3.0,
    corner_radius: float = 0.0,
    block_mouse: bool = false
) -> ColorRect:
    var overlay := ColorRect.new()
    overlay.name = "BlurOverlay"
    overlay.color = Color.TRANSPARENT
    overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    
    overlay.material = ShaderMaterial.new()
    overlay.material.shader = preload(shader_path)
    overlay.material.set_shader_parameter("blur_amount", blur_amount)
    
    if corner_radius > 0:
        overlay.material.set_shader_parameter("rect_size_px", parent.size)
        overlay.material.set_shader_parameter("corner_radius_px", corner_radius)
    
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP if block_mouse else Control.MOUSE_FILTER_IGNORE
    
    parent.add_child(overlay)
    return overlay

## 为 TextureRect 添加溶解效果
static func apply_dissolve(
    texture_rect: TextureRect,
    noise_texture: Texture2D,
    burn_size: float = 0.05,
    burn_color: Color = Color.ORANGE
) -> ShaderMaterial:
    var material := ShaderMaterial.new()
    material.shader = preload("res://assets/shaders/dissolve.gdshader")
    material.set_shader_parameter("dissolve_texture", noise_texture)
    material.set_shader_parameter("dissolve_value", 0.0)
    material.set_shader_parameter("burn_size", burn_size)
    material.set_shader_parameter("burn_color", burn_color)
    
    texture_rect.material = material
    return material

## 执行溶解动画
static func tween_dissolve(
    material: ShaderMaterial,
    from: float,
    to: float,
    duration: float,
    node: Node
) -> void:
    var tween := node.create_tween()
    tween.tween_method(
        func(value): material.set_shader_parameter("dissolve_value", value),
        from, to, duration
    )

## 执行模糊动画
static func tween_blur(
    material: ShaderMaterial,
    from: float,
    to: float,
    duration: float,
    node: Node
) -> void:
    var tween := node.create_tween()
    tween.tween_method(
        func(value): material.set_shader_parameter("blur_amount", value),
        from, to, duration
    )
```

---

## 7. 性能优化建议

1. **避免过度使用**：同时运行的 Shader 越多，性能消耗越大
2. **合理设置模糊强度**：过高的 `blur_amount` 会增加 GPU 负担
3. **使用 Visible 控制**：不需要时隐藏 Shader 层，而不是调整参数
4. **及时释放资源**：动态创建的 ColorRect 用完后调用 `queue_free()`
5. **移动端注意**：这些 Shader 在低端设备上可能性能较差

---

## 8. 测试方法

### 快速测试 Shader

1. 新建一个测试场景 `test_shader.tscn`
2. 添加 Sprite2D 或 TextureRect，放入一张测试图片
3. 添加子节点 ColorRect，覆盖父节点
4. 给 ColorRect 应用 Shader
5. 运行场景查看效果

### 参数实时调整

在编辑器中运行项目时，可以在 Remote 面板找到应用了 Shader 的节点，实时修改 Material 的参数观察效果。

### 调试模糊效果

```gdscript
func _process(delta: float) -> void:
    # 运行时调试：用鼠标位置控制模糊强度
    var blur = get_local_mouse_position().x / size.x * 5.0
    $ColorRect.material.set_shader_parameter("blur_amount", blur)
```