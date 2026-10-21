class_name CardShadowComponent
extends Node

# ============================================
# 卡片阴影组件 (Card Shadow Component)
# ============================================
# 实现动态阴影效果，模拟点光源固定在屏幕中心
# 
# 物理原理：
# - 光源位于屏幕正中央（点光源）
# - 阴影投射方向与光源位置相反
# - 距离光源越远，阴影偏移越大
#
# 使用方法：
# 1. 将组件添加到卡片场景
# 2. 在编辑器中设置 card（Button）和 shadow_texture_rect（TextureRect）
# 3. 确保 Shadow 节点的 modulate/self_modulate/show_behind_parent 已配置
# 4. 在卡片的 _process() 中调用 update_shadow_position()
# ============================================

# ============================================
# 导出变量 - 在编辑器中配置
# ============================================

## 卡片节点引用（Button类型）- 用于获取位置信息
@export var card: Button

## 阴影纹理节点 - 直接拖拽 TextureRect 到此
## 要求：已在编辑器中配置好 modulate、self_modulate、show_behind_parent
@export var shadow_texture_rect: TextureRect

## 最大偏移量（像素）- 卡片在最边缘时的阴影偏移距离
@export var max_offset: float = 300


func _ready() -> void:
	#await card.ready
	#await  shadow_texture_rect.ready
	if not card:
		push_warning("CardShadowComponent: card reference is not set!")
	if not shadow_texture_rect:
		push_warning("CardShadowComponent: shadow_texture_rect is not set!")


# ============================================
# 公共接口
# ============================================

## 更新阴影位置 - 核心功能
## 
## 调用时机：每帧在 _process() 中调用，或卡片移动时调用
##
## 计算逻辑：
##   1. 获取视口中心点坐标
##   2. 计算卡片与中心的水平和垂直距离
##   3. 根据距离比例计算 X 和 Y 方向的偏移量
##   4. 应用偏移到阴影节点
##
## 公式说明：
##   offset_x = sign(distance_x) * max_offset * (abs(distance_x) / center_x)
##   
##   其中：
##   - sign(distance): 返回 -1（左/上）或 +1（右/下），决定偏移方向
##   - max_offset: 最大偏移距离
##   - abs(distance) / center: 归一化的距离比例（0.0 ~ 1.0）
##   
##   示例：
##   - 卡片在最左侧：distance_x < 0, sign = -1，阴影向左偏移
##   - 卡片在最右侧：distance_x > 0, sign = +1，阴影向右偏移
##   - 卡片在中心：distance = 0，无偏移
func update_shadow_position() -> void:
	if not shadow_texture_rect or not card:
		return
	
	# 获取实际可见的视口尺寸（适配 Keep Aspect 拉伸模式）
	var viewport_rect = get_viewport().get_visible_rect()
	var center_x = viewport_rect.size.x / 2.0
	var center_y = viewport_rect.size.y / 2.0
	
	# 计算卡片中心点与视口中心的距离
	var card_center_x = card.global_position.x + card.size.x / 2.0
	var card_center_y = card.global_position.y + card.size.y / 2.0
	
	var distance_x = card_center_x - center_x
	var distance_y = card_center_y - center_y
	
	# 计算归一化的距离比例（0.0 ~ 1.0）
	var ratio_x = clampf(abs(distance_x) / center_x, 0.0, 1.0)
	var ratio_y = clampf(abs(distance_y) / center_y, 0.0, 1.0)
	
	# 计算偏移量（远离光源方向）
	var offset_x = sign(distance_x) * max_offset * ratio_x
	var offset_y = sign(distance_y) * max_offset * ratio_y
	
	# 应用偏移
	shadow_texture_rect.position.x = offset_x
	shadow_texture_rect.position.y = offset_y


## 设置阴影纹理
## 
## 参数:
##   texture: 要显示的纹理，通常使用与卡片相同的图片
func set_shadow_texture(texture: Texture2D) -> void:
	if shadow_texture_rect:
		shadow_texture_rect.texture = texture
