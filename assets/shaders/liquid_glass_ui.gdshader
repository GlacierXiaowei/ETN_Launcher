shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// 注意：rect_size_px 需要由脚本设置为该控件的像素尺寸。
uniform vec2 rect_size_px = vec2(256.0, 256.0);
uniform float corner_radius_px : hint_range(0.0, 256.0) = 24.0;

// tint.rgb: 玻璃吸收/染色颜色；tint.a: 染色强度 (0..1)。
uniform vec4 tint : source_color = vec4(2.117, 2.117, 2.117, 0.12);

// 最终玻璃透明度（与 tint.a 解耦）。
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

// 折射强度（像素单位）。越靠近边缘越强。
uniform float refraction_strength_px : hint_range(0.0, 64.0) = 14;
uniform float edge_refraction_boost : hint_range(0.0, 4.0) = 4.0;
uniform float edge_falloff_px : hint_range(1.0, 256.0) = 12;

// 基于 mip 的模糊（textureLod 使用 SCREEN_TEXTURE 的 mip 级别）。
uniform float blur_lod_center : hint_range(0.0, 10.0) = 2.8;
uniform float blur_lod_edge : hint_range(0.0, 10.0) = 4.2;

// High-quality blur (Gaussian taps). Used only when blur_quality > 0.
uniform float blur_strength : hint_range(0.0, 1.0) = 1.0;
uniform float blur_radius_px : hint_range(0.0, 32.0) = 21;

// Blur quality selection.
// 0: mip LOD only (your "low quality" path; very smooth and stable)
// 1: 17 taps (isotropic)
// 2: 65 taps (very heavy; best quality)
// 3: 257 taps (extreme; mostly for experiments)
uniform int blur_quality : hint_range(0, 3) = 0;

// Refraction shaping. Helps avoid prism-like faceting artifacts.
uniform float refraction_isotropy : hint_range(0.0, 1.0) = 0.35;
uniform float refraction_edge_curve : hint_range(0.0, 4.0) = 2.05;

// 色散：当 dispersion_strength > 0 时，启用 3 次采样（R/G/B 分离）。
uniform float dispersion_strength : hint_range(0.0, 2.0) = 1.4;
uniform float dispersion_px : hint_range(0.0, 64.0) = 16;

// 内描边。
uniform float border_width_px : hint_range(0.0, 64.0) = 0.5;
uniform vec4 border_color : source_color = vec4(1.353, 1.353, 1.353, 0.278);

// 边缘高光（仅在内部）。
uniform float rim_width_px : hint_range(0.0, 128.0) =2.25;
uniform float rim_intensity : hint_range(0.0, 4.0) = 4.0;
uniform vec4 rim_color : source_color = vec4(3.294, 3.294, 3.294, 0.55);

// Fresnel-style edge highlight tuning (approximate in 2D).
uniform float rim_fresnel_power : hint_range(0.5, 8.0) = 3.2;
uniform float rim_curvature : hint_range(0.0, 2.0) = 1.0;
uniform float rim_f0 : hint_range(0.0, 1.0) = 0.04;

// Radial lens distortion (subtle convex/concave feel).
uniform float distortion_k1 : hint_range(-0.4, 0.4) = 0.15;
uniform float distortion_k2 : hint_range(-0.4, 0.4) = 0.10;

float sd_rounded_rect_px(vec2 p_px, vec2 half_size_px, float radius_px) {
    // 圆角矩形的 SDF（以中心为原点，单位 px）。
    float r = clamp(radius_px, 0.0, min(half_size_px.x, half_size_px.y));
    vec2 b = half_size_px - vec2(r);
    vec2 d = abs(p_px) - b;
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - r;
}

vec2 get_screen_pixel_size() {
    // Godot 4 canvas_item shader does not expose SCREEN_PIXEL_SIZE on some backends.
    // Use the screen texture size to derive UV-per-pixel instead.
    vec2 sz = vec2(textureSize(SCREEN_TEXTURE, 0));
    sz = max(sz, vec2(1.0));
    return 1.0 / sz;
}

vec2 clamp_screen_uv(vec2 uv) {
    // 防止采样越界；使用半像素 padding 可降低屏幕边缘的“粘边”伪影。
    vec2 pad = get_screen_pixel_size() * 0.5;
    return clamp(uv, pad, vec2(1.0) - pad);
}

