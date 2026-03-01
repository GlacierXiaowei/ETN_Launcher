# Phase4:弹窗Shader动画与特效实现计划

##目标
实现完整的弹窗视觉效果，包括Shader模糊关闭动画、背景压暗、圆角同步。

##当前状态
-已有 `transition_blur.gdshader`可用于全屏模糊
- GlassComponent场景使用 `liquid_glass_ui.gdshader`作为面板材质
- medium_popup.tscn和 large_popup.tscn已完成基础改造（Phase1-3）

## Phase3交付内容（进入Phase4前置上下文）

### Phase3已实现
- 弹窗内容更新：`PopupManager.update_popup(config)`，支持不关闭弹窗更新标题/内容/按钮。
- 内容切换动画：当 `config["transition_animation"] == true` 时，使用淡入淡出更新（GlobalPopup.update_with_fade）。
- 关闭后新开：`PopupManager.close_and_show_new(config)`，通过等待被关闭弹窗实例的 `closed` 信号避免竞态。
- 回调语义拆分（关键）：
  - GlobalPopup:
    - `button_pressed(metadata)`：任意按钮按下必触发，业务回调永远能拿到 metadata。
    - `closed`：关闭动画结束后触发，用于生命周期控制。
  - PopupManager:
    - `popup_button_pressed(metadata)`：业务回调。
    - `popup_closed`：关闭完成事件。
- 按钮文本自适应默认开启：GlassButton 根据文本自动扩展最小尺寸，避免长文本被裁切。

### Phase3测试场景
- `res://scenes/test/test_popup_phase3.tscn`
- 用例覆盖：更新不关闭、淡入淡出更新、关闭后新开、has_open_popup检查。

##需要实现的内容

###1.关闭动画Shader集成

**问题：** transition_blur.gdshader是全屏的，需要适配到弹窗面板大小

**解决方案：**
在 GlobalPopup中添加专门的模糊层：
```
CanvasLayer
└── GlobalPopup
 ├── DimBackground (ColorRect -全屏遮罩)
 └── PopupRoot (Control -包含所有弹窗内容)
 ├── BlurOverlay (ColorRect -覆盖整个面板区域)
 │ └── material: ShaderMaterial with transition_blur.gdshader
 └── GlassPanel (原有的玻璃面板)
```

**BlurOverlay设置：**
- size = GlassPanel.size
- position = GlassPanel.position
- mouse_filter = MOUSE_FILTER_STOP（吸收输入）
-初始 visible = false

**关闭动画流程：**
```gdscript
func close_with_blur(metadata: String = "") -> void:
 #1.显示模糊层
 _blur_overlay.visible = true
 
 #2.第一阶段：增加模糊
 var tween1 = create_tween()
 tween1.tween_property(
 _blur_overlay.material,
 "shader_parameter/blur_amount",
3.0, #最大模糊强度
0.15
 )
 await tween1.finished
 
 #3.第二阶段：淡出
 var tween2 = create_tween()
 tween2.parallel().tween_property(_popup_root, "modulate:a",0.0,0.15)
 tween2.parallel().tween_property(_blur_overlay, "modulate:a",0.0,0.15)
 await tween2.finished
 
 #4.清理
 popup_closed.emit(metadata)
 queue_free()
```

###2.背景压暗（Dim Background）

**DimBackground节点：**
```gdscript
var _dim_bg: ColorRect

func _create_dim_background() -> void:
 _dim_bg = ColorRect.new()
 _dim_bg.name = "DimBackground"
 _dim_bg.color = Color(0,0,0,0.5) #50%黑色透明度
 _dim_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
 _dim_bg.mouse_filter = Control.MOUSE_FILTER_STOP #阻止点击穿透
 add_child(_dim_bg)
 move_child(_dim_bg,0) #放到最底层
```

**动画：**
-打开时：alpha0 →0.5 (0.2s)
-关闭时：alpha0.5 →0 (0.15s)

**配置控制：**
```gdscript
{
 "dim_background": true, #是否启用
 "dim_color": Color(0,0,0,0.5), #自定义颜色
 "dim_click_to_close": false #点击背景是否关闭（预留）
}
```

###3.圆角同步

**问题：** BlurOverlay是矩形，但GlassPanel有圆角，会穿帮

**解决方案A：使用Viewport截图（复杂）**
-将弹窗内容渲染到Viewport
-对Viewport应用Shader模糊
-用GlassPanel的shader做圆角裁剪

**解决方案B：简化方案（推荐）**
- BlurOverlay也使用 `liquid_glass_ui.gdshader`
-但参数不同：高模糊 +低透明度
-这样边缘会有相同的圆角效果

**实现：**
```gdscript
#为 BlurOverlay创建特殊材质
var blur_mat = ShaderMaterial.new()
blur_mat.shader = load("res://assets/shaders/liquid_glass_ui.gdshader")
blur_mat.set_shader_parameter("blur_lod_center",4.0) #高模糊
blur_mat.set_shader_parameter("blur_lod_edge",5.0)
blur_mat.set_shader_parameter("tint", Color(1,1,1,0.1)) #几乎透明
_blur_overlay.material = blur_mat
```

###4.动画曲线优化

**打开动画增强：**
```gdscript
func open() -> void:
 _popup_root.scale = Vector2(0.8,0.8)
 _popup_root.modulate.a =0.0
 
 var tween = create_tween()
 tween.set_trans(Tween.TRANS_BACK)
 tween.set_ease(Tween.EASE_OUT)
 
 #同时执行缩放和淡入
 tween.parallel().tween_property(_popup_root, "scale", Vector2(1,1),0.3)
 tween.parallel().tween_property(_popup_root, "modulate:a",1.0,0.25)
 
 #如果有背景压暗，同时淡入
 if _dim_bg and _config.get("dim_background", false):
 _dim_bg.modulate.a =0.0
 tween.parallel().tween_property(_dim_bg, "modulate:a", _dim_alpha,0.2)
 
 await tween.finished
 popup_opened.emit()
```

###5.转场防点击

**问题：**动画过程中用户可能误触按钮

**解决：**
```gdscript
var _is_animating := false

func open() -> void:
 _is_animating = true
 #...动画代码
 _is_animating = false

func _on_button_pressed(metadata: String) -> void:
 if _is_animating:
 return #动画中忽略点击
 #...正常处理
```

或者在动画开始时设置：
```gdscript
_button_container.mouse_filter = MOUSE_FILTER_IGNORE #禁用按钮
#动画结束后恢复
_button_container.mouse_filter = MOUSE_FILTER_PASS
```

##测试场景

**文件：** `scenes/test/test_popup_phase4.tscn`

测试内容：
1.标准关闭动画（无模糊）
2.Shader模糊关闭动画
3.带背景压暗的打开/关闭
4.快速连续点击测试（防误触）
5.不同尺寸弹窗的动画一致性

##验收标准

- [ ]关闭时 Shader模糊效果流畅
- [ ]背景压暗正确显示在所有弹窗后方
- [ ]圆角边缘没有穿帮
- [ ]动画过程中按钮不可点击
- [ ]打开和关闭动画时间符合设计（共约0.5s）
- [ ]测试场景展示所有特效组合

##技术难点

1. **BlurOverlay位置同步**：需要在 `_on_resized()`中更新位置和大小
2. **性能考虑**：Shader模糊在低端设备可能卡顿，考虑提供降级方案（简单淡出）
3. **层级关系**：确保 DimBackground < BlurOverlay < GlassPanel的绘制顺序
