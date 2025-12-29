extends Node

# =============================================================================
# Utils - 全局工具箱
# -----------------------------------------------------------------------------
# 这个 Autoload 脚本存放项目中任何地方都可能用到的通用辅助函数。
# 例如：版本号转换、文件操作、数学计算等。
# 保持这里的函数通用、无副作用，不要和特定的业务逻辑耦合。
# =============================================================================


## 将 "v1.2.3.4" 格式的版本字符串转换为整数，便于比较。
## v1.2.3.4  -> 1234
## v1.10.2.0 -> 11020 (正确处理两位数版本号)
## v1.2.3    -> 1230 (自动补零)
## 返回 0 表示转换失败。
func version_string_to_int(version_str: String) -> int:
	if not version_str.begins_with("v"):
		return 0
	
	var parts: PackedStringArray = version_str.trim_prefix("v").split(".", false) # `false` 避免移除空条目
	
	var major: int = 0
	var minor: int = 0
	var patch: int = 0
	var revision: int = 0
	
	if parts.size() >= 1:
		major = parts[0].to_int()
	if parts.size() >= 2:
		minor = parts[1].to_int()
	if parts.size() >= 3:
		patch = parts[2].to_int()
	if parts.size() >= 4:
		revision = parts[3].to_int()

	# 使用权重系统来组合版本号，确保 v1.10.0 (1*1000 + 10*100 = 2000) 
	# 和 v1.1.0 (1*1000 + 1*100 = 1100) 不会混淆。
	# 这里我们假设每个版本号部分不会超过100。
	# 为了安全，我们用更大的基数
	var version_int = major * 1000000 + minor * 10000 + patch * 100 + revision
	
	return version_int
