# Phase2:多按钮与布局系统实现计划

##目标
实现1-3个按钮的动态生成，支持灵活的布局配置（对齐方式），完善回调机制。

##当前状态（基于Phase1）
- GlobalPopup可以显示单个按钮
- ButtonContainer使用 HBoxContainer，alignment = END（右对齐）

##需要实现的功能

###1.动态按钮生成
**GlobalPopup._create_buttons()方法：**
```gdscript
func _create_buttons(button_configs: Array[Dictionary]) -> void:
 #清空现有按钮
 for btn in _buttons:
 btn.queue_free()
 _buttons.clear()
 
 #根据配置数量创建按钮
 var count = button_configs.size()
 if count ==0:
 return
 
 for i in range(count):
 var config = button_configs[i]
 var btn = GlassButton.new()
 btn.text = config.get("text", "按钮")
 btn.button_type = _parse_button_type(config.get("type", "secondary"))
 btn.size_variant = GlassButton.SizeVariant.MEDIUM
 
 #设置最小尺寸
 btn.custom_minimum_size = Vector2(120,40)
 
 #绑定元数据
 btn.set_meta("metadata", config.get("metadata", str(i)))
 btn.pressed.connect(_on_button_pressed.bind(btn))
 
 _buttons.append(btn)
 button_container.add_child(btn)
```

###2.布局策略
**方案：对齐方式控制（不使用 spacer）**

HBoxContainer.alignment属性：
- `ALIGNMENT_BEGIN` (0):左对齐
- `ALIGNMENT_CENTER` (1):居中对齐
- `ALIGNMENT_END` (2):右对齐

配置格式：
```gdscript
{
 "buttons": [...],
 "button_alignment": "end" # "begin" | "center" | "end"
}
```

默认行为：
-1个按钮：居中
-2个按钮：右对齐（取消在左，确定在右）
-3个按钮：考虑左中右分布或右对齐

**3按钮布局处理：**
当 buttons.size() ==3时：
-选项A：全部右对齐（紧凑排列）
-选项B：第一个按钮左对齐，其余右对齐（需要调整容器结构）

建议先用选项A（简单），如果需要特殊布局再扩展。

###3.回调机制完善
**信号流：**
```
GlassButton.pressed → GlobalPopup._on_button_pressed → PopupManager._on_button_pressed →调用方
```

**携带数据：**
```gdscript
# GlobalPopup
func _on_button_pressed(btn: GlassButton) -> void:
 var metadata = btn.get_meta("metadata")
 popup_closed.emit(metadata)

# PopupManager
func _on_popup_closed(metadata: String) -> void:
 popup_button_pressed.emit(metadata)
 close_popup()
```

###4.默认模板支持
**PopupManager添加快捷方法：**
```gdscript
func show_confirm(title: String, content: String, on_confirmed: Callable, on_cancelled: Callable = Callable()) -> void:
 show_popup({
 "title": title,
 "content": content,
 "buttons": [
 {"text": "取消", "type": "secondary", "metadata": "cancel"},
 {"text": "确定", "type": "primary", "metadata": "confirm"}
 ]
 })
 
 #临时存储回调（或使用信号连接）
 _temp_callbacks["cancel"] = on_cancelled
 _temp_callbacks["confirm"] = on_confirmed
```

###5.按钮样式配置
扩展按钮配置：
```gdscript
{
 "text": "确定",
 "type": "primary",
 "metadata": "confirm",
 "size": "medium", #可选，覆盖全局设置
 "min_width":140, #可选，覆盖默认120
 "min_height":48 #可选，覆盖默认40
}
```

##测试场景
**文件：** `scenes/test/test_popup_phase2.tscn`

测试内容：
1.打开1个按钮的弹窗（居中）
2.打开2个按钮的弹窗（右对齐）
3.打开3个按钮的弹窗（右对齐）
4.验证每个按钮按下后返回正确的 metadata
5.测试 show_confirm()快捷方法
6.测试自定义按钮文本和样式

##验收标准
- [ ]支持1-3个按钮动态生成
- [ ]按钮布局符合配置（对齐方式）
- [ ]按钮按下正确返回 metadata（"primary"/"second"/"third"或自定义）
- [ ]支持默认模板（show_confirm）
- [ ]按钮最小尺寸可配置
- [ ]测试场景覆盖所有情况
