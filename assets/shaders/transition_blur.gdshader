shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 10.0) = 0.0;

// Size of the rect (in pixels) this shader is applied to.
// MUST be set by script for dynamic Controls (e.g. ColorRect overlays).
uniform vec2 rect_size_px = vec2(256.0, 256.0);

// Rounded corner radius in pixels. 0 disables rounded corners.
uniform float corner_radius_px : hint_range(0.0, 256.0) = 0.0;

float sd_round_rect(vec2 p, vec2 b, float r) {
	// Signed distance to a rounded rectangle centered at origin.
	// p: point (px) relative to center; b: half-size minus radius.
	vec2 q = abs(p) - b;
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec4 col = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount);

	if (corner_radius_px > 0.0) {
		// Compute a rounded-rect alpha mask in local rect pixel space.
		vec2 size_px = max(rect_size_px, vec2(1.0));
		float r = clamp(corner_radius_px, 0.0, min(size_px.x, size_px.y) * 0.5);
		vec2 p = (UV * size_px) - (size_px * 0.5);
		vec2 b = (size_px * 0.5) - vec2(r);
		float d = sd_round_rect(p, b, r);

		// Approx 1px anti-aliasing.
		float aa = 1.0;
		float a = 1.0 - smoothstep(0.0, aa, d);
		col.a *= a;
	}

	COLOR = col;
}
