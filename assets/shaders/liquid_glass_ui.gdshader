shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// 注意：rect_size_px 需要由脚本设置为该控件的像素尺寸。
uniform vec2 rect_size_px = vec2(256.0, 256.0);
uniform float corner_radius_px : hint_range(0.0, 256.0) = 24.0;

// tint.rgb: 玻璃吸收/染色颜色；tint.a: 染色强度 (0..1)。
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 0.12);

// 最终玻璃透明度（与 tint.a 解耦）。
uniform float opacity : hint_range(0.0, 1.0) = 0.12;

// 折射强度（像素单位）。越靠近边缘越强。
uniform float refraction_strength_px : hint_range(0.0, 64.0) = 10.0;
uniform float edge_refraction_boost : hint_range(0.0, 4.0) = 1.25;
uniform float edge_falloff_px : hint_range(1.0, 256.0) = 64.0;

// 基于 mip 的模糊（textureLod 使用 SCREEN_TEXTURE 的 mip 级别）。
uniform float blur_lod_center : hint_range(0.0, 10.0) = 0.0;
uniform float blur_lod_edge : hint_range(0.0, 10.0) = 3.0;

// 色散：当 dispersion_strength > 0 时，启用 3 次采样（R/G/B 分离）。
uniform float dispersion_strength : hint_range(0.0, 1.0) = 0.0;
uniform float dispersion_px : hint_range(0.0, 8.0) = 1.5;

// 内描边。
uniform float border_width_px : hint_range(0.0, 64.0) = 1.0;
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 0.28);

// 边缘高光（仅在内部）。
uniform float rim_width_px : hint_range(0.0, 128.0) = 14.0;
uniform float rim_intensity : hint_range(0.0, 4.0) = 1.0;
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 0.55);

float sd_rounded_rect_px(vec2 p_px, vec2 half_size_px, float radius_px) {
    // 圆角矩形的 SDF（以中心为原点，单位 px）。
    float r = clamp(radius_px, 0.0, min(half_size_px.x, half_size_px.y));
    vec2 b = half_size_px - vec2(r);
    vec2 d = abs(p_px) - b;
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - r;
}

vec2 clamp_screen_uv(vec2 uv) {
    // 防止采样越界；使用半像素 padding 可降低屏幕边缘的“粘边”伪影。
    vec2 pad = SCREEN_PIXEL_SIZE * 0.5;
    return clamp(uv, pad, vec2(1.0) - pad);
}

vec4 sample_screen_glass(vec2 uv, float lod, float edge_factor, vec2 dir_px) {
    vec2 base_uv = clamp_screen_uv(uv);
    float lod_clamped = clamp(lod, 0.0, 10.0);

    if (dispersion_strength > 1e-5) {
        vec2 disp_uv_off = dir_px * (dispersion_px * dispersion_strength * edge_factor) * SCREEN_PIXEL_SIZE;

        vec2 uv_p = clamp_screen_uv(base_uv + disp_uv_off);
        vec2 uv_m = clamp_screen_uv(base_uv - disp_uv_off);

        vec4 c0 = textureLod(SCREEN_TEXTURE, uv_p, lod_clamped);
        vec4 c1 = textureLod(SCREEN_TEXTURE, base_uv, lod_clamped);
        vec4 c2 = textureLod(SCREEN_TEXTURE, uv_m, lod_clamped);

        return vec4(c0.r, c1.g, c2.b, c1.a);
    }

    return textureLod(SCREEN_TEXTURE, base_uv, lod_clamped);
}

void fragment() {
    vec2 half_size_px = rect_size_px * 0.5;
    vec2 p_px = (UV * rect_size_px) - half_size_px;

    float sd = sd_rounded_rect_px(p_px, half_size_px, corner_radius_px);

    // 抗锯齿宽度（像素单位）；小尺寸下也尽量稳定。
    float aa = max(fwidth(sd), 0.75);

    // mask: 内部 1，外部 0。
    float mask = 1.0 - smoothstep(0.0, aa, sd);

    // 外部直接返回透明。
    if (mask <= 0.0) {
        COLOR = vec4(0.0);
        return;
    }

    float inside_px = max(-sd, 0.0);

    // edge_factor：越靠近边缘（inside_px 趋近 0）越强，向中心衰减。
    float edge_factor = 1.0 - smoothstep(0.0, max(edge_falloff_px, 1.0), inside_px);

    // 折射方向：以像素空间为准，从中心指向当前像素。
    float vlen = max(length(p_px), 1e-4);
    vec2 dir_px = p_px / vlen;

    float refr_px = refraction_strength_px * edge_factor * (1.0 + edge_refraction_boost * edge_factor);
    vec2 refr_uv_off = dir_px * refr_px * SCREEN_PIXEL_SIZE;

    float lod = mix(blur_lod_center, blur_lod_edge, edge_factor);
    vec4 refr = sample_screen_glass(SCREEN_UV + refr_uv_off, lod, edge_factor, dir_px);

    // 玻璃基底颜色。
    vec4 col = refr;
    float tint_a = clamp(tint.a, 0.0, 1.0);
    col.rgb = mix(col.rgb, col.rgb * tint.rgb, tint_a);

    // 边缘高光带（仅内部）：越靠近边缘越强，按 rim_width_px 衰减。
    float rim_band = 1.0 - smoothstep(rim_width_px - aa, rim_width_px + aa, inside_px);
    rim_band *= smoothstep(0.0, aa, inside_px);
    col.rgb += rim_color.rgb * (rim_intensity * rim_band * rim_color.a);

    // 内描边。
    float bw = max(border_width_px, 0.0);
    float border = 1.0 - smoothstep(bw - aa, bw + aa, inside_px);
    border *= smoothstep(0.0, aa, inside_px);
    col.rgb = mix(col.rgb, border_color.rgb, border * border_color.a);

    float out_a = mask * clamp(opacity, 0.0, 1.0);
    COLOR = vec4(col.rgb, out_a);
}
