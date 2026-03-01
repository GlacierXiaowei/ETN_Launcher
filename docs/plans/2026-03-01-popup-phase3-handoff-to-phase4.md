# Phase3 Handoff -> Phase4 Effects

## Phase3 Done

### Goals
Implement dynamic popup content updates and a robust callback mechanism that supports:
- Update-in-place (keep popup open)
- Close and then show a new popup (chained flow)

### Key Decisions
- Button press always yields a metadata callback.
- Default behavior: clicking a button closes the popup.
- Per-button override: `stay_open: true` keeps the popup open.

### Signal Semantics (Current)

**GlobalPopup** (res://component/GlassComponent/global_popup.gd)
- `signal button_pressed(metadata: String)`
  - Emitted for any button press.
  - Always emits, regardless of `stay_open`.
- `signal closed`
  - Emitted after the close animation finishes.

**PopupManager** (res://script/managers/popup_manager.gd)
- `signal popup_button_pressed(metadata: String)`
  - Business-level callback; forwards GlobalPopup.button_pressed.
- `signal popup_closed`
  - Lifecycle event; emitted after GlobalPopup.closed.

### Popup Update API

**PopupManager**
- `update_popup(config: Dictionary) -> bool`
  - Updates current popup without closing it.
  - If `config["transition_animation"] == true`, uses fade transition.
- `close_and_show_new(config: Dictionary) -> void`
  - Closes current popup and then opens a new one.
  - Implemented by awaiting the closing popup instance's `closed` signal to avoid race conditions.

### Button Auto Size
GlassButton auto-sizes to its text by default.
- File: res://component/GlassComponent/glass_button.gd
- Behavior: adjusts `custom_minimum_size` based on label text + padding.

### Test Scene
- res://scenes/test/test_popup_phase3.tscn
- res://scenes/test/test_popup_phase3.gd

Covered cases:
- Update-in-place step flow (1/3 -> 2/3 -> 3/3)
- Update-with-fade transition
- Close and open new popup
- has_open_popup() state check

## Phase4 Context

Phase4 focuses on effects and interaction safety:
- Dim background (config-driven)
- Close effects (shader blur overlay / fade)
- Input blocking during animations
- Consistent corner radius across overlays

The signal split done in Phase3 (button_pressed vs closed) is intended to make Phase4 animation and lifecycle handling predictable.
