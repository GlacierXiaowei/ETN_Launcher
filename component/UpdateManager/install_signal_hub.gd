extends Node
class_name InstallSignalHub

enum InstallState {
	CHECKING_UPDATE,
	NEED_UPDATE,
	CHECK_FAILED,
	UP_TO_DATE,
	DOWNLOAD_STARTED,
	DOWNLOAD_FINISHED,
	INSTALL_STARTED,
	INSTALL_FINISHED
}

signal state_changed(state: InstallState)
signal error_occurred(error_message: String)

var _connected_installers: Array = []

func register_installer(installer: Node) -> void:
	if installer in _connected_installers:
		return
	_connected_installers.append(installer)
	
	if installer.has_signal("state_changed"):
		installer.state_changed.connect(_on_installer_state_changed.bind(installer))
	if installer.has_signal("error_occurred"):
		installer.error_occurred.connect(_on_installer_error)

func unregister_installer(installer: Node) -> void:
	if not installer in _connected_installers:
		return
	_connected_installers.erase(installer)
	
	if installer.has_signal("state_changed"):
		installer.state_changed.disconnect(_on_installer_state_changed.bind(installer))
	if installer.has_signal("error_occurred"):
		installer.error_occurred.disconnect(_on_installer_error)

func _on_installer_state_changed(state: InstallState, _installer: Node) -> void:
	state_changed.emit(state)

func _on_installer_error(error_message: String) -> void:
	error_occurred.emit(error_message)

func _exit_tree() -> void:
	for installer in _connected_installers.duplicate():
		if is_instance_valid(installer):
			unregister_installer(installer)
