##请复制使用该脚本 同时删除class_name 和 信号的这两行即可
##同时需要继承这个类
class_name NodeState
extends Node

@warning_ignore("unused_signal")
signal transition 


func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	pass


func _on_next_transitions() -> void:
	pass


func _on_enter() -> void:
	pass


func _on_exit() -> void:
	pass
