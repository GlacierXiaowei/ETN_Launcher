shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Must be set from script to match the Control/TextureRect pixel size.
uniform vec2 rect_size_px = vec2(256.0, 256.0);
uniform float corner_radius_px : hint_range(0.0, 256.0) = 24.0;

// tint.rgb: absorption color, tint.a: tint strength (0..1).
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 0.12);

// Final glass alpha inside the mask (decoupled from tint strength).
uniform float opacity : hint_range(0.0, 1.0) = 0.12;

// Refraction (in pixels). Stronger near edges.
uniform float refraction_strength_px : hint_range(0.0, 64.0) = 10.0;
uniform float edge_refraction_boost : hint_range(0.0, 4.0) = 1.25;
uniform float edge_falloff_px : hint_range(1.0, 256.0) = 64.0;

// Mip-based blur. (textureLod uses SCREEN_TEXTURE mip levels.)
uniform float blur_lod_center : hint_range(0.0, 10.0) = 0.0;
uniform float blur_lod_edge : hint_range(0.0, 10.0) = 3.0;

// Dispersion: when > 0, uses 3 samples total (R/G/B separated).
uniform float dispersion_strength : hint_range(0.0, 1.0) = 0.0;
uniform float dispersion_px : hint_range(0.0, 8.0) = 1.5;

// Inside-only border stroke.
uniform float border_width_px : hint_range(0.0, 64.0) = 1.0;
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 0.28);

// Rim highlight band near the edge (inside only).
uniform float rim_width_px : hint_range(0.0, 128.0) = 14.0;
uniform float rim_intensity : hint_range(0.0, 4.0) = 1.0;
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 0.55);

float sd_rounded_rect_px(vec2 p_px, vec2 half_size_px, float radius_px) {
    // Signed distance to a rounded rectangle centered at origin.
    // p_px: point in px relative to center
    // half_size_px: half extents in px
    // radius_px: corner radius in px
    float r = clamp(radius_px, 0.0, min(half_size_px.x, half_size_px.y));
    vec2 b = half_size_px - vec2(r);
    vec2 d = abs(p_px) - b;
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - r;
}

vec2 clamp_screen_uv(vec2 uv) {
    // Prevent out-of-screen sampling. Using a half-pixel pad reduces edge pinning artifacts.
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

    // Antialias width in pixels; keep stable even on very small quads.
    float aa = max(fwidth(sd), 0.75);

    // 1 inside, 0 outside.
    float mask = 1.0 - smoothstep(0.0, aa, sd);

    // Early out outside mask.
    if (mask <= 0.0) {
        COLOR = vec4(0.0);
        return;
    }

    float inside_px = max(-sd, 0.0);

    // Strongest near edge (inside_px ~ 0), fades toward center.
    float edge_factor = 1.0 - smoothstep(0.0, max(edge_falloff_px, 1.0), inside_px);

    // Refraction direction: from center to fragment in pixel space.
    float vlen = max(length(p_px), 1e-4);
    vec2 dir_px = p_px / vlen;

    float refr_px = refraction_strength_px * edge_factor * (1.0 + edge_refraction_boost * edge_factor);
    vec2 refr_uv_off = dir_px * refr_px * SCREEN_PIXEL_SIZE;

    float lod = mix(blur_lod_center, blur_lod_edge, edge_factor);
    vec4 refr = sample_screen_glass(SCREEN_UV + refr_uv_off, lod, edge_factor, dir_px);

    // Base glass color.
    vec4 col = refr;
    float tint_a = clamp(tint.a, 0.0, 1.0);
    col.rgb = mix(col.rgb, col.rgb * tint.rgb, tint_a);

    // Rim band (inside only): 1 near edge, fades by rim_width_px.
    float rim_band = 1.0 - smoothstep(rim_width_px - aa, rim_width_px + aa, inside_px);
    rim_band *= smoothstep(0.0, aa, inside_px);
    col.rgb += rim_color.rgb * (rim_intensity * rim_band * rim_color.a);

    // Inside-only border stroke.
    float bw = max(border_width_px, 0.0);
    float border = 1.0 - smoothstep(bw - aa, bw + aa, inside_px);
    border *= smoothstep(0.0, aa, inside_px);
    col.rgb = mix(col.rgb, border_color.rgb, border * border_color.a);

    float out_a = mask * clamp(opacity, 0.0, 1.0);
    COLOR = vec4(col.rgb, out_a);
}
