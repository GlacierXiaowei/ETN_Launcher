shader_type canvas_item;

uniform float blur_amount : hint_range(0.0,5.0) =0.0;
uniform float dim_amount : hint_range(0.0,1.0) =0.0;

void fragment() {
 //使用 textureLod进行模糊采样
 vec4 color = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount);
 
 //添加暗化效果
 color.rgb *= (1.0 - dim_amount);
 
 COLOR = color;
}
