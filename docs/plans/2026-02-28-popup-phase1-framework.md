# Phase1:弹窗基础框架实现计划

##目标
改造现有的 GlassComponent场景，实现基础的弹窗显示功能，支持单个按钮和基本的打开/关闭动画。

##当前状态
-已有 `component/GlassComponent/medium_popup.tscn`和 `large_popup.tscn`
-场景结构：ColorRect(Shader背景) → Margin → VBox → [Title, Content, Spacer, ButtonContainer]
- ButtonContainer中已有 PrimaryButton和 SecondaryButton（使用 spacer分隔）

##需要改造的内容

###1.场景结构调整
**medium_popup.tscn / large_popup.tscn:**
-添加 CanvasLayer作为根节点（层级 Layer =4）
-保留原有的 ColorRect作为玻璃面板
-重命名节点使其更通用：
 - `PrimaryButton` → `Button1`
 - `SecondaryButton` → `Button2`
-删除固定的 Button节点，改为运行时动态创建
- ButtonContainer保持 HBoxContainer，alignment设为 END（右对齐）

###2.创建 GlobalPopup脚本
**文件：** `script/component/global_popup.gd`

核心功能：
```gdscript
extends CanvasLayer
class_name GlobalPopup

#节点引用
@onready var glass_panel: ColorRect
@onready var title_label: Label
@onready var content_label: RichTextLabel
@onready var button_container: HBoxContainer

#配置数据
var _config: Dictionary = {}
var _buttons: Array[GlassButton] = []

#信号
signal popup_closed(metadata: String)
signal popup_opened

func setup(config: Dictionary) -> void:
 #解析配置并设置UI
 
func open() -> void:
 #播放打开动画（缩放+淡入）
 
func close(metadata: String = "") -> void:
 #播放关闭动画，然后发送信号
```

###3. PopupManager改造
**文件：** `script/managers/popup_manager.gd`

```gdscript
extends Node

signal popup_button_pressed(metadata: String)

var _current_popup: GlobalPopup = null
var _popup_scene_medium: PackedScene = preload("res://component/GlassComponent/medium_popup.tscn")
var _popup_scene_large: PackedScene = preload("res://component/GlassComponent/large_popup.tscn")

func show_popup(config: Dictionary) -> void:
 #清除旧弹窗（如果存在）
 #实例化新弹窗
 #连接按钮信号
 #播放打开动画

func _on_button_pressed(metadata: String) -> void:
 popup_button_pressed.emit(metadata)
 close_popup()

func close_popup() -> void:
 if _current_popup:
 _current_popup.close()
```

###4.配置格式定义
```gdscript
{
 "size": "medium", # "medium" | "large"
 "title": "弹窗标题",
 "content": "弹窗内容文本",
 "content_type": "label", # "label" | "richtext"
 "buttons": [
 {
 "text": "确定",
 "type": "primary", # "primary" | "secondary"
 "metadata": "primary" #回调时携带的标识
 }
 ],
 "close_policy": "immediate", # "immediate" | "stack"(预留)
 "clear_on_new": true #打开新弹窗时是否清除旧弹窗
}
```

###5.动画实现
**打开动画（Tween）：**
- scale:0.8 →1.0 (0.3s, TRANS_BACK, EASE_OUT)
- modulate.a:0 →1 (0.25s)

**关闭动画（Tween）：**
- modulate.a:1 →0 (0.15s)
-完成后 queue_free()

##测试场景
**文件：** `scenes/test/test_popup_phase1.tscn`

测试内容：
1.点击按钮打开中等弹窗（单个按钮）
2.点击按钮打开大弹窗（单个按钮）
3.验证打开动画效果
4.验证关闭动画效果
5.验证回调信号正确携带 metadata

##验收标准
- [ ] medium_popup.tscn和 large_popup.tscn完成改造
- [ ] GlobalPopup脚本可以接收配置并显示内容
- [ ] PopupManager.show_popup()可以成功打开弹窗
- [ ]按钮点击后正确发送携带 metadata的信号
- [ ]打开/关闭动画流畅自然
- [ ]测试场景运行正常
