shader_type canvas_item;

uniform float border_width : hint_range(0.0,0.1) =0.03;
uniform vec4 border_color : source_color = vec4(1.0,1.0,1.0,1.0);
uniform float glow_intensity : hint_range(0.0,2.0) =1.2;

void fragment() {
 vec2 uv = UV;
 
 //计算到边缘的距离（取四个边中最小的距离）
 float dist_to_left = uv.x;
 float dist_to_right =1.0 - uv.x;
 float dist_to_top = uv.y;
 float dist_to_bottom =1.0 - uv.y;
 
 float dist_to_edge = min(min(dist_to_left, dist_to_right), min(dist_to_top, dist_to_bottom));
 
 //如果在边框范围内，添加发光效果
 if (dist_to_edge < border_width) {
 //计算边框强度（越靠近边缘越强）
 float edge_factor =1.0 - (dist_to_edge / border_width);
 float alpha = edge_factor * glow_intensity;
 
 //混合边框颜色（使用预乘alpha）
 COLOR = vec4(border_color.rgb, alpha);
 } else {
 //不在边框范围内，完全透明
 COLOR = vec4(0.0,0.0,0.0,0.0);
 }
}