vec4 sample_screen_glass(vec2 uv, float lod, float edge_factor, vec2 dir_px) {
    vec2 base_uv = clamp_screen_uv(uv);
    float lod_clamped = clamp(lod, 0.0, 10.0);
    vec2 spx = get_screen_pixel_size();

    if (dispersion_strength > 1e-5) {
        vec2 disp_uv_off = dir_px * (dispersion_px * dispersion_strength * edge_factor) * spx;

        vec2 uv_p = clamp_screen_uv(base_uv + disp_uv_off);
        vec2 uv_m = clamp_screen_uv(base_uv - disp_uv_off);

        vec4 c0 = textureLod(SCREEN_TEXTURE, uv_p, lod_clamped);
        vec4 c1 = textureLod(SCREEN_TEXTURE, base_uv, lod_clamped);
        vec4 c2 = textureLod(SCREEN_TEXTURE, uv_m, lod_clamped);

        return vec4(c0.r, c1.g, c2.b, c1.a);
    }

    return textureLod(SCREEN_TEXTURE, base_uv, lod_clamped);
}

vec4 sample_screen(vec2 uv, float lod) {
    // Unified screen sampling with clamp.
    return textureLod(SCREEN_TEXTURE, clamp_screen_uv(uv), clamp(lod, 0.0, 10.0));
}

// Isotropic blur kernels (avoid cross/X artifacts).
// radius_px is in pixel units.
vec4 blur9(vec2 uv, float radius_px) {
    vec2 spx = get_screen_pixel_size();
    float r = max(radius_px, 0.0);

    // 9 taps: center + 8 around (approx Gaussian weights).
    vec2 o1 = vec2(1.0, 0.0) * r * spx;
    vec2 o2 = vec2(0.0, 1.0) * r * spx;
    vec2 o3 = vec2(0.7071, 0.7071) * r * spx;
    vec2 o4 = vec2(-0.7071, 0.7071) * r * spx;

    vec4 c = sample_screen(uv, 0.0) * 0.22;
    c += sample_screen(uv + o1, 0.0) * 0.10;
    c += sample_screen(uv - o1, 0.0) * 0.10;
    c += sample_screen(uv + o2, 0.0) * 0.10;
    c += sample_screen(uv - o2, 0.0) * 0.10;
    c += sample_screen(uv + o3, 0.0) * 0.095;
    c += sample_screen(uv - o3, 0.0) * 0.095;
    c += sample_screen(uv + o4, 0.0) * 0.095;
    c += sample_screen(uv - o4, 0.0) * 0.095;
    return c;
}

vec4 blur17(vec2 uv, float radius_px) {
    vec2 spx = get_screen_pixel_size();
    float r = max(radius_px, 0.0);

    // 17 taps: center + 8 (radius) + 8 (radius*0.5)
    vec2 o1 = vec2(1.0, 0.0) * r * spx;
    vec2 o2 = vec2(0.0, 1.0) * r * spx;
    vec2 o3 = vec2(0.7071, 0.7071) * r * spx;
    vec2 o4 = vec2(-0.7071, 0.7071) * r * spx;
    vec2 p1 = o1 * 0.5;
    vec2 p2 = o2 * 0.5;
    vec2 p3 = o3 * 0.5;
    vec2 p4 = o4 * 0.5;

    vec4 c = sample_screen(uv, 0.0) * 0.16;
    c += sample_screen(uv + p1, 0.0) * 0.08;
    c += sample_screen(uv - p1, 0.0) * 0.08;
    c += sample_screen(uv + p2, 0.0) * 0.08;
    c += sample_screen(uv - p2, 0.0) * 0.08;
    c += sample_screen(uv + p3, 0.0) * 0.07;
    c += sample_screen(uv - p3, 0.0) * 0.07;
    c += sample_screen(uv + p4, 0.0) * 0.07;
    c += sample_screen(uv - p4, 0.0) * 0.07;

    c += sample_screen(uv + o1, 0.0) * 0.045;
    c += sample_screen(uv - o1, 0.0) * 0.045;
    c += sample_screen(uv + o2, 0.0) * 0.045;
    c += sample_screen(uv - o2, 0.0) * 0.045;
    c += sample_screen(uv + o3, 0.0) * 0.04;
    c += sample_screen(uv - o3, 0.0) * 0.04;
    c += sample_screen(uv + o4, 0.0) * 0.04;
    c += sample_screen(uv - o4, 0.0) * 0.04;
    return c;
}

