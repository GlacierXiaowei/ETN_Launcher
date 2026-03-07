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
@onready var zhe_zhao: ColorRect = $ZheZhao


##注意 设置就是0页
@export var current_page = 1

var _turn_page_enable : bool  = false

func _ready() -> void:
	#call_deferred("add_card") 
	await get_tree().process_frame
	card_panel.visible = true
	card_panel_2.visible = false
	card_panel_3.visible = false
	
	
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
		if not _turn_page_enable :
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			turn_to_page(current_page - 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			turn_to_page(current_page + 1)

##同时调用动画 同时计数 同时处理页面重复/超出
func turn_to_page(target_page : int) -> void:
	_turn_page_enable = false
	
	target_page = clamp(target_page , 0 , 3)
	if current_page == target_page:
		return
	
	##阻止点击
	zhe_zhao.mouse_filter = Control.MOUSE_FILTER_STOP
	page_animation.turn_to_page(current_page,target_page)
	if target_page !=0 :
		current_page = target_page
	await get_tree().create_timer(0.8).timeout
	zhe_zhao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	
	_turn_page_enable = true


func _on_card_panel_card_selected() -> void:
	_turn_page_enable = false


func _on_card_panel_card_deselected() -> void:
	_turn_page_enable = true
