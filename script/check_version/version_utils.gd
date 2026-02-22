extends Node
##已设置为全局单例


func version_to_int(version: String) -> int:
	var parts = version.split(".")
	var result = 0
	for i in range(parts.size()):
		var num = parts[i].to_int()
		result = result * 10 + num
	return result

func int_to_version(num: int, part_count: int = 4) -> String:
	var parts = []
	var temp = num
	while parts.size() < part_count:
		parts.push_front(str(temp % 10))
		temp /= 10
		if temp == 0 and parts.size() >= 2:
			break
	while parts.size() < part_count:
		parts.push_front("0")
	return parts.join(".")
