shader_type canvas_item;

uniform float border_width : hint_range(0.0,0.05) =0.01;
uniform vec4 border_color : source_color = vec4(1.0,1.0,1.0,1.0);
uniform float scale_factor : hint_range(0.8,1.0) =0.95;

void fragment() {
 vec2 uv = UV;
 
 //计算到边缘的距离
 float dist_to_left = uv.x;
 float dist_to_right =1.0 - uv.x;
 float dist_to_top = uv.y;
 float dist_to_bottom =1.0 - uv.y;
 
 float dist_to_edge = min(min(dist_to_left, dist_to_right), min(dist_to_top, dist_to_bottom));
 
 //如果在边框范围内，显示白色边框
 if (dist_to_edge < border_width) {
 COLOR = border_color;
 } else {
 //在中间区域，采样缩小的原图
 //将 UV坐标从 [border_width,1-border_width]映射到 [0,1]
 vec2 inner_uv = (uv - vec2(border_width)) / (1.0 -2.0 * border_width);
 
 //应用缩放：从中心点向外收缩
 vec2 center = vec2(0.5,0.5);
 vec2 scaled_uv = center + (inner_uv - center) * scale_factor;
 
 //确保缩放后的 UV在有效范围内
 if (scaled_uv.x <0.0 || scaled_uv.x >1.0 || scaled_uv.y <0.0 || scaled_uv.y >1.0) {
 COLOR = vec4(0.0,0.0,0.0,0.0);
 } else {
 COLOR = texture(TEXTURE, scaled_uv);
 }
 }
}
