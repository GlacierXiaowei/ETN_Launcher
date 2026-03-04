extends NodeStateMachine


func _on_card_confirm() -> void:
	current_node_state._on_card_confirm()
