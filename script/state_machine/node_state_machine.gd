##使用时 直接拖动使用同一个脚本即可
class_name NodeStateMachine
extends Node

#这个状态已经在外部编辑器中设置了
@export var initial_node_state : NodeState


var node_states : Dictionary = {}
@export var current_node_state : NodeState
var current_node_state_name:String
var current_character_name : String

#状态机就是主动调用子类的函数
func _ready() -> void:
	for child in get_children():
		if child is NodeState:
			node_states[child.name.to_lower()] = child
			child.transition.connect(transition_to)
	
	if initial_node_state:
		initial_node_state._on_enter()
		current_node_state = initial_node_state


func _process(delta : float) -> void:
	if current_node_state:
		current_node_state._on_process(delta)


func _physics_process(delta: float) -> void:
	if current_node_state:
		current_node_state._on_physics_process(delta)
		current_node_state._on_next_transitions()
	

func transition_to(node_state_name : String) -> void:
	if node_state_name == current_node_state.name.to_lower():
		return
	
	var new_node_state = node_states.get(node_state_name.to_lower())
	
	if !new_node_state:
		return
	
	if current_node_state:
		current_node_state._on_exit()
	
	new_node_state._on_enter()
	##这里获取的名字 实际上是转换后的阶段 也就是正确的名字 
	current_node_state = new_node_state
	current_node_state_name = current_node_state.name.to_lower()
	current_character_name = get_parent().name.to_lower()
	
	
	print(current_character_name," Current State: ", current_node_state_name)
