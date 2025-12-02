extends HBoxContainer
@onready var option_button = $OptionButton

#如果只是 该场景启动1会因为地址不对而报错
@onready var audio_player = get_node("/root/Main/menu_bg/menu_music")
# 【技巧】使用 @export，可以直接在编辑器里把音乐文件拖进来！
@export var music_tracks: Array[AudioStream] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 1. 填充 OptionButton，并关联元数据
	_populate_music_options()
	
	# 2. 根据当前播放的音乐，设置初始选中项
	_update_selection_from_player()
	
	# 3. 连接信号，以便用户选择时可以切换音乐
	option_button.item_selected.connect(_on_music_selected)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
# 负责填充OptionButton
func _populate_music_options() -> void:
	option_button.clear()
	for track in music_tracks:
		if track:
			# 从文件路径中获取一个干净的名字作为显示文本
			var display_name = track.resource_path.get_file().get_basename().capitalize()
			option_button.add_item(display_name)
			# 【核心】将 AudioStream 资源本身作为元数据附加到刚添加的项目上
			var index = option_button.get_item_count() - 1
			option_button.set_item_metadata(index, track)

# 负责根据播放器状态更新UI
func _update_selection_from_player() -> void:
	var current_stream = audio_player.stream
	# 如果当前没有设置音乐，就不用继续了
	if not current_stream:
		return
		
	# 遍历所有选项，查找匹配项
	for i in option_button.get_item_count():
		var item_stream = option_button.get_item_metadata(i)
		
		# 直接比较两个资源对象是否相同
		if item_stream == current_stream:
			# 找到了！设置选中项并停止循环
			option_button.selected = i
			print("初始音乐 '", current_stream.resource_path, "' 匹配到索引 ", i)
			break
			
# 当用户从下拉列表中选择新音乐时调用
func _on_music_selected(index: int) -> void:
	# 从元数据中获取要播放的音乐资源
	var selected_stream = option_button.get_item_metadata(index)
	# 只有当选择的音乐和当前的不同时才切换，避免不必要地重播
	if audio_player.stream != selected_stream:
		audio_player.stream = selected_stream
		audio_player.play()
		print("切换到音乐: ", selected_stream.resource_path)
