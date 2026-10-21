extends Control

@onready var logo_texture: TextureRect = $PanelContainer/LogoTexture
@onready var panel_container: PanelContainer = $PanelContainer
@onready var update_controller: UpdateController = $UpdateController
@onready var status_label: Label = $Control/ColorRect/MarginContainer/VBoxContainer/Label
@onready var rich_label: RichTextLabel = $Control/ColorRect/MarginContainer/VBoxContainer/RichTextLabel
@onready var primary_button: Button = $Control/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/Button1
@onready var secondary_button: Button = $Control/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/Button2

var logos: Array[String] = [
	"res://assets/image/boot_logo/logo_01.png",
    "res://assets/image/boot_logo/logo_02.png"
]
var current_logo_index: int = 0
var need_update: bool = true
var update_check_completed: bool = false
var splash_animation_completed: bool = false

func _ready() -> void:
	_connect_signals()
	_start_splash_sequence()

func _connect_signals() -> void:
	update_controller.state_changed.connect(_on_update_state_changed)
	primary_button.pressed.connect(_on_primary_button_pressed)
	secondary_button.pressed.connect(_on_secondary_button_pressed)

func _start_splash_sequence() -> void:
	_show_next_logo()

func _show_next_logo() -> void:
	if current_logo_index >= logos.size():
		_on_splash_finished()
		return
	
	logo_texture.texture = load(logos[current_logo_index])
	current_logo_index += 1
	
	await get_tree().create_timer(2.0).timeout
	_show_next_logo()

func _on_splash_finished() -> void:
	splash_animation_completed = true
	var tween = create_tween()
	tween.tween_property(panel_container, "modulate:a", 0.0, 0.5)
	panel_container.visible = false
	_check_and_enter()

func _on_update_state_changed(state: int) -> void:
	match state:
		UpdateController.State.STATE_CHECKING:
			_update_ui_checking()
		UpdateController.State.STATE_UP_TO_DATE:
			_update_ui_up_to_date()
		UpdateController.State.STATE_NEED_UPDATE:
			_update_ui_need_update()
		UpdateController.State.STATE_CHECK_FAILED:
			_update_ui_check_failed()

func _update_ui_checking() -> void:
	status_label.text = "正在检查更新"
	rich_label.text = "正在检查启动器更新，请稍候..."
	primary_button.text = "请稍后"
	primary_button.disabled = true
	secondary_button.visible = false

func _update_ui_up_to_date() -> void:
	status_label.text = "已是最新版本"
	rich_label.text = "启动器已是最新版本，祝您游戏愉快！"
	need_update = false
	update_check_completed = true
	primary_button.text = "直接进入"
	primary_button.disabled = false
	secondary_button.visible = false
	_check_and_enter()

func _update_ui_need_update() -> void:
	status_label.text = "需要更新"
	need_update = true
	update_check_completed = true
	primary_button.text = "下载更新"
	primary_button.disabled = false
	secondary_button.visible = false
	
	var notes = update_controller.get_update_notes()
	rich_label.text = "[color=yellow]发现新版本[/color]\n\n" + notes
	rich_label.text += "\n\n[color=cyan]请点击【下载更新】，根据提示完成更新。[/color]"

func _update_ui_check_failed() -> void:
	status_label.text = "检查更新失败"
	update_check_completed = true
	primary_button.text = "重试"
	primary_button.disabled = false
	secondary_button.text = "离线进入"
	secondary_button.visible = true
	
	var error = update_controller.get_error_message()
	rich_label.text = "[color=red]检查更新失败[/color]\n\n"
	rich_label.text += "错误信息：" + error + "\n\n"
	rich_label.text += "您可以选择：\n"
	rich_label.text += "1. 点击【重试】重新检查更新\n"
	rich_label.text += "2. 点击【离线进入】继续使用当前版本"

func _check_and_enter() -> void:
	if splash_animation_completed and update_check_completed and not need_update:
		await get_tree().create_timer(0.5).timeout
		_enter_main_menu()

func _enter_main_menu() -> void:
	SceneManager.switch_scene("res://scenes/main_menu/main_menu.tscn")

func _on_primary_button_pressed() -> void:
	update_controller.on_primary_button_pressed()

func _on_secondary_button_pressed() -> void:
	update_controller.on_secondary_button_pressed()
	_enter_main_menu()
