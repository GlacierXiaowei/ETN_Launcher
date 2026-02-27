shader_type canvas_item;

uniform float blur_amount : hint_range(0.0,5.0) =2.0;
uniform float brightness : hint_range(0.0,2.0) =1.0;

void fragment() {
 //使用 textureLod进行模糊采样
 vec4 color = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount);
 
 //应用亮度调整
 color.rgb *= brightness;
 
 COLOR = color;
}
