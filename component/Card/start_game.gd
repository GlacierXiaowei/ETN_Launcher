extends Node
class_name StartGame

@onready var card_panel: Node2D = $".."
@onready var install_component: InstallComponent = $"../InstallComponent"
@onready var game_card: GameCard = $"../GameCard"

##注意 pid文件名为小写！ 但是本身的exe命名是正常的
var game_name : String 
var user_path : String
var boot_path : String

## 游戏进程 ID
var game_pid : int = -1

signal boot_successful
signal boot_failed 

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
	
	# 步骤 4：启动游戏进程（不检查返回值，以轮询检测为准）
	OS.create_process(boot_path, [])
	
	# 步骤 5：异步轮询检测游戏进程（最多检测 10 秒）
	var success = await _wait_for_game_boot()
	
	if success:
		print("[StartGame] 游戏启动成功，进程 ID: ", game_pid)
		# 切换到运行中状态
		card_panel.node_state_machine.transition_to("runningstate")
		boot_successful.emit()
	else:
		push_error("[StartGame] 游戏进程未找到，启动超时")
		boot_failed.emit()
		PopupManager.show_alert(
			"启动失败",
			"无法启动游戏。\n\n可能的原因：\n- 游戏文件损坏\n- 杀毒软件阻止\n- 系统权限不足",
			func(): pass
		)

##为了防止混淆 我们启动器的PID将会写入到游戏数据目录 游戏的PID将会写到启动器的用户数据目录
## 检查游戏是否正在运行
func is_game_running() -> bool:
	# 尝试读取游戏 PID 文件
	var temp : String = "." + game_name.to_lower() + "_pid"
	var pid_file_path =	OS.get_environment("APPDATA").path_join("ETN_Launcher").path_join(temp)
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
		# 使用 CSV 格式输出，便于解析
		var exit_code = OS.execute("tasklist", ["/FI", "PID eq " + str(game_pid), "/NH", "/FO", "CSV"], output)
		if exit_code == 0 and output.size() > 0:
			# CSV 格式："进程名","PID","会话名"... 检查是否包含 PID
			return str(game_pid) in output[0]
	
	return false

## 写入启动器 PID 文件到游戏的用户数据目录
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


## 异步轮询检测游戏进程是否启动
## 返回：true = 启动成功，false = 启动失败（超时）
func _wait_for_game_boot() -> bool:
	var check_count = 0
	const max_check_count = 20  # 0.5 秒 * 20 = 10 秒超时
	
	while check_count < max_check_count:
		await get_tree().create_timer(0.5).timeout
		if is_game_running():
			return true
		check_count += 1
	
	return false