// 9-tap Gaussian blur along a direction in UV space.
// dir_uv is the UV offset for 1 pixel step along the blur axis.
vec4 gauss9_dir(vec2 uv, vec2 dir_uv, float radius_px) {
    // We use pre-tuned weights (rough Gaussian) and scale offsets by radius_px.
    // Precomputed offsets for 9 taps: -4..4
    float w0 = 0.227027;
    float w1 = 0.1945946;
    float w2 = 0.1216216;
    float w3 = 0.054054;
    float w4 = 0.016216;

    // Scale offsets by radius. We normalize by 4 so radius_px roughly matches "reach".
    float s = radius_px / 4.0;

    vec4 col = sample_screen(uv, 0.0) * w0;
    col += sample_screen(uv + dir_uv * (1.0 * s), 0.0) * w1;
    col += sample_screen(uv - dir_uv * (1.0 * s), 0.0) * w1;
    col += sample_screen(uv + dir_uv * (2.0 * s), 0.0) * w2;
    col += sample_screen(uv - dir_uv * (2.0 * s), 0.0) * w2;
    col += sample_screen(uv + dir_uv * (3.0 * s), 0.0) * w3;
    col += sample_screen(uv - dir_uv * (3.0 * s), 0.0) * w3;
    col += sample_screen(uv + dir_uv * (4.0 * s), 0.0) * w4;
    col += sample_screen(uv - dir_uv * (4.0 * s), 0.0) * w4;
    return col;
}

vec4 gauss9_separable(vec2 uv, float radius_px) {
    // Back-compat entrypoint.
    // We prefer isotropic kernels to avoid X-shaped artifacts.
    return blur9(uv, radius_px);
}

vec4 blur33(vec2 uv, float radius_px) {
    vec2 spx = get_screen_pixel_size();
    float r = max(radius_px, 0.0);

    // 33 taps: center + 16 at r + 16 at r*0.5 (8 directions + mirrored).
    vec2 d0 = vec2(1.0, 0.0);
    vec2 d1 = vec2(0.0, 1.0);
    vec2 d2 = vec2(0.7071, 0.7071);
    vec2 d3 = vec2(-0.7071, 0.7071);
    vec2 d4 = normalize(vec2(0.9239, 0.3827));
    vec2 d5 = normalize(vec2(-0.9239, 0.3827));
    vec2 d6 = normalize(vec2(0.3827, 0.9239));
    vec2 d7 = normalize(vec2(-0.3827, 0.9239));

    vec2 dirs[8] = vec2[8](d0, d1, d2, d3, d4, d5, d6, d7);

    vec4 c = sample_screen(uv, 0.0) * 0.12;
    for (int i = 0; i < 8; i++) {
        vec2 o = dirs[i] * r * spx;
        vec2 p = dirs[i] * (r * 0.5) * spx;
        c += sample_screen(uv + o, 0.0) * 0.03;
        c += sample_screen(uv - o, 0.0) * 0.03;
        c += sample_screen(uv + p, 0.0) * 0.04;
        c += sample_screen(uv - p, 0.0) * 0.04;
    }
    return c;
}

vec4 blur65(vec2 uv, float radius_px) {
    vec2 spx = get_screen_pixel_size();
    float r = max(radius_px, 0.0);

    // 16 directions around the circle.
    vec2 dirs[16] = vec2[16](
        vec2(1.0, 0.0), vec2(0.9239, 0.3827), vec2(0.7071, 0.7071), vec2(0.3827, 0.9239),
        vec2(0.0, 1.0), vec2(-0.3827, 0.9239), vec2(-0.7071, 0.7071), vec2(-0.9239, 0.3827),
        vec2(-1.0, 0.0), vec2(-0.9239, -0.3827), vec2(-0.7071, -0.7071), vec2(-0.3827, -0.9239),
        vec2(0.0, -1.0), vec2(0.3827, -0.9239), vec2(0.7071, -0.7071), vec2(0.9239, -0.3827)
    );

    // Four rings (0.25, 0.5, 0.75, 1.0). Total taps: 1 + 16*4 = 65.
    float ring_scales[4] = float[4](0.25, 0.50, 0.75, 1.00);

    // Approx Gaussian-ish weights. Must sum to ~1.
    float w_center = 0.16;
    float w_r0 = 0.22;
    float w_r1 = 0.22;
    float w_r2 = 0.20;
    float w_r3 = 0.20;

    vec4 c = sample_screen(uv, 0.0) * w_center;

    for (int ring = 0; ring < 4; ring++) {
        float ws = (ring == 0) ? w_r0 : ((ring == 1) ? w_r1 : ((ring == 2) ? w_r2 : w_r3));
        float per = ws / 16.0;
        vec2 o = r * ring_scales[ring] * spx;
        for (int i = 0; i < 16; i++) {
            c += sample_screen(uv + dirs[i] * o, 0.0) * per;
        }
    }

    return c;
}

