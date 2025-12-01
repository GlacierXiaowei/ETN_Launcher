extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_website_meta_clicked(meta: Variant) -> void:
	var meta_str=str(meta)
	if meta_str=="glacier_xiaowei@163.com":
		DisplayServer.clipboard_set(meta_str)
		pass
	else:
		OS.shell_open(meta_str)
		
	pass # Replace with function body.
