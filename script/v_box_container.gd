extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_settings_pressed() -> void:
	$"../../setting_menu".show()
	$"../../zhe_zhao2".show()
	var master_menu_out = $".".create_tween()
	master_menu_out.tween_property($"..","modulate:a",0.0,0.5)
	#$"..".visible = false
	var setting_menu_in =$"." .create_tween()
	setting_menu_in.tween_property($"../../setting_menu","modulate:a",1.0,0.5)
	await get_tree().create_timer(0.5).timeout
	$"../../zhe_zhao2".hide()
	$"../../about_menu".hide()
	$"../../donation_menu".hide()
	pass # Replace with function body.


func _on_about_pressed() -> void:
	$"../../about_menu".show()
	$"../../zhe_zhao2".show()
	var master_menu_out = $".".create_tween()
	master_menu_out.tween_property($"..","modulate:a",0.0,0.5)
	#$"..".visible = false
	var about_menu_in = $".".create_tween()
	about_menu_in.tween_property($"../../about_menu","modulate:a",1.0,0.5)
	await get_tree().create_timer(0.5).timeout
	$"../../zhe_zhao2".hide()
	$"../../setting_menu".hide()
	$"../../donation_menu".hide()
	pass # Replace with function body.
	
	


func _on_donation_pressed() -> void:
	$"../../donation_menu".show()
	$"../../zhe_zhao2".show()
	var master_menu_out = $".".create_tween()
	master_menu_out.tween_property($"..","modulate:a",0.0,0.5)
	#$"..".visible = false
	var donation_menu_in = $".".create_tween()
	donation_menu_in.tween_property($"../../donation_menu","modulate:a",1.0,0.5)
	await get_tree().create_timer(0.5).timeout
	$"../../zhe_zhao2".hide()
	$"../../about_menu".hide()
	$"../../setting_menu".hide()
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.
