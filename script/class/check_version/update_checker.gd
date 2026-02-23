class_name UpdateChecker
extends Node


func check(local: VersionInfo, server: UpdatePolicy) -> String:
	var base_version : int = VersionUtils.version_to_int(local.base_version)
	var min_supported_version : int = VersionUtils.version_to_int(server.min_supported_version)
	var equal_version: int = VersionUtils.version_to_int(local.equal_version)
	var target_version:int = VersionUtils.version_to_int(server.target_version)

	
	if equal_version >= target_version:
		return "UP_TO_DATE"
	
	if base_version < min_supported_version:
		server.force_full_package = true
		return "FULL_UPDATE_REQUIRED"
	
	if server.force_full_package:
		return "FULL_UPDATE_REQUIRED"
	
	if equal_version < target_version:
		return "NORMAL_UPDATE_REQUIRED"


	return "UNKNOWN_STATE"
