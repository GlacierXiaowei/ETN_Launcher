# LauncherUpdateCheck Liquid-Glass Theme Design

**Goal:** Give the test scene `LauncherUpdateCheck` a high-quality dark “liquid glass” look (frosted card + coherent typography/buttons) that can be reused by future popup/dialog UIs.

**Constraints / Non-Goals**
- Do not directly edit existing `.tscn` files in the repository (scene edits are performed by the user inside the Godot editor).
- Keep the effect performant for popup-scale UI (single card on screen, not dozens).
- Prefer reusable resources (`.gdshader`, `.tres` Theme) over per-scene one-off styling.

---

## Visual Direction

### Base Mood
- Dark, calm background ambience.
- A centered frosted-glass card that feels like a lens: subtle refraction near edges, mild blur, controlled highlight rim.
- Optional very subtle chromatic dispersion at edges (default off or very low).

### Typography
- Use an existing project font (prefer `res://assets/fonts/unifont-16.0.02.otf` for neutral UI readability).
- Hierarchy:
  - `StatusLabel`: prominent (e.g., 24-28).
  - Body/notes: 14-16 with softer color.
  - Buttons: 16-18.

### Buttons
- Primary: filled (cool accent), rounded corners, strong contrast.
- Secondary: glass-outline style (transparent fill + subtle border) with hover brighten.
- Disabled: reduced contrast and alpha, still readable.

---

## Component Design

### Frosted Card (Core)

The frosted card is a dedicated UI node with a ShaderMaterial. It sits behind the existing `CenterContainer/VBoxContainer` content.

**Effect layers (in one shader):**
1. **Blur:** mip-based blur sampling from `SCREEN_TEXTURE` (cheap) with adjustable strength.
2. **Refraction (lens):** screen UV offset computed procedurally (no displacement texture) so edges refract slightly more than the center.
3. **Liquid detail:** a very subtle time-based noise perturbation applied to refraction strength/offset (kept small to avoid dizziness).
4. **Rim highlight:** thin bright edge (top-left and bottom-right bias optional) to help define glass boundary.
5. **Tint + border:** overall tint with a faint border line.
6. **Optional dispersion:** very small RGB channel split driven by the refraction offset magnitude (default to 0).

**Shape:** rounded rectangle. The shader masks itself to rounded corners.

### Background Ambience

Use the existing background layer in the test scene when available. The glass card needs some background variation; if the screen is pure black, refraction/blur reads poorly.

---

## Technical Approach

### Files / Resources
- New shader: `res://assets/shaders/liquid_glass_ui.gdshader`
- New theme: `res://assets/themes/etn_glass_dark.theme.tres`
- New helper script: `res://script/ui/theme/etn_theme_factory.gd`

### Scene Integration (Test Scene)

We do not modify `.tscn` directly.

Integration happens in `res://scenes/test/launcher_update_check.gd`:
- Load and apply the Theme to the root Control (`self.theme = load(...)`).
- At runtime, create a `ColorRect` (or `Panel`) as the frosted card background, insert it beneath the content.
- Apply the ShaderMaterial to that card node.

### Shader Correctness Requirements
- Must compile in Godot 4.x as `shader_type canvas_item`.
- Must only rely on `SCREEN_TEXTURE` and `SCREEN_UV` (no external textures required).
- Must guard parameters to avoid invalid operations (e.g., clamp values).
- Must render correctly at different viewport sizes.

---

## Success Criteria / Acceptance Checklist

- The test scene `LauncherUpdateCheck` shows a centered frosted-glass card with rounded corners.
- Text and buttons look coherent (typography + primary/secondary styles).
- Refraction is subtle and lens-like, stronger near edges.
- Rim highlight is visible but not harsh.
- Effect remains stable (no flicker), and the UI stays readable.
- Default parameters avoid nausea: no strong wobble; noise is subtle.
