extends HBoxContainer

@onready var volume_slider=$HSlider
var master_bus_idx = AudioServer.get_bus_index("Master")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 1. 初始化滑块的位置
	# 获取 "Master" 音频总线的索引号 (通常是 0)
	
	
	# 获取该总线当前的的音量（单位是dB）
	var current_master_volume = AudioServer.get_bus_volume_db(master_bus_idx)
	# 将音量从 dB 转换回线性值 (0.0 to 1.0)，并赋给滑块
	volume_slider.value = db_to_linear(current_master_volume)
	# 2. 连接滑块的信号到我们的处理函数
	# 当滑块的值改变时 (value_changed)，就会调用 _on_volume_slider_changed 函数
	volume_slider.value_changed.connect(_on_volume_slider_changed)
# 当滑块的值发生变化时，这个函数会被自动调用
func _on_volume_slider_changed(new_value: float):
	# `new_value` 是滑块的当前线性值 (0.0 to 1.0)
	# 获取 "Master" 音频总线的索引号
	#var master_bus_idx = AudioServer.get_bus_index("Master")
	
	# 将线性值转换为分贝(dB)值，并设置给音频总线
	# 注意：当 new_value 为 0 时，linear_to_db 会返回 -inf (负无穷)，这会使声音完全静音
	AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(new_value))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var volume_text=str(int($HSlider.value*100))
	$HSlider/Label2.text=volume_text
	pass
