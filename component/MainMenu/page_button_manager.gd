extends Node

signal page_selected(page_index: int)

@export var buttons: Array[GlassIconPanel] = []
@export var initial_page: int = 1

var _current_page: int = -1
var _main_menu: Control = null

func _ready() -> void:
	await get_tree().process_frame
	_find_main_menu()
	_connect_buttons()
	_set_initial_page()

func _find_main_menu() -> void:
	var parent = get_parent()
	while parent:
		if parent.has_method("turn_to_page"):
			_main_menu = parent
			return
		parent = parent.get_parent()

func _connect_buttons() -> void:
	for i in range(buttons.size()):
		var btn = buttons[i]
		if btn == null:
			continue
		btn.pressed.connect(_on_button_pressed.bind(i))

func _set_initial_page() -> void:
	if buttons.size() == 0:
		return
	_select_page(initial_page)

func _on_button_pressed(index: int) -> void:
	_select_page(index)

func _select_page(index: int) -> void:
	if index < 0 or index >= buttons.size():
		return
	
	if _current_page >= 0 and _current_page < buttons.size():
		buttons[_current_page].is_selected = false
	
	_current_page = index
	buttons[index].is_selected = true
	
	page_selected.emit(index)
	
	if _main_menu:
		_main_menu.turn_to_page(index)

func get_current_page() -> int:
	return _current_page
