extends Node
class_name SetUpInfo

enum UpdateStatus {
	IDLE,                   # 初始状态
	CHECKING,               # 正在检查更新
	NEEDS_UPDATE,           # 有更新可用 (一个通用状态)
	UP_TO_DATE,             # 已是最新版本
	NOT_INSTALLED,          # 未安装
	DOWNLOADING,            # 正在下载
	UNZIPPING,              # 正在解压
	INSTALL_COMPLETE,       # 安装/更新完成

	# 错误状态
	FAIL_TO_CHECK,          # 检查更新失败
	DOWNLOAD_FAILED,        # 下载失败
	FAIL_TO_UNZIP,          # 解压失败

}


#static 静态变量 才可以 直接按照类的形式访问
#当前应该检查更新的类型 可以选择 ETN_Laucher  ETN  none  only(只需要检查更新 获取版本信息)
static  var version_check_type: String = "Launcher"


# 版本信息变量
static  var local_launcher_version_str = "v1.0.0.1"
static  var local_game_version_str = "v0.0.0.0"

static  var local_launcher_version_int = 1001
static  var local_game_version_int = 0
#是否需要更新
static var launcher_need_setup = false
static var game_need_setup = false
#是否需要连续检查 
static var contious_version_check = true

# 远程更新信息
static var remote_launcher_info = {}
static var remote_game_info = {}
static var game_patches_to_download = []
#↓ 无需辨别的类型
static var remote_version_info ={}

# 下载进度与状态变量
static var download_progress: float = 0.0
static var download_current_size_mb: float = 0.0
static var download_total_size_mb: float = 0.0
static var download_speed_mbps: float = 0.0
static var download_description: String = ""
static var is_downloading: bool = false

#补丁or全量
static var patch:bool=true

# 兼容旧代码的状态变量
var game_status: int = UpdateStatus.IDLE

# 信号定义
signal update_status_changed(new_status)


static func get_status_message(status: UpdateStatus) -> String:
	match status:
		UpdateStatus.IDLE:
			return "准备就绪"
		UpdateStatus.CHECKING:
			return "正在检查更新..."
		UpdateStatus.NEEDS_UPDATE:
			return "发现新版本！"
		UpdateStatus.UP_TO_DATE:
			return "已是最新版本"
		UpdateStatus.NOT_INSTALLED:
			return "游戏未安装"
		UpdateStatus.DOWNLOADING:
			return "正在下载..."
		UpdateStatus.UNZIPPING:
			return "正在解压文件..."
		UpdateStatus.INSTALL_COMPLETE:
			return "安装/更新完成！"
		UpdateStatus.FAIL_TO_CHECK:
			return "检查更新失败，请检查网络连接"
		UpdateStatus.DOWNLOAD_FAILED:
			return "下载失败，请重试"
		UpdateStatus.FAIL_TO_UNZIP:
			return "解压失败，文件可能已损坏"
		_:
			return "未知状态"
