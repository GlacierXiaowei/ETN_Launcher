extends Control

@onready var zhe_zhao: ColorRect = $ZheZhao

signal enter_outer_setting
signal exit_outer_setting

func _on_button_pressed() -> void:
	var title : String = "敬请期待"
	var content : String = "预计 3.2.0.0 版本之前完善"
	
	PopupManager.show_popup({"title" :title , "content" :content })


func _on_back_pressed() -> void:
	exit_outer_setting.emit()


func _on_exit_outer_setting() -> void:
	await get_tree().create_timer(0.5).timeout
	zhe_zhao.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_enter_outer_setting() -> void:
	await get_tree().create_timer(0.5).timeout
	zhe_zhao.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_button_2_pressed() -> void:
	var title : String = "已切换模式"
	var content : String = "当前将会为所有游戏的检查更新设置为使用本地文件以验证更新功能可用性
选择不同的按钮将会替换本地的更新策略文件（目前会以ETN_Farm为基准文件，所有下载的更新将是ETN_Farm的文件），详细如下
	“补丁”：可以搜索到 Patch_002.pck补丁
	“全量”：可以搜索到ETN_Farm完整包版本号1.3.0.0
	“关闭”：将调试模式设置为关 将会按照正常流程的进行
	提示：由于ETN_Farm插件问题 目前的补丁对游戏不起效果，需要进入/user/APPDATA/ETN_Farm/Patch 路径下查看是否有对应Patch_002 文件"

	var	buttons= [
		{"text": "补丁" , "type" : "primary" , "metadata" : "patch"},
		{"text": "全量" , "type" : "secondary" , "metadata" : "full"},
		{"text": "关闭" , "type" : "third" , "metadata" : "cancel"}
	]
	PopupManager.popup_button_pressed.connect(on_popup_button_pressed, Object.CONNECT_ONE_SHOT)
	PopupManager.show_popup({
		"title" : title , "content" : content , "buttons" : buttons
							})

func on_popup_button_pressed(metadata : String) -> void:
	match metadata:
		#"min_supported_version": "1.3.0.0"
		"patch":
			VersionUtils.use_mock_cloud_version = true
			update_json_file( "min_supported_version", "0.0.0.0")
			update_json_file( "force_update",false) 
			PopupManager.show_popup({
					"title" :"成功"
							})
			
		"full":
			VersionUtils.use_mock_cloud_version = true
			update_json_file( "force_update",true) 
			update_json_file( "min_supported_version", "0.0.0.0")
			PopupManager.show_popup({
					"title" :"成功"
							})
			
		"cancel":
			VersionUtils.use_mock_cloud_version = false
			update_json_file( "min_supported_version", "1.2.0.0")
			update_json_file( "force_update", "false")
			
			PopupManager.show_popup({
					"title" :"成功"
							})


func update_json_file( key: String, value, add_if_missing: bool = true, 
path:String = "res://data/mock_cloud_version.json") -> bool:
	var file = FileAccess.open(path, FileAccess.READ)
	var data = {}
	
	if file == null:
		if not add_if_missing:
			return false
	else:
		var text = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(text) == OK:
			data = json.data
	
	data[key] = value
	
	file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	return true

## 使用示例
#update_json_file("res://data/config.json", "player_name", "张三")
#update_json_file("res://data/config.json", "level", 10)
