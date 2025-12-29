# PatchManager.gd
# 把它设置为一个自动加载（AutoLoad）的单例，方便全局访问
extends Node
# --- 核心函数：扫描并加载所有未加载的补丁 ---
## 扫描 "user://patch" 目录，并加载所有尚未被引擎加载的 .pck 文件。
## 这个函数可以安全地多次调用。
func load_all_patches():
	print_rich("[color=cyan]开始扫描并加载补丁...[/color]")
	var patch_dir = "user://patch"
	# 1. 检查补丁目录是否存在，如果不存在就创建一个
	if not DirAccess.dir_exists_absolute(patch_dir):
		print("补丁目录 '%s' 不存在，将自动创建。" % patch_dir)
		var err = DirAccess.make_dir_recursive_absolute(patch_dir)
		if err == OK:
			print("目录创建成功。")
		else:
			print_rich("[color=red]目录创建失败！错误码: %s[/color]" % err)
		return # 既然目录是空的，就没必要继续了
	# 2. 打开目录进行扫描
	var dir = DirAccess.open(patch_dir)
	if not dir:
		print_rich("[color=red]错误：无法打开补丁目录！'%s'[/color]" % patch_dir)
		return
	# 3. 遍历目录中的每一个文件
	var newly_loaded_count = 0
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		# 确保我们处理的是文件，并且后缀是 .pck
		if not dir.current_is_dir() and file_name.ends_with(".pck"):
			var pck_path = patch_dir.path_join(file_name)
			print_rich("  [color=lightblue]发现新补丁，正在加载:[/color] %s" % file_name)
			if ProjectSettings.load_resource_pack(pck_path):
				print_rich("    [color=green]加载成功。[/color]")
				newly_loaded_count += 1
			else:
				print_rich("    [color=red]加载失败！[/color]")
		file_name = dir.get_next() # 继续处理下一个文件
	print_rich("[color=cyan]补丁加载流程结束。本次新加载了 %d 个补丁。[/color]" % newly_loaded_count)
