extends Node
class_name CardVisualComponent

@export var card_texture: TextureRect
@export var shadow: TextureRect

var _3d_material: ShaderMaterial

func _ready() -> void:
	_setup_materials()

func _setup_materials() -> void:
	if card_texture:
		_3d_material = card_texture.material
		if _3d_material:
			set_rotation_3d(0.0, 0.0)

func set_poster_texture(texture: Texture2D) -> void:
	if card_texture:
		card_texture.texture = texture

func set_rotation_3d(x_rot: float, y_rot: float) -> void:
	if _3d_material:
		_3d_material.set_shader_parameter("x_rot", x_rot)
		_3d_material.set_shader_parameter("y_rot", y_rot)

func reset_rotation() -> void:
	set_rotation_3d(0.0, 0.0)

func update_rect_size(size: Vector2) -> void:
	if _3d_material:
		_3d_material.set_shader_parameter("rect_size", size)
