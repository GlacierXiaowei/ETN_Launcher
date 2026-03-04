extends Node
class_name StartGame

@onready var card_panel: Node2D = $".."
@onready var install_component: InstallComponent = $"../InstallComponent"
@onready var game_card: GameCard = $"../GameCard"

var game_name : String 
var user_path : String
var boot_path : String

## 游戏进程 ID
var game_pid : int = -1

func _ready() -> void:
	game_name = install_component.game_name
	user_path = install_component.user_path
	# 构建游戏启动路径
	boot_path = user_path.path_join(game_name + ".exe")
	
## 启动游戏
func start_game() -> void:
	# 步骤 1：检查游戏可执行文件是否存在
	if not FileAccess.file_exists(boot_path):
		push_error("[StartGame] 游戏可执行文件不存在：" + boot_path)
		PopupManager.show_alert(
			"启动失败",
			"找不到游戏可执行文件。\n路径：" + boot_path + "\n\n请检查游戏是否已正确安装。",
			func(): pass
		)
		install_component.update_state_changed.emit(InstallSignalHub.InstallState.NOT_INSTALLED)
		return
	
	# 步骤 2：检查游戏是否已经在运行
	if is_game_running():
		PopupManager.show_confirm(
			"游戏运行中",
			"游戏已经在运行中。\n\n进程 ID: " + str(game_pid) + "\n\n是否重新启动？（将关闭当前运行的游戏）",
			_on_restart_confirm,
			func(): pass
		)
		return
	
	# 步骤 3：写入启动器 PID 文件（防破解验证）
	if not _write_launcher_pid():
		push_error("[StartGame] 写入启动器 PID 文件失败")
		PopupManager.show_alert(
			"启动失败",
			"无法写入启动器验证文件。\n\n请检查磁盘权限或联系技术支持。",
			func(): pass
		)
		return
	
	# 步骤 4：启动游戏进程
	var error = OS.create_process(boot_path, [])
	if error != 0:
		push_error("[StartGame] 启动游戏失败，错误码：" + str(error))
		PopupManager.show_alert(
			"启动失败",
			"无法启动游戏。\n错误码：" + str(error) + "\n\n可能的原因：\n- 游戏文件损坏\n- 杀毒软件阻止\n- 系统权限不足",
			func(): pass
		)
		return
	
	# 步骤 5：等待游戏进程启动
	await get_tree().create_timer(1.0).timeout
	
	# 步骤 6：验证游戏是否成功启动
	if is_game_running():
		print("[StartGame] 游戏启动成功，进程 ID: ", game_pid)
		# 切换到运行中状态
		card_panel.node_state_machine.transition_to("runningstate")
	else:
		push_error("[StartGame] 游戏进程未找到，可能启动失败")
		PopupManager.show_alert(
			"启动异常",
			"游戏进程已启动但无法检测到。\n\n请检查游戏是否正常运行。",
			func(): pass
		)

## 检查游戏是否正在运行
func is_game_running() -> bool:
	# 尝试读取游戏 PID 文件
	var pid_file_path = user_path.path_join(".game_pid")
	if not FileAccess.file_exists(pid_file_path):
		return false
	
	var file = FileAccess.open(pid_file_path, FileAccess.READ)
	if file == null:
		return false
	
	var pid_str = file.get_as_text().strip_edges()
	file.close()
	
	if pid_str.is_empty():
		return false
	
	game_pid = pid_str.to_int()
	if game_pid <= 0:
		return false
	
	# 检查进程是否存在（Windows）
	if OS.has_feature("windows"):
		var output = []
		# Godot 4.x: OS.execute(command, arguments, output_array)
		var exit_code = OS.execute("tasklist", ["FI", "PID eq " + str(game_pid), "/NH"], output)
		if exit_code == 0 and output.size() > 0 and not output[0].is_empty():
			return true
	
	return false

## 写入启动器 PID 文件到游戏用户数据目录
func _write_launcher_pid() -> bool:
	var launcher_pid = OS.get_process_id()
	var pid_file_path = user_path.path_join(".etn_launcher_pid")
	
	var file = FileAccess.open(pid_file_path, FileAccess.WRITE)
	if file == null:
		push_error("[StartGame] _write_launcher_pid: 无法创建文件：" + pid_file_path)
		return false
	
	file.store_string(str(launcher_pid))
	file.close()
	
	print("[StartGame] 已写入启动器 PID 文件：", pid_file_path, " PID: ", launcher_pid)
	return true

## 重新启动游戏（关闭当前进程后启动）
func _on_restart_confirm() -> void:
	if game_pid > 0:
		# 尝试终止游戏进程
		OS.kill(game_pid)
		await get_tree().create_timer(2.0).timeout
	
	# 重新启动游戏
	start_game()
