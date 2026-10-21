extends Node
class_name CardDragComponent

# ============================================
# 信号定义
# ============================================
## 拖拽开始时发出，可连接漂浮组件暂停漂浮
signal drag_started
## 拖拽结束时发出，可连接漂浮组件恢复漂浮
signal drag_ended

# ============================================
# 导出变量 - 可在编辑器中配置
# ============================================
## 卡片节点引用，必须设置为父级 Control 节点
@export var card: Button
## 屏幕边缘边距，防止卡片完全超出屏幕
@export var boundary_margin: Vector2 = Vector2(50, 50)
## 恢复到中心动画的持续时间（秒）
@export var restore_duration: float = 0.5

# ============================================
# 私有变量
# ============================================
## 是否启用拖拽功能
var _drag_enabled: bool = true
## 当前是否正在拖拽中
var _is_dragging: bool = false
## 卡片的原始位置（用于restore_to_center）
var _original_position: Vector2
## 鼠标点击时相对于卡片左上角的偏移量
## 用于保持拖拽时鼠标与卡片的相对位置不变
var _drag_offset: Vector2
## 恢复动画的Tween引用，用于中断之前的动画
var _tween_restore: Tween

# ============================================
# 初始化
# ============================================
func _ready() -> void:
	# 检查必要引用是否设置
	await card.ready
	if not card:
		push_warning("CardDragComponent: 'card' reference is not set!")
		return
	
	# 保存初始全局位置作为"中心"位置
	# 这个位置可以通过 update_original_position() 方法更新
	_original_position = card.global_position

# ============================================
# 公共接口 - 供外部调用
# ============================================

## 处理输入事件，由父节点 GameCard._on_gui_input() 调用
## 参数:
##   event: InputEvent - Godot输入事件对象
## 说明: 不直接响应全局输入，而是通过父节点转发，符合Godot事件传播机制
func handle_input(event: InputEvent) -> void:
	# 如果拖拽被禁用，忽略所有输入
	if not _drag_enabled:
		return
	
	# 只处理鼠标左键事件
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	
	if event.is_pressed():
		# 鼠标按下：开始拖拽
		_start_drag()
	else:
		# 鼠标释放：结束拖拽
		if _is_dragging:
			_end_drag()
	
	###尝试修复 连续点击卡片无法移动得问题	
	#if event is InputEventMouseEnter and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		#if not _is_dragging:
			#_start_drag()

## 每帧更新拖拽位置，由父节点 GameCard._process() 调用
## 参数:
##   delta: float - 帧间隔时间
## 说明: 需要在_process中持续调用以跟随鼠标移动
func process_drag() -> void:
	# 只有处于拖拽状态且启用拖拽时才更新位置
	if not (_is_dragging and _drag_enabled and card):
		return
	
	_update_drag_position()

## 启用拖拽功能
func enable_drag() -> void:
	_drag_enabled = true

## 禁用拖拽功能
## 说明: 如果正在拖拽中会立即结束拖拽
func disable_drag() -> void:
	_drag_enabled = false
	if _is_dragging:
		_end_drag()

## 检查当前是否正在拖拽
## 返回: bool - true表示正在拖拽中
func is_dragging() -> bool:
	return _is_dragging

## 使用Tween动画平滑恢复到原始中心位置
## 说明: 手动调用接口，不会自动执行
func restore_to_center() -> void:
	if not card:
		return
	
	# 如果已有恢复动画在运行，先停止它
	if _tween_restore and _tween_restore.is_running():
		_tween_restore.kill()
	
	# 创建新的恢复动画
	_tween_restore = create_tween()
	_tween_restore.set_ease(Tween.EASE_OUT)
	_tween_restore.set_trans(Tween.TRANS_CUBIC)
	_tween_restore.tween_property(
		card,
		"global_position",
		_original_position,
		restore_duration
	)


## 设置边界边距
## 参数:
##   margin: Vector2 - 新的边距值（像素）
func set_boundary_margin(margin: Vector2) -> void:
	boundary_margin = margin


## 更新原始中心位置
## 参数:
##   new_position: Vector2 - 新的中心位置，默认为当前位置
## 说明: 当卡片被放置到新位置后调用，更新restore_to_center的目标位置
## 这个会修改中心位置哦
func update_original_position(new_position: Vector2 = card.global_position) -> void:
	_original_position = new_position


# ============================================
# 私有方法
# ============================================

## 开始拖拽
## 说明: 记录当前鼠标位置与卡片位置的偏移量，准备跟随鼠标
func _start_drag() -> void:
	_is_dragging = true
	# 计算偏移量：卡片左上角到鼠标的向量
	# 这样在拖拽过程中保持这个相对位置不变
	var mouse_pos: Vector2 = card.get_global_mouse_position()
	_drag_offset = card.global_position - mouse_pos
	# 发出信号，通知其他组件（如漂浮组件）暂停
	drag_started.emit()

## 结束拖拽
## 说明: 停止跟随鼠标，重置旋转，发出结束信号
func _end_drag() -> void:
	_is_dragging = false
	# 发出信号，通知其他组件（如漂浮组件）恢复
	drag_ended.emit()


## 更新拖拽位置（带硬边界限制）
## 说明: 将卡片位置设为鼠标位置+偏移量，然后钳制在边界内
func _update_drag_position() -> void:
	# 获取当前鼠标全局位置
	var mouse_pos: Vector2 = card.get_global_mouse_position()
	# 目标位置 = 鼠标位置 + 记录的偏移量
	var target_pos: Vector2 = mouse_pos + _drag_offset
	
	# 应用硬边界限制
	target_pos = _clamp_position_to_boundary(target_pos)
	
	# 更新卡片全局位置
	card.global_position = target_pos


## 将位置限制在屏幕边界内（允许一半超出）
## 参数:
##   pos: Vector2 - 待限制的位置
## 返回: Vector2 - 限制后的位置
## 说明: 
##   - 允许卡片的一半超出屏幕边缘
##   - 防止卡片完全丢失在屏幕外
func _clamp_position_to_boundary(pos: Vector2) -> Vector2:
	# 获取视口的实际可见矩形（已考虑Canvas变换和缩放）
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var card_size: Vector2 = card.size
	
	# 新边界计算：允许卡片一半超出屏幕
	# min_x: 左边可以出去一半的卡片宽度
	# max_x: 右边可以出去一半的卡片宽度
	var min_x: float = -card_size.x / 2.0
	var max_x: float = viewport_rect.size.x - card_size.x / 2.0
	var min_y: float = -card_size.y / 2.0
	var max_y: float = viewport_rect.size.y - card_size.y / 2.0
	
	# 使用 clampf 函数将位置限制在新的边界内
	var clamped_x: float = clampf(pos.x, min_x, max_x)
	var clamped_y: float = clampf(pos.y, min_y, max_y)
	
	return Vector2(clamped_x, clamped_y)
