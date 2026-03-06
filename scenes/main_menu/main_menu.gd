extends Control

##之前一直有重载问题 现在只能动态添加
##现在引用不能使用@onready免得出问题
#var card_panel : Control 
#var card_panel_2 : Control
#var card_panel_3  :Control 
@onready var card_panel: Control = $CardPanel
@onready var card_panel_2: Control = $CardPanel2
@onready var card_panel_3: Control = $CardPanel3

@onready var page_animation: Node = $Component/PageAnimation
@onready var page_switcher: Node = $Component/PageSwitcher

##注意 设置就是0页
@export var current_page = 1

var _turn_page_enable : bool  = false

func _ready() -> void:
	#call_deferred("add_card") 
	await get_tree().process_frame
	card_panel.visible = false
	card_panel_2.visible = false
	card_panel_3.visibal = false
	
	
	_turn_page_enable = true
	

#func add_card () -> void:
	#var card_2_load = load("res://scenes/card/card_panel.tscn")
	#var card_3_load = load("res://scenes/card/card_panel.tscn")
	#
	#card_panel_2 = card_2_load.instantiate()
	#card_panel_3 = card_3_load.instantiate()
	#
	#card_panel_2.visible = false
	#card_panel_3.visible = false
	#
	#add_child(card_panel_2)
	#add_child(card_panel_3)


##备注：向下滚就是翻下一页哈
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			print("滚轮向上")
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			print("滚轮向下")

##同时调用动画 同时计数 同时处理页面重复/超出
func turn_to_page(target_page : int) -> void:
	
	await get_tree().create_timer(0.45).timeout


func _on_card_panel_card_selected() -> void:
	_turn_page_enable = false


func _on_card_panel_card_deselected() -> void:
	_turn_page_enable = true
