extends Control

@onready var logo_texture: TextureRect = $PanelContainer/LogoTexture
@onready var panel_container: PanelContainer = $PanelContainer


var logos: Array[String] = [
	"res://assets/image/boot_logo/logo_01.png",
    "res://assets/image/boot_logo/logo_02.png"
]
var current_logo_index: int = 0
var update_check_completed: bool = false
var update_check_successful: bool = false
var need_update: bool = true

func _ready() -> void:
	_start_splash_sequence()

func _start_splash_sequence() -> void:
	_show_next_logo()


func _show_next_logo() -> void:
	if current_logo_index >= logos.size():
		_on_splash_finished()
		return
	
	logo_texture.texture = load(logos[current_logo_index])
	current_logo_index += 1
	
	await get_tree().create_timer(2.0).timeout
	_show_next_logo()


func _on_splash_finished() -> void:
	
	var tween = create_tween()
	# Panel透明度1 -> 0
	tween.tween_property(
		panel_container,
		"modulate:a",
		0.0,
		0.5
	)
	panel_container.visible = false


func _on_install_component_update_needed_state_signal(result : String) -> void:
	update_check_completed = true
	if result == "UP_TO_DATE":
		need_update = false
	else :
		need_update = true
