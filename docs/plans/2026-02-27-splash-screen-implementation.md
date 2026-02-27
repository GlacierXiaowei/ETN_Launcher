# 开屏场景 (SplashScreen) 实现计划

> **For Claude:** 使用 subagent-driven-development 来逐步实现

**Goal:** 创建开屏场景，展示两张Logo后根据更新检查结果切换场景

**Architecture:** 使用 Tween 动画控制Logo切换，后台触发版本检查

**Tech Stack:** Godot 4.x, GDScript

---

### Task 1: 创建 splash_screen.gd 脚本

**Files:**
- Create: `res://script/scenes/splash/splash_screen.gd`

**Step 1: 创建脚本**

```gdscript
extends Control

@onready var logo_texture: TextureRect = $Background/LogoTexture

var logos: Array[String] = [
	"res://assets/image/boot_logo/logo_01.png",
    "res://assets/image/boot_logo/logo_02.png"
]
var current_logo_index: int = 0
var update_check_completed: bool = false
var need_update: bool = false

func _ready() -> void:
	_start_splash_sequence()

func _start_splash_sequence() -> void:
	_show_next_logo()
	_check_for_updates()

func _show_next_logo() -> void:
	if current_logo_index >= logos.size():
		_on_splash_finished()
		return
	
	logo_texture.texture = load(logos[current_logo_index])
	current_logo_index += 1
	
	await get_tree().create_timer(1.5).timeout
	_show_next_logo()

func _check_for_updates() -> void:
	update_check_completed = false
	# TODO: 调用 VersionUtils 检查更新
	# 暂时直接完成
	update_check_completed = true

func _on_splash_finished() -> void:
	while not update_check_completed:
		await get_tree().create_timer(0.1).timeout
	
	if need_update:
		SceneManager.switch_scene("res://scenes/launcher_update/launcher_update_check.tscn")
	else:
		SceneManager.switch_scene("res://scenes/main/main_menu.tscn")
```

**Step 2: 创建场景文件**

在 Godot 编辑器中创建:
- 创建目录: `res://scenes/splash/`
- 创建场景: `splash_screen.tscn`
- 节点结构:
  - SplashScreen (Control)
	- Background (ColorRect) - 深色背景
	  - LogoTexture (TextureRect) - 居中

**Step 3: 关联脚本**

在 Godot 中将 splash_screen.gd 附加到 SplashScreen 节点

---

### Task 2: 验证开屏流程

**测试步骤:**
1. 将 SplashScreen 设为启动场景
2. 运行项目，观察 Logo 切换
3. 确认1.5秒后自动切换

**预期结果:** 两张Logo各显示1.5秒后切换到主菜单
