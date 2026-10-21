class_name Oscillator
extends Node

# ============================================
# 简谐振子 (Oscillator) - 物理振荡系统
# ============================================
# 用于实现卡片漂浮效果的物理模拟
# 基于弹簧-阻尼模型，产生自然的周期性运动
# 
# 物理原理:
# - 胡克定律: F = -kx (弹簧恢复力)
# - 阻尼力: F = -cv (速度相关的阻力)
# - 合力: F = -kx - cv
# ============================================

# 弹簧系数 (spring constant)
# 控制振荡的弹性强度，值越大弹性越强，振动频率越高
# 建议范围: 50.0 - 300.0
var spring: float = 150.0

# 阻尼系数 (damping coefficient)
# 控制振荡的衰减速度，值越大衰减越快
# 临界阻尼时: damp = 2 * sqrt(spring)
# 建议范围: 5.0 - 20.0
var damp: float = 10.0

# 位移 (displacement)
# 当前偏离平衡位置的距离
# 正值表示向一个方向偏离，负值表示相反方向
var displacement: float = 0.0

# 速度 (velocity)
# 当前振荡的速度，决定下一步位移的变化量
var velocity: float = 0.0

# 启用开关
# 设置为 false 时暂停物理计算，保持当前状态
var enabled: bool = true

# ============================================
# 构造函数
# ============================================
# spring_constant: 弹簧系数，控制振动频率
# damping: 阻尼系数，控制衰减速度
func _init(spring_constant: float = 150.0, damping: float = 10.0) -> void:
	spring = spring_constant
	damp = damping

# ============================================
# 更新函数 - 核心物理计算
# ============================================
# 每帧调用，根据 delta 时间计算新的位移和速度
# 
# 参数:
#   delta: 帧间隔时间（秒），由 Godot 引擎自动传入
# 
# 物理公式:
#   force = -spring * displacement - damp * velocity
#   velocity += force * delta
#   displacement += velocity * delta
func update(delta: float) -> void:
	if not enabled:
		return
	
	# 计算合力: 弹簧恢复力 + 阻尼力
	# 负号表示力的方向与位移/速度相反
	var force = -spring * displacement - damp * velocity
	
	# 根据牛顿第二定律 F=ma，更新速度
	# 假设质量为1，则 a = F
	velocity += force * delta
	
	# 根据速度更新位移
	displacement += velocity * delta

# ============================================
# 重置函数
# ============================================
# 将位移和速度归零，回到初始状态
# 用于重新开始动画或紧急停止
func reset() -> void:
	displacement = 0.0
	velocity = 0.0

# ============================================
# 设置位移
# ============================================
# 手动设置当前位移值
# 可用于初始化位置或外部控制
# 
# 参数:
#   value: 新的位移值
func set_displacement(value: float) -> void:
	displacement = value
