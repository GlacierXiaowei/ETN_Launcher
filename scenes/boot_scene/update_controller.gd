extends Node
class_name UpdateController

signal state_changed(state: int)

enum State { STATE_CHECKING, STATE_UP_TO_DATE, STATE_NEED_UPDATE, STATE_CHECK_FAILED }

var install_component: InstallComponent
var current_state: int = State.STATE_CHECKING
var launcher_game_name: String = "ETN_Launcher"
var launcher_dir: String

func _ready() -> void:
	launcher_dir = ProjectSettings.globalize_path("res://data/")
	_init_install_component()

func _init_install_component() -> void:
	var scene = load("res://component/InstallComponent/install_component.tscn")
	install_component = scene.instantiate()
	
	install_component.game_name = launcher_game_name
	install_component.game_dir = launcher_dir
	# 关键：必须覆盖 user_path，因为 InstallComponent 初始化时已经计算好了
	install_component.user_path = launcher_dir
	
	install_component.update_state_changed.connect(_on_update_state_changed)
	install_component.update_error_occurred.connect(_on_update_error)
	
	add_child(install_component)

func _on_update_state_changed(state: InstallSignalHub.InstallState) -> void:
	match state:
		InstallSignalHub.InstallState.CHECKING_UPDATE:
			_set_state(State.STATE_CHECKING)
		InstallSignalHub.InstallState.UP_TO_DATE:
			_set_state(State.STATE_UP_TO_DATE)
		InstallSignalHub.InstallState.NEED_UPDATE:
			_set_state(State.STATE_NEED_UPDATE)
		InstallSignalHub.InstallState.CHECK_FAILED:
			_set_state(State.STATE_CHECK_FAILED)

func _set_state(new_state: int) -> void:
	current_state = new_state
	state_changed.emit(new_state)

func on_primary_button_pressed() -> void:
	match current_state:
		State.STATE_UP_TO_DATE:
			pass
		State.STATE_NEED_UPDATE:
			install_component._on_下载_pressed()
		State.STATE_CHECK_FAILED:
			install_component.re_ready()

func on_secondary_button_pressed() -> void:
	pass

func _on_update_error(error_message: String) -> void:
	printerr("[UpdateController] 错误：", error_message)

func get_update_notes() -> String:
	if install_component and install_component._server:
		return install_component._server.update_notes
	return ""

func get_error_message() -> String:
	if install_component and install_component._server:
		return install_component._server.err_notes
	return ""
