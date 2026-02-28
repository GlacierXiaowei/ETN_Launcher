# Liquid Glass Test Scene Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restore `res://scenes/test/launcher_update_check.gd` to its original behavior and create a new dedicated test scene under `res://scenes/test/` to showcase and tune the liquid-glass shader with UI sliders, without directly editing existing `.tscn` text files.

**Architecture:**
- Keep the liquid-glass shader and factory (`ETNThemeFactory`) reusable.
- Move all glass demo UI into a new test scene script (runtime-injected UI) so the existing update-check test scene remains stable.
- Provide sliders to tune key shader uniforms in real time.

**Tech Stack:** Godot 4.x, GDScript, CanvasItem shader.

---

## Current State (Living Notes)

This plan evolved during implementation:

- `LiquidGlassDemo` is now a normal `.tscn` + `.gd` test scene.
- Demo script no longer forces demo defaults by default; it reads current `ShaderMaterial` uniform values to populate sliders.
- Shader now uses a Fresnel-like rim highlight (2D approximation), isotropic blur kernels, and refraction shaping to reduce prism/cross artifacts.
- Blur quality is unified into a single `blur_quality` selector. `0` uses mip LOD only; higher values use increasingly expensive isotropic multi-tap blurs (17/65/257 taps).

---

### Task 1: Restore LauncherUpdateCheck script (no glass injection)

**Files:**
- Modify: `scenes/test/launcher_update_check.gd`

**Step 1: Capture current file for reference**

Run:
```bash
git show HEAD:scenes/test/launcher_update_check.gd > /tmp/launcher_update_check_current.gd
```
Expected: file written.

**Step 2: Restore script to original minimal version**

Replace `scenes/test/launcher_update_check.gd` contents with the pre-glass logic:
- Only `_init_install_component()` setup
- `install_component` wiring
- button actions
- no ETNThemeFactory usage
- no GlassCard injection

**Step 3: Manual check in editor**

Run the scene and confirm it behaves as before.

---

### Task 2: Create new liquid-glass demo script

**Files:**
- Create: `scenes/test/liquid_glass_demo.gd`

**Step 1: Implement demo scene UI in code**

Create a Control-based demo:
- Background TextureRect (texture left empty; user sets in editor)
- GlassCard (ColorRect + ShaderMaterial using `res://assets/shaders/liquid_glass_ui.gdshader`)
- Title Label + body RichTextLabel
- Primary/Secondary Buttons
- Right-side panel with sliders for:
  - `opacity`
  - `corner_radius_px`
  - `refraction_strength_px`
  - `edge_falloff_px`
  - `blur_lod_edge`
  - `rim_width_px`
  - `rim_intensity`
  - `border_width_px`
  - `dispersion_strength` (default 0)

On slider change:
- Update shader parameters live.

On resize:
- Update `rect_size_px` from the card size.

---

### Task 3: Create new demo scene (editor-created)

**Files:**
- Create (in Godot editor): `scenes/test/liquid_glass_demo.tscn`

**Step 1: Create scene nodes**

In editor:
- Root: `LiquidGlassDemo` (Control)
- Child: `Background` (TextureRect) — leave texture empty
- Child: `DemoRoot` (Control)

Attach script `res://scenes/test/liquid_glass_demo.gd` to the root.

---

### Task 4: (Optional) Add small helper UI components

**Files:**
- Create: `script/ui/widgets/labeled_slider.gd`

Implement a tiny reusable labeled slider component to reduce boilerplate.

---

### Task 5: Verification

Because Godot CLI may not be available:
- Manual editor run:
  - `LauncherUpdateCheck` still works
  - `LiquidGlassDemo` loads
  - Sliders update the glass card in real time
