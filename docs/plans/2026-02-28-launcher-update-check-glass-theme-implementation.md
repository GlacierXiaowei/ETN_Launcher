# LauncherUpdateCheck Liquid-Glass Theme Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a reusable dark liquid-glass UI theme (Theme + Shader) and apply it to `res://scenes/test/launcher_update_check.tscn` via runtime changes in `res://scenes/test/launcher_update_check.gd`, without directly editing existing `.tscn` files.

**Architecture:** A `Theme` resource defines typography and button styles; a `canvas_item` shader (`liquid_glass_ui.gdshader`) renders the frosted card background using `SCREEN_TEXTURE` (mip blur + procedural refraction + rim highlight + optional dispersion). A small factory helper constructs and applies the runtime glass card node behind existing UI content.

**Tech Stack:** Godot 4.x, GDScript, Theme resources (`.tres`), CanvasItem shaders (`.gdshader`).

---

### Task 1: Add liquid glass UI shader

**Files:**
- Create: `assets/shaders/liquid_glass_ui.gdshader`

**Step 1: Create shader file with compile-safe uniforms**

Create `assets/shaders/liquid_glass_ui.gdshader`:

```glsl
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float blur_amount : hint_range(0.0, 10.0) = 2.5;
uniform float refraction_strength : hint_range(0.0, 0.08) = 0.02;
uniform float dispersion_strength : hint_range(0.0, 0.05) = 0.0;
uniform float highlight_strength : hint_range(0.0, 1.0) = 0.35;
uniform float highlight_width : hint_range(0.001, 0.2) = 0.03;

uniform vec4 tint_color : source_color = vec4(0.08, 0.10, 0.13, 0.38);
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 0.10);
uniform float border_width_px : hint_range(0.0, 6.0) = 1.0;

uniform float corner_radius_px : hint_range(0.0, 64.0) = 22.0;
uniform float edge_softness_px : hint_range(0.0, 8.0) = 1.5;

uniform float noise_strength : hint_range(0.0, 1.0) = 0.12;
uniform float noise_speed : hint_range(0.0, 4.0) = 0.75;

float _hash(vec2 p) {
    // Cheap deterministic hash
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float _noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = _hash(i);
    float b = _hash(i + vec2(1.0, 0.0));
    float c = _hash(i + vec2(0.0, 1.0));
    float d = _hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float _sd_round_rect(vec2 p, vec2 b, float r) {
    // Signed distance to rounded rectangle centered at origin.
    // p: position (px), b: half-size (px), r: radius (px)
    vec2 q = abs(p) - (b - vec2(r));
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
    vec2 px = max(vec2(1.0), vec2(textureSize(SCREEN_TEXTURE, 0)));
    vec2 uv = UV;
    vec2 screen_uv = SCREEN_UV;

    // Local rect in pixels (assumes the Control is axis-aligned)
    vec2 local_px = uv * px;
    vec2 center_px = 0.5 * px;
    vec2 p = local_px - center_px;

    float radius = clamp(corner_radius_px, 0.0, min(px.x, px.y) * 0.5);
    float d = _sd_round_rect(p, 0.5 * px, radius);

    // Smooth mask for rounded corners
    float aa = max(0.0001, edge_softness_px);
    float mask = 1.0 - smoothstep(0.0, aa, d);
    if (mask <= 0.0) {
        discard;
    }

    // Edge factor: 0 center -> 1 near boundary
    float edge = clamp(1.0 - smoothstep(-radius * 0.6, 0.0, d), 0.0, 1.0);

    // Normal-ish direction towards center for lens refraction
    vec2 dir = normalize(-p + vec2(1e-4));

    // Subtle animated noise (kept small)
    float t = TIME * noise_speed;
    float n = _noise(uv * 8.0 + vec2(t, -t));
    float wobble = (n - 0.5) * 2.0;

    float refr = refraction_strength * edge * (1.0 + wobble * noise_strength);
    vec2 offset = dir * refr;

    // Sample blurred background with refraction
    vec2 base_uv = screen_uv + offset;
    vec4 base_col = textureLod(SCREEN_TEXTURE, base_uv, blur_amount);

    // Optional dispersion (RGB split) based on offset
    if (dispersion_strength > 0.0) {
        vec2 o = offset * dispersion_strength * 20.0;
        float r = textureLod(SCREEN_TEXTURE, base_uv + o, blur_amount).r;
        float g = base_col.g;
        float b = textureLod(SCREEN_TEXTURE, base_uv - o, blur_amount).b;
        base_col = vec4(r, g, b, 1.0);
    }

    // Rim highlight near edge
    float rim = smoothstep(0.0, 1.0, edge);
    rim = pow(rim, 2.0);
    float rim_band = smoothstep(1.0 - highlight_width, 1.0, rim) * highlight_strength;
    vec3 rim_col = vec3(1.0);

    // Border line (approx) using distance in px
    float bw = max(0.0, border_width_px);
    float border = 1.0 - smoothstep(bw, bw + aa, abs(d));

    vec4 glass = base_col;
    glass.rgb = mix(glass.rgb, rim_col, rim_band * 0.35);
    glass.rgb = mix(glass.rgb, border_color.rgb, border * border_color.a);
    glass = mix(glass, tint_color, tint_color.a);

    glass.a = mask;
    COLOR = glass;
}
```

