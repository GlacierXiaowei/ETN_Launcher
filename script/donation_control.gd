extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_rich_text_label_1_meta_clicked(meta: Variant) -> void:
	var meta_str=str(meta)
	if meta_str=="fu_kuan_ma":
		if ($alipay.modulate.a==0.0 and $we_chat_pay.modulate.a==0.0):
			$alipay.modulate.a=1.0
			$we_chat_pay.modulate.a=1.0
		else:
			$alipay.modulate.a=0.0
			$we_chat_pay.modulate.a=0.0
	pass # Replace with function body.
