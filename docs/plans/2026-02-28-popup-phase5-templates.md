# Phase5:快捷方法与完整文档

##目标
提供易用的快捷方法，完善API文档，整合到主项目。

##快捷方法实现

###PopupManager添加的方法：
```gdscript
#确认对话框（2个按钮：确定/取消）
func show_confirm(
 title: String,
 content: String,
 on_confirm: Callable,
 on_cancel: Callable = Callable(),
 confirm_text: String = "确定",
 cancel_text: String = "取消"
) -> void

#提示对话框（1个按钮：确定）
func show_alert(
 title: String,
 content: String,
 on_ok: Callable = Callable(),
 ok_text: String = "确定"
) -> void

#加载中弹窗（无按钮，显示转圈动画）
func show_loading(title: String = "请稍候") -> void
func hide_loading() -> void

#富文本内容弹窗（用于更新公告）
func show_richtext(
 title: String,
 richtext_content: String,
 buttons: Array[Dictionary]
) -> void
```

##使用示例

###简单确认：
```gdscript
PopupManager.show_confirm(
 "删除存档",
 "确定要删除这个存档吗？此操作不可恢复。",
 func(): _delete_save(),
 func(): print("用户取消了")
)
```

###带回调的提示：
```gdscript
PopupManager.show_alert(
 "保存成功",
 "您的游戏进度已保存。",
 func(): _return_to_menu()
)
```

###完整自定义：
```gdscript
PopupManager.show_popup({
 "size": "large",
 "title": "更新公告",
 "content_type": "richtext",
 "content": "[b]版本 v1.2.0[/b]\n•新功能A\n•修复问题B",
 "buttons": [
 {"text": "立即更新", "type": "primary", "metadata": "update_now"},
 {"text": "稍后提醒", "type": "secondary", "metadata": "remind_later"},
 {"text": "忽略此版本", "type": "secondary", "metadata": "ignore"}
 ]
})

PopupManager.popup_button_pressed.connect(_on_update_choice)

func _on_update_choice(metadata: String):
 match metadata:
 "update_now": _start_update()
 "remind_later": _set_reminder()
 "ignore": _ignore_version()
```

##测试场景
**文件：** `scenes/test/test_popup_phase5.tscn`

测试内容：
1.测试 show_confirm()各种参数组合
2.测试 show_alert()
3.测试 show_loading()和 hide_loading()
4.测试 show_richtext()
5.验证所有快捷方法正常工作

##文档完善

###需要更新的文档：
1.**docs/glass-components-api-guide.md**
 -添加 GlobalPopup API说明
 -添加 PopupManager快捷方法说明

2.**docs/项目设计与实践指南.md**
 -更新"全局弹窗系统"章节（Phase1已完成）
 -补充快捷方法使用示例

###API参考文档结构：
```markdown
## PopupManager API

### show_popup(config: Dictionary)
显示自定义配置的弹窗。

**参数：**
- config:弹窗配置字典
 - size: "medium" | "large"
 - title:标题文本
 - content:内容文本
 - content_type: "label" | "richtext"
 - buttons:按钮数组
 - ...

**示例：**
[代码示例]

### show_confirm(title, content, on_confirm, on_cancel, ...)
显示确认对话框...
```

##验收标准
- [ ]所有快捷方法实现完成
- [ ]show_confirm()支持自定义按钮文本
- [ ]show_alert()支持可选回调
- [ ]show_loading()显示正确的加载动画
- [ ]API文档更新完成
- [ ]项目设计与实践指南更新完成
- [ ]测试场景覆盖所有快捷方法
- [ ]代码通过类型检查和无警告运行
