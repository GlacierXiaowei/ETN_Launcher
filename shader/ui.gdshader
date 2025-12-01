// 这告诉 Godot 这是一个用于 2D 元素的着色器
shader_type canvas_item;

// 【核心】定义一个 uniform 变量，这会让我们可以在 Inspector 面板里控制它
// hint_range(min, max) 会让它显示为一个滑块，非常直观
uniform float feather_size : hint_range(0.0, 0.5) = 0.25;

// fragment() 函数对纹理的每一个像素运行一次
void fragment() {
    // 1. 获取这个像素原本应该是什么颜色
    //vec4 original_color = texture(TEXTURE, UV);

    // 2. 计算当前像素(UV)到纹理中心(0.5, 0.5)的“盒子距离”
    // abs(UV - vec2(0.5)) 计算出 x 和 y 方向上分别距离中心多远
    // max(...) 则取其中较远的一个距离。这会形成一个方形的渐变
    vec2 distance_from_center = abs(UV - vec2(0.5));
    float box_distance = max(distance_from_center.x, distance_from_center.y);

    // 3. 使用 smoothstep() 函数来创建一个平滑的 alpha (透明度) 遮罩
    // box_distance 的范围是从 0 (中心) 到 0.5 (边缘)
    // 我们希望在 (0.5 - feather_size) 这个位置开始淡出, 到 0.5 这个位置完全透明
    // smoothstep(edge1, edge0, value) 当 edge1 > edge0 时，会产生一个从 1 到 0 的平滑过渡
    float alpha = smoothstep(0.5, 0.5 - feather_size, box_distance);

    // 4. 将我们计算出的 alpha 应用到原始颜色上
    // 我们保留原始的 RGB 颜色，但将它的 alpha 通道与我们计算出的羽化 alpha 相乘
    COLOR.a*=alpha;
}
