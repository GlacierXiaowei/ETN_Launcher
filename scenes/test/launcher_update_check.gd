extends Control

#@onready var background: ColorRect = $Background
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var update_notes: RichTextLabel = $CenterContainer/VBoxContainer/UpdateNotes
@onready var button_container: HBoxContainer = $CenterContainer/VBoxContainer/ButtonContainer
@onready var primary_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/PrimaryButton
@onready var secondary_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/SecondaryButton
@onready var loading_spinner: TextureRect = $LoadingSpinner

@onready var center_container: CenterContainer = $CenterContainer

var _glass_card: ColorRect = null

var install_component: Node = null
var is_checking: bool = true
var is_force_update: bool = false

func _ready() -> void:
	_apply_test_theme()
	_setup_glass_card()
	_init_install_component()
	_resync_glass_card_layout()
	resized.connect(_resync_glass_card_layout)


func _apply_test_theme() -> void:
	# Note: We inject theme + glass at runtime to avoid editing .tscn directly.
	var factory = load("res://script/ui/theme/etn_theme_factory.gd")
	if factory:
		factory.apply_glass_theme(self)

	# 对当前场景的两个按钮做主次区分（即使主题资源不存在，也能有明显层级）。
	# 主按钮：更亮
	primary_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	# 次按钮：更低对比
	secondary_button.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92, 1))

	status_label.add_theme_font_size_override("font_size", 26)
	update_notes.add_theme_font_size_override("normal_font_size", 16)


func _setup_glass_card() -> void:
	# Create a glass card under CenterContainer (background layer).
	if _glass_card != null:
		return

	var factory = load("res://script/ui/theme/etn_theme_factory.gd")
	if not factory:
		return

	_glass_card = factory.create_glass_card()
	_glass_card.anchors_preset = Control.PRESET_FULL_RECT
	_glass_card.offset_left = 0
	_glass_card.offset_top = 0
	_glass_card.offset_right = 0
	_glass_card.offset_bottom = 0

	center_container.add_child(_glass_card)
	center_container.move_child(_glass_card, 0)

	# If BackGround exists, enable it to improve glass readability.
	if has_node("BackGround"):
		var bg: Control = $BackGround
		bg.visible = true


func _resync_glass_card_layout() -> void:
	if _glass_card == null:
		return

	# Layout: keep a stable card size first. We can later make it follow VBoxContainer size.
	var target_size = Vector2(720, 420)
	if size.x < 900:
		target_size.x = max(520, size.x - 120)
		target_size.y = 420

	_glass_card.custom_minimum_size = target_size
	_glass_card.size = target_size
	_glass_card.position = (center_container.size - target_size) * 0.5

	# Important: sync the card pixel size into shader parameters.
	var mat := _glass_card.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("rect_size_px", _glass_card.size)

func _init_install_component() -> void:
	button_container.visible = true
	loading_spinner.visible = true
	status_label.text = "正在检查更新..."
	update_notes.text = ""
	is_checking = true
	
	primary_button.disabled = true
	_show_buttons("请稍后", "retry", "download")
	
	
	install_component = load("res://component/UpdateManager/install_component.tscn").instantiate()
	install_component.repo_name = "ETN_Launcher"
	install_component.update_needed_state_signal.connect(_on_update_check_completed)
	add_child(install_component)


func _on_update_check_completed(result: String) -> void:
	is_checking = false
	loading_spinner.visible = false
	button_container.visible = true
	
	primary_button.disabled = false
	
	is_force_update = install_component.is_force_update
	
	match result:
		"UP_TO_DATE":
			_show_buttons("进入", "", "enter")
		"FULL_UPDATE_REQUIRED", "NORMAL_UPDATE_REQUIRED":
			if is_force_update:
				status_label.text = "需要更新"
				_show_buttons("下载更新", "", "download")
			else:
				status_label.text = "需要注意"
				_show_buttons("下载更新", "离线进入", "download")
		"ERROR":
			status_label.text = "发生错误"
			_show_buttons("重试", "离线进入", "retry")

func _show_buttons(primary_text: String, secondary_text: String, action: String) -> void:
	primary_button.text = primary_text
	primary_button.disabled = false
	primary_button.set_meta("action", action)
	
	if secondary_text != "":
		secondary_button.visible = true
		secondary_button.text = secondary_text
		secondary_button.disabled = false
		secondary_button.set_meta("action", "skip")
	else:
		secondary_button.visible = false

func _on_primary_button_pressed() -> void:
	var action = primary_button.get_meta("action")
	match action:
		"enter":
			_go_to_main_menu()
		"download":
			_start_download()
		"retry":
			_retry_check()

func _on_secondary_button_pressed() -> void:
	var action = secondary_button.get_meta("action")
	match action:
		"skip":
			_go_to_main_menu()

func _start_download() -> void:
	primary_button.disabled = true
	primary_button.text = "下载中..."
	secondary_button.disabled = true
	status_label.text ="请直接运行新客户端"
	install_component._on_下载_pressed()


func _retry_check() -> void:
	install_component.queue_free()
	_init_install_component()

func _go_to_main_menu() -> void:
	SceneManager.switch_scene("res://scenes/main/main_menu.tscn")
