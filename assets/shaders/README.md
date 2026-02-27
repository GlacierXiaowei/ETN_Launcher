# Shader使用指南

##1. background_blur.gdshader -背景模糊

**用途：**
-主菜单背景的实时模糊效果
-弹窗背景的毛玻璃效果

**使用方法：**

###在主菜单中使用：
```gdscript
# main_menu.gd
extends Control

@onready var background_blur = $BackgroundBlur

func _ready():
 #获取当前选中游戏的海报
 var poster_texture = load("res://assets/images/games/game1_poster.jpg")
 
 #设置到模糊背景
 background_blur.texture = poster_texture
 
 #调整模糊强度（可选）
 var material = background_blur.material as ShaderMaterial
 material.set_shader_parameter("blur_amount",3.0)
```

###在 Godot编辑器中配置：
1.创建一个 `TextureRect`节点作为背景
2.将 `background_blur.gdshader`拖到 Inspector的 Material属性
3.勾选 "Local to Scene"（确保每个实例独立）
4.设置 Texture为游戏海报图片
5.调整 `blur_amount`参数（推荐值：2.0-4.0）

**关键参数：**
- `blur_amount`:模糊强度（0.0-5.0），值越大越模糊
- `texture`:要模糊的源图像

---

##2. highlight_border.gdshader -选中高亮边框

**用途：**
-游戏卡面悬停时的白色发光边框
-任何需要强调选中的 UI元素

**使用方法：**

###在游戏卡面中使用：
```gdscript
# game_card.gd
extends Control

@onready var hover_effect = $HoverEffect

func _ready():
 #默认隐藏高亮效果
 hover_effect.visible = false

func _on_mouse_entered():
 hover_effect.visible = true
 
 #可选：动态调整发光强度
 var material = hover_effect.material as ShaderMaterial
 material.set_shader_parameter("glow_intensity",1.5)

func _on_mouse_exited():
 hover_effect.visible = false
```

###在 Godot编辑器中配置：
1.在游戏卡面的最上层添加 `ColorRect`或 `TextureRect`
2.尺寸与海报相同，覆盖整个卡面
3.应用 `highlight_border.gdshader`
4.调整参数：
 - `border_width`:边框宽度（0.0-0.1），推荐0.02-0.05
 - `border_color`:边框颜色，推荐白色 (1,1,1,1)
 - `glow_intensity`:发光强度（0.0-2.0），推荐1.0-1.5

**注意事项：**
-这个 Shader会修改原图，建议放在单独的 overlay层
-可以配合 Tween实现发光强度的渐变动画

---

##3. transition_blur.gdshader -过渡模糊

**用途：**
-场景切换时的全屏模糊过渡
-页面切换的高级效果

**使用方法：**

###基础用法（直接代码控制）：
```gdscript
# scene_manager.gd
extends Node

var blur_overlay: ColorRect

func transition_with_blur(duration: float =0.5):
 #创建全屏模糊层
 blur_overlay = ColorRect.new()
 blur_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
 blur_overlay.material = ShaderMaterial.new()
 blur_overlay.material.shader = preload("res://assets/shaders/transition_blur.gdshader")
 get_tree().root.add_child(blur_overlay)
 
 #动画：从清晰到模糊
 var tween = create_tween()
 tween.tween_method(
 func(value): blur_overlay.material.set_shader_parameter("blur_amount", value),
0.0,
5.0,
 duration /2
 )
 
 await tween.finished
 
 #这里执行场景切换逻辑
 # change_scene_to_file(...)
 
 #动画：从模糊到清晰
 tween = create_tween()
 tween.tween_method(
 func(value): blur_overlay.material.set_shader_parameter("blur_amount", value),
5.0,
0.0,
 duration /2
 )
 
 await tween.finished
 blur_overlay.queue_free()
```

###高级用法（配合加载界面）：
```gdscript
func transition_with_loading(scene_path: String):
 #显示"加载中"文字
 show_loading_text()
 
 #执行模糊过渡
 await transition_with_blur(0.3)
 
 #加载新场景
 get_tree().change_scene_to_file(scene_path)
 
 #隐藏加载文字
 hide_loading_text()
```

**关键参数：**
- `blur_amount`:模糊强度（0.0-10.0）
 -0.0 =完全清晰
 -5.0 =中度模糊
 -10.0 =重度模糊（几乎看不见内容）

---

## Shader性能优化建议

1. **避免过度使用**：同时运行的 Shader越多，性能消耗越大
2. **合理设置模糊强度**：过高的 blur_amount会增加 GPU负担
3. **使用 Visible控制**：不需要时隐藏 Shader层，而不是调整参数
4. **移动端注意**：这些 Shader在低端设备上可能性能较差

##测试方法

###快速测试 Shader：
1.新建一个测试场景 `test_shader.tscn`
2.添加 Sprite2D或 TextureRect，放入一张测试图片
3.添加子节点 ColorRect，覆盖父节点
4.给 ColorRect应用 Shader
5.运行场景查看效果

###参数实时调整：
在编辑器中运行项目时，可以在 Remote面板找到应用了 Shader的节点，实时修改 Material的参数观察效果。