vec4 blur129(vec2 uv, float radius_px) {
    vec2 spx = get_screen_pixel_size();
    float r = max(radius_px, 0.0);

    // 129 taps: 1 + 64 directions * 2 rings.
    float pi2 = 6.28318530718;

    float w_center = 0.20;
    float w_ring0 = 0.40;
    float w_ring1 = 0.40;

    vec4 c = sample_screen(uv, 0.0) * w_center;

    float per0 = w_ring0 / 64.0;
    float per1 = w_ring1 / 64.0;

    vec2 o0 = spx * (r * 0.55);
    vec2 o1 = spx * (r * 1.00);

    for (int i = 0; i < 64; i++) {
        float a = pi2 * (float(i) / 64.0);
        vec2 dir = vec2(cos(a), sin(a));
        c += sample_screen(uv + dir * o0, 0.0) * per0;
        c += sample_screen(uv + dir * o1, 0.0) * per1;
    }

    return c;
}

vec4 blur257(vec2 uv, float radius_px) {
    vec2 spx = get_screen_pixel_size();
    float r = max(radius_px, 0.0);

    // 257 taps: 1 + 64 directions * 4 rings.
    float pi2 = 6.28318530718;

    float w_center = 0.14;
    float w_r0 = 0.22;
    float w_r1 = 0.24;
    float w_r2 = 0.22;
    float w_r3 = 0.18;

    vec4 c = sample_screen(uv, 0.0) * w_center;

    float per0 = w_r0 / 64.0;
    float per1 = w_r1 / 64.0;
    float per2 = w_r2 / 64.0;
    float per3 = w_r3 / 64.0;

    vec2 o0 = spx * (r * 0.30);
    vec2 o1 = spx * (r * 0.55);
    vec2 o2 = spx * (r * 0.80);
    vec2 o3 = spx * (r * 1.05);

    for (int i = 0; i < 64; i++) {
        float a = pi2 * (float(i) / 64.0);
        vec2 dir = vec2(cos(a), sin(a));
        c += sample_screen(uv + dir * o0, 0.0) * per0;
        c += sample_screen(uv + dir * o1, 0.0) * per1;
        c += sample_screen(uv + dir * o2, 0.0) * per2;
        c += sample_screen(uv + dir * o3, 0.0) * per3;
    }

    return c;
}

// Compute a soft edge normal from SDF derivatives.
vec2 sd_normal(float sd) {
    vec2 g = vec2(dFdx(sd), dFdy(sd));
    float gl = max(length(g), 1e-5);
    return g / gl;
}

