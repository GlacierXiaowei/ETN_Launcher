extends Control

#@onready var background: ColorRect = $Background
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var update_notes: RichTextLabel = $CenterContainer/VBoxContainer/UpdateNotes
@onready var button_container: HBoxContainer = $CenterContainer/VBoxContainer/ButtonContainer
@onready var primary_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/PrimaryButton
@onready var secondary_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/SecondaryButton
@onready var loading_spinner: VideoStreamPlayer = $LoadingSpinner

var install_component: Node = null
var is_checking: bool = true
var is_force_update: bool = false

func _ready() -> void:
	_init_install_component()

func _init_install_component() -> void:
	button_container.visible = true
	loading_spinner.visible = true
	status_label.text = "正在检查更新..."
	update_notes.text = ""
	is_checking = true
	
	_show_buttons("请稍后", "", "download")
	primary_button.disabled = true
	
	
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