**Step 2: Manual compile check**

Open Godot editor, create a `ColorRect`, assign a ShaderMaterial using `res://assets/shaders/liquid_glass_ui.gdshader`. Confirm:
- No shader compile errors.
- Rounded corners mask works.
- Increasing `refraction_strength` increases edge distortion.

---

### Task 2: Add dark glass Theme resource

**Files:**
- Create: `assets/themes/etn_glass_dark.theme.tres`
- Create (optional): `assets/themes/etn_glass_dark_preset.tres` (if using Theme presets)

**Step 1: Create Theme in editor (preferred)**

Because `.tres` may embed resource IDs, create the Theme inside the Godot editor:
- New Resource: `Theme`
- Save as `res://assets/themes/etn_glass_dark.theme.tres`

Set defaults:
- Default font: `res://assets/fonts/unifont-16.0.02.otf`
- Label colors: normal `#E7EDF6`, subtle `#C9D1DA`
- Button StyleBoxes:
  - Primary: bg ~ `#2B7CFF` (tweak), radius 14-18, padding 14x10
  - Secondary: transparent bg, border `rgba(255,255,255,0.18)`, radius same
  - Hover: +10% brightness
  - Pressed: -10% brightness
  - Disabled: alpha ~ 0.55

**Step 2: Quick usage check**

In any test Control scene, set root `theme` to this Theme and confirm buttons/labels change.

---

### Task 3: Create theme + glass card helper

**Files:**
- Create: `script/ui/theme/etn_theme_factory.gd`

**Step 1: Implement helper**

Create `script/ui/theme/etn_theme_factory.gd`:

```gdscript
extends RefCounted

class_name ETNThemeFactory

static func load_glass_theme() -> Theme:
	return load("res://assets/themes/etn_glass_dark.theme.tres")

static func create_glass_card() -> ColorRect:
	var card := ColorRect.new()
	card.name = "GlassCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.color = Color(1, 1, 1, 1)

	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/liquid_glass_ui.gdshader")
	card.material = mat

	# Reasonable defaults
	mat.set_shader_parameter("blur_amount", 2.8)
	mat.set_shader_parameter("refraction_strength", 0.018)
	mat.set_shader_parameter("dispersion_strength", 0.0)
	mat.set_shader_parameter("corner_radius_px", 22.0)
	mat.set_shader_parameter("border_width_px", 1.0)
	mat.set_shader_parameter("highlight_strength", 0.35)
	mat.set_shader_parameter("highlight_width", 0.03)
	mat.set_shader_parameter("noise_strength", 0.12)
	mat.set_shader_parameter("noise_speed", 0.75)

	return card
```

**Step 2: Ensure script loads without errors**

In editor script console, run a tiny snippet or just ensure no parse errors.

---

### Task 4: Apply theme + inject glass card in LauncherUpdateCheck test scene

**Files:**
- Modify: `scenes/test/launcher_update_check.gd`

**Step 1: Load and apply Theme**

At `_ready()` start:
- `self.theme = ETNThemeFactory.load_glass_theme()`

**Step 2: Insert GlassCard behind content**

Locate `CenterContainer` and its `VBoxContainer`. Add a glass card child sized/padded to contain the VBox.

Implementation notes:
- Create a wrapper `MarginContainer` for padding.
- Alternatively, set `GlassCard` anchors to full inside `CenterContainer` and use `custom_minimum_size`.

Pseudo-steps:
- `var card = ETNThemeFactory.create_glass_card()`
- Add as child of `CenterContainer` (or as sibling behind VBox)
- Ensure it is drawn behind by moving it to index 0.
- Update its size each frame or on `resized` by binding to viewport resize.

**Step 3: Enable existing background ambience if needed**

If `$BackGround` exists, set it visible and adjust brightness/blur parameters via node paths (only runtime property edits).

---

### Task 5: Verification

**Step 1: Godot editor run**

Run the test scene and verify:
- No shader compile errors.
- Card appears and clips to rounded corners.
- Buttons are styled by Theme.
- No input is blocked by the card (mouse_filter ignore).

**Step 2: Performance sanity**

Use Godot profiler for a quick check: confirm draw calls and frame time remain stable.

---

## Execution Options

Plan complete and saved to `docs/plans/2026-02-28-launcher-update-check-glass-theme-implementation.md`.

Two execution options:

1. Subagent-Driven (this session) — I dispatch a fresh subagent per task, review between tasks, fast iteration.

2. Parallel Session (separate) — Open a new session with executing-plans, batch execution with checkpoints.

Which approach?
