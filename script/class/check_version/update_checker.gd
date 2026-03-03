class_name UpdateChecker
extends Node

signal state_changed(state: InstallSignalHub.InstallState)
signal error_occurred(error_message: String)


func check(local: VersionInfo, server: UpdatePolicy) -> String:
	state_changed.emit(InstallSignalHub.InstallState.CHECKING_UPDATE)
	
	var base_version : int = VersionUtils.version_to_int(local.base_version)
	var min_supported_version : int = VersionUtils.version_to_int(server.min_supported_version)
	var equal_version: int = VersionUtils.version_to_int(local.equal_version)
	var target_version:int = VersionUtils.version_to_int(server.target_version)

	if equal_version >= target_version:
		state_changed.emit(InstallSignalHub.InstallState.UP_TO_DATE)
		return "UP_TO_DATE"
	
	if base_version < min_supported_version:
		server.force_full_package = true
		state_changed.emit(InstallSignalHub.InstallState.CHECK_FAILED)
		error_occurred.emit("Base version below minimum supported version")
		return "FULL_UPDATE_REQUIRED"
	
	if server.force_full_package:
		state_changed.emit(InstallSignalHub.InstallState.CHECK_FAILED)
		error_occurred.emit("Server requires full package update")
		return "FULL_UPDATE_REQUIRED"
	
	if equal_version < target_version:
		return "NORMAL_UPDATE_REQUIRED"

	return "UNKNOWN"