void fragment() {
    vec2 half_size_px = rect_size_px * 0.5;
    vec2 p_px = (UV * rect_size_px) - half_size_px;

    float sd = sd_rounded_rect_px(p_px, half_size_px, corner_radius_px);

    // AA: scale with derivatives to keep corners smooth at higher resolutions.
    float aa = max(fwidth(sd) * 1.35, 1.0);

    // mask: 内部 1，外部 0。
    float mask = 1.0 - smoothstep(0.0, aa, sd);

    // 外部直接输出透明。
    if (mask <= 0.0) {
        COLOR = vec4(0.0);
    } else {
        float inside_px = max(-sd, 0.0);

        // edge_factor：越靠近边缘（inside_px 趋近 0）越强，向中心衰减。
        float edge_factor = 1.0 - smoothstep(0.0, max(edge_falloff_px, 1.0), inside_px);

        // Local normalized coordinates (-1..1-ish) for radial distortion.
        vec2 p_n = p_px / max(half_size_px, vec2(1.0));
        float r2 = dot(p_n, p_n);
        float radial = 1.0 + distortion_k1 * r2 + distortion_k2 * r2 * r2;

        // Pseudo normal from SDF gradient for Fresnel + refraction direction.
        vec2 n2 = sd_normal(sd);
        vec3 N = normalize(vec3(n2 * rim_curvature, 1.0));
        float ndv = clamp(N.z, 0.0, 1.0);
        // Schlick-like Fresnel in 2D: stable baseline via rim_f0.
        float fresnel = rim_f0 + (1.0 - rim_f0) * pow(1.0 - ndv, rim_fresnel_power);

        // Refraction direction: mix center push with edge normal for a lens-like feel.
        float plen = max(length(p_px), 1e-4);
        vec2 dir_center = p_px / plen;
        vec2 dir_px = normalize(mix(dir_center, n2, 0.70));

        // Refraction profile: stronger near edge, smoother in center.
        float edge_profile = pow(edge_factor, max(refraction_edge_curve, 0.001));
        float refr_px = refraction_strength_px * mix(0.20, 1.00, edge_profile) * radial;
        refr_px *= (1.0 + edge_refraction_boost * edge_profile);

        // Reduce prism-like faceting by blending refraction direction toward radial.
        vec2 dir_smooth = normalize(mix(dir_center, dir_px, clamp(refraction_isotropy, 0.0, 1.0)));
        vec2 refr_uv_off = dir_smooth * refr_px * get_screen_pixel_size();

        // Base sampling: either high-quality blur or mip LOD.
        float lod = mix(blur_lod_center, blur_lod_edge, edge_factor);
        vec2 uv_refr = SCREEN_UV + refr_uv_off;

        vec4 base_col = vec4(0.0);
        if (blur_quality == 0 || blur_strength <= 1e-4 || blur_radius_px <= 0.25) {
            // Low quality path: mip LOD blur only. (This is the one you like.)
            base_col = sample_screen_glass(uv_refr, lod, edge_factor, dir_px);
        } else {
            // High quality path should NOT stack on top of mip LOD blur.
            // Use lod=0 for the sharp sample, then blend in the HQ blur.
            float blur_amt = clamp(blur_strength * mix(1.0, 0.85, edge_factor), 0.0, 1.0);

            vec4 blur_col = blur17(uv_refr, blur_radius_px);
            if (blur_quality == 2) {
                blur_col = blur65(uv_refr, blur_radius_px);
            } else if (blur_quality == 3) {
                blur_col = blur257(uv_refr, blur_radius_px);
            }

            vec4 sharp_col = sample_screen_glass(uv_refr, 0.0, edge_factor, dir_px);
            base_col = mix(sharp_col, blur_col, blur_amt);
        }

        // Glass tint / absorption.
        vec4 col = base_col;
        float tint_a = clamp(tint.a, 0.0, 1.0);
        col.rgb = mix(col.rgb, col.rgb * tint.rgb, tint_a);

        // Fresnel-style rim highlight: soft band * fresnel.
        float rim_band = 1.0 - smoothstep(rim_width_px - aa, rim_width_px + aa, inside_px);
        rim_band *= smoothstep(0.0, aa, inside_px);
        float rim = rim_intensity * rim_band * fresnel;
        col.rgb += rim_color.rgb * (rim * rim_color.a);

        // Inner border.
        float bw = max(border_width_px, 0.0);
        float border = 1.0 - smoothstep(bw - aa, bw + aa, inside_px);
        border *= smoothstep(0.0, aa, inside_px);
        col.rgb = mix(col.rgb, border_color.rgb, border * border_color.a);

        // Subtle extra chromatic dispersion near the edge (fresnel-driven).
        if (dispersion_strength > 1e-5) {
            float ca = clamp(dispersion_strength * pow(edge_factor, 0.85) * (0.20 + 0.80 * fresnel), 0.0, 1.0);
            vec2 ca_off = n2 * (dispersion_px * (0.5 + 0.5 * edge_factor)) * ca * get_screen_pixel_size();
            float lod_ca = max(lod, 0.0);
            float r = sample_screen(uv_refr + ca_off, lod_ca).r;
            float g = sample_screen(uv_refr, lod_ca).g;
            float b = sample_screen(uv_refr - ca_off, lod_ca).b;
            col.rgb = mix(col.rgb, vec3(r, g, b), ca);
        }

        // Smooth alpha falloff: slightly denser at the edge to feel like a physical layer.
        float edge_alpha = mix(1.0, 1.15, fresnel * edge_factor);
        float out_a = mask * clamp(opacity, 0.0, 1.0) * edge_alpha;
        COLOR = vec4(col.rgb, out_a);
    }
}
