shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0,10.0) =0.0;

void fragment() {
 //使用 textureLod进行模糊采样，blur_amount控制模糊强度
 vec4 color = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount);
 
 COLOR = color;
}
