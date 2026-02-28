# Phase3:弹窗内容管理与切换实现计划

##目标
实现弹窗内容的动态更新和切换策略，支持"下一步"流程（不关闭弹窗直接更新内容）。

##功能需求

###1.内容更新方法
**GlobalPopup新增方法：**
```gdscript
func set_title(title: String) -> void:
 #更新标题文本
 
func set_content(text: String, type: String = "label") -> void:
 #更新内容文本
 #type: "label" | "richtext"
 
func set_buttons(buttons: Array[Dictionary]) -> void:
 #清除现有按钮，重新创建
 #buttons格式同 Phase2

func update(config: Dictionary) -> void:
 #批量更新：标题、内容、按钮
 #播放内容切换动画（可选）
```

###2. PopupManager新增方法
```gdscript
#更新当前弹窗内容（不关闭）
func update_popup(config: Dictionary) -> bool:
 if _current_popup == null:
 return false
 _current_popup.update(config)
 return true

#关闭当前弹窗并打开新弹窗
func close_and_show_new(config: Dictionary) -> void:
 if _current_popup:
 await _current_popup.close()
 show_popup(config)

#检查是否有弹窗打开
func has_open_popup() -> bool:
 return _current_popup != null and is_instance_valid(_current_popup)
```

###3.内容切换动画（可选增强）
**方案A：直接切换（简单）**
-直接修改文本内容，无动画

**方案B：淡入淡出切换（推荐）**
```gdscript
func update_with_fade(new_config: Dictionary) -> void:
 #1.淡出旧内容（0.15s）
 var tween = create_tween()
 tween.tween_property(content_container, "modulate:a",0.0,0.15)
 await tween.finished
 
 #2.更新内容
 set_title(new_config.title)
 set_content(new_config.content, new_config.get("content_type", "label"))
 set_buttons(new_config.buttons)
 
 #3.淡入新内容（0.15s）
 tween = create_tween()
 tween.tween_property(content_container, "modulate:a",1.0,0.15)
```

###4.配置扩展
```gdscript
{
 #...原有配置...
 
 #切换动画设置
 "transition_animation": true, #是否播放切换动画
 
 #关闭策略
 "close_policy": "immediate", # "immediate":立即关闭
 # "keep_open":保持打开（用于update）
}
```

##测试场景
**文件：** `scenes/test/test_popup_phase3.tscn`

测试用例：
1.**单弹窗内容更新**
 -打开弹窗显示"步骤1"
 -点击"下一步"按钮
 -使用 update_popup()更新为"步骤2"
 -验证内容已更新，弹窗未关闭

2.**关闭后新开**
 -打开弹窗A
 -点击按钮调用 close_and_show_new()打开弹窗B
 -验证弹窗A已关闭，弹窗B已打开

3.**has_open_popup()检查**
 -无弹窗时返回 false
 -有弹窗时返回 true
 -弹窗关闭后返回 false

##验收标准
- [ ] set_title(), set_content(), set_buttons()工作正常
- [ ] update()可以批量更新所有内容
- [ ] update_popup()可以在不关闭的情况下更新弹窗
- [ ] close_and_show_new()可以顺序关闭和打开
- [ ]内容切换动画流畅（如果实现）
- [ ]所有测试用例通过
