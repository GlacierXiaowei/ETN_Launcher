extends Button
class_name CardInputHandler

signal card_hovered()
signal card_unhovered()
signal card_clicked()
signal card_released()

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _on_mouse_entered() -> void:
	card_hovered.emit()

func _on_mouse_exited() -> void:
	card_unhovered.emit()

func _on_button_down() -> void:
	card_clicked.emit()

func _on_button_up() -> void:
	card_released.emit()
