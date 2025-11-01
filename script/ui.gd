extends Control

@onready var menus = {
	"master": $master_menu,
	"setting": $setting_menu,
	"about": $about_menu,
	"donation": $donation_menu,
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for menu in menus.values():
		if menu != $master_menu:
			menu.modulate.a = 0.0
			#menu.visible = false
	
		
	$master_menu/ui_show_animation.play("ui_show_animation")
	await $master_menu/ui_show_animation.animation_finished
	$zhe_zhao2.hide()
	
	#$quit.hide()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_return_pressed() -> void:
	$zhe_zhao2.show()
	
	var master_menu_in = $".".create_tween()
	master_menu_in.parallel().tween_property($master_menu,"modulate:a",1.0,0.5)
	for menu in menus.values():
		if ((menu != $master_menu) && menu.modulate.a == 1.0) :
			
			#这里 如果两个动画 不并行播放的话 就会导致 一个在执行的时候 另外一个 不执行 
			#并行就是 两个动画 共用一个 tween 并且使用 parallel 
			#只是说 这样就不能 用名字区分了 所以 注意这里的名字
			master_menu_in.parallel().tween_property(menu,"modulate:a",0.0,0.5)
	
	await get_tree().create_timer(0.5).timeout
	$zhe_zhao2.hide()
			
	# 遍历所有菜单
	

	 # Replace with function body.
