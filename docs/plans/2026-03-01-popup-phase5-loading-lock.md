# Popup Phase5 Loading Lock Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a reliable "loading / interaction lock" state to the global popup system, plus fix PopupManager shortcut callback leaks, with a Phase5 test scene and updated docs.

**Architecture:**
- Keep `PopupManager.show_popup(config)` as the single entry point for creating popups.
- Implement loading as a *state transition* on the current popup when available; otherwise create a minimal "please wait" popup as the carrier.
- Preserve existing open/close animations; for state transitions, reuse `PopupManager.update_popup({"transition_animation": true})` when requested.
- Add a snapshot/restore mechanism so `hide_loading()` can revert the popup to its pre-loading state.

**Tech Stack:** Godot 4.x, GDScript, existing GlassComponent (`GlobalPopup`, `GlassButton`) and Tween animations.

---

### Task 1: Fix shortcut callback leakage (confirm/alert)

**Files:**
- Modify: `script/managers/popup_manager.gd`
- Test: `scenes/test/test_popup_phase5.tscn` (created in Task 4)

**Step 1: Add a one-shot connection helper (no behavior change yet)**

Implement a small helper in `PopupManager` that:
- Connects to `popup_button_pressed`.
- Disconnects itself after the first invocation.

Suggested code (exact shape may vary):

```gdscript
func _connect_popup_button_pressed_one_shot(cb: Callable) -> void:
    var wrapper := func(metadata: String) -> void:
        if popup_button_pressed.is_connected(wrapper):
            popup_button_pressed.disconnect(wrapper)
        cb.call(metadata)
    popup_button_pressed.connect(wrapper)
```

**Step 2: Update `show_confirm()` to use the one-shot helper**

Ensure that:
- callback only fires once
- the metadata routing remains the same (`confirm` / `cancel`)

**Step 3: Update `show_alert()` to use the one-shot helper**

Ensure that:
- callback only fires once
- metadata remains `ok`

**Step 4: Verify manually in Phase5 test scene**

Expected:
- Repeatedly opening confirm/alert does not accumulate callbacks.

---

### Task 2: Make `GlobalPopup.update()` merge config instead of replacing

**Files:**
- Modify: `component/GlassComponent/global_popup.gd`
- Test: `scenes/test/test_popup_phase5.tscn` (Task 4)

**Rationale:** Phase5 will frequently update only `buttons` and/or the label content. Replacing `_config` with a partial dictionary loses state and breaks snapshot/restore.

**Step 1: Change `update(config)` to merge**

Replace `_config = config` with a per-key merge:

```gdscript
for k in config.keys():
    _config[k] = config[k]
```

Then apply updates from `_config` (or from `config` only for fields present) but keep `_config` complete.

**Step 2: Keep behavior identical for existing callers**

Expected:
- Phase3 test scene behaviors remain unchanged.

---

### Task 3: Add loading/interaction lock APIs to GlobalPopup

**Files:**
- Modify: `component/GlassComponent/global_popup.gd`

**Step 1: Support `disabled` in button config**

In `_build_buttons(buttons)`:
- read `btn_config.get("disabled", false)`
- assign to `btn.disabled`

Example:

```gdscript
var is_disabled := btn_config.get("disabled", false) as bool
btn.disabled = is_disabled
```

**Step 2: Add helper methods for Phase5**

Add minimal methods (names can be adjusted, but keep them explicit):

- `func get_state_snapshot() -> Dictionary`
  - returns a dictionary containing at least: `title`, `content`, `content_type`, `buttons`, `size`
  - uses `_config` as the source of truth (after Task 2 merge fix)

- `func apply_loading_state(wait_button_text: String = "请稍候...", label_text: String = "") -> void`
  - removes existing buttons and replaces them with a single disabled button
  - does NOT modify richtext content if current `content_type == "richtext"`
  - if current `content_type == "label"`:
    - only set content when `label_text != ""`
  - keep title unchanged (unless caller updates via `update_popup`)

Implementation sketch:

```gdscript
func apply_loading_state(wait_button_text: String = "请稍候...", label_text: String = "") -> void:
    var ct := _config.get("content_type", "richtext") as String
    if ct != "richtext" and label_text != "":
        set_content(label_text, "label")

    set_buttons([
        {
            "text": wait_button_text,
            "type": "secondary",
            "metadata": "_loading",
            "stay_open": true,
            "disabled": true,
        }
    ])
```

---

### Task 4: Add loading APIs to PopupManager (A+B behavior)

**Files:**
- Modify: `script/managers/popup_manager.gd`
- Create: `scenes/test/test_popup_phase5.tscn`
- Create: `scenes/test/test_popup_phase5.gd`

**Step 1: Add internal fields to track loading**

Add:
- `_loading_snapshot: Dictionary = {}`
- `_loading_active: bool = false`
- `_loading_popup_ref: GlobalPopup = null` (optional)

**Step 2: Implement `show_loading(...)`**

Signature proposal:

```gdscript
func show_loading(title: String = "请稍候", label_text: String = "请稍候...", use_fade: bool = true) -> void
```

Behavior:
- If `has_open_popup()`:
  - snapshot current popup state via `get_state_snapshot()`
  - mark loading active
  - transition the popup to loading state:
    - optionally call `update_popup({"transition_animation": use_fade})` first or reuse `update_with_fade` by sending a config update
    - call `_current_popup.apply_loading_state("请稍候...", label_text)`
- Else:
  - `show_popup({"size":"medium","title":title,"content_type":"label","content":label_text,"buttons":[ ... disabled wait ... ]})`
  - mark loading active; store snapshot as empty (or store the initial state as snapshot if you want restore)

**Step 3: Implement `hide_loading(...)`**

Signature proposal:

```gdscript
func hide_loading(restore_config: Dictionary = {}, use_fade: bool = true) -> void
```

Behavior:
- If no popup open: return
- If `restore_config` not empty:
  - set `restore_config["transition_animation"] = use_fade` if not specified
  - call `update_popup(restore_config)`
- Else if `_loading_snapshot` not empty:
  - call `update_popup(_loading_snapshot.merged({"transition_animation": use_fade}, true))`
- Clear loading flags and snapshot

**Step 4: Create Phase5 test scene**

Create a new test scene similar to Phase3/Phase4 tests.

Required buttons in the test UI:
- "Confirm x3" (open confirm 3 times, verify callbacks do not multiply)
- "Alert x3" (same)
- "Popup -> Loading -> Restore"
- "No popup -> show_loading"
- "Loading -> hide_loading(restore_config)" (switch to a finished state with real buttons)

The script should print to output and update a status label.

---

### Task 5: Update docs

**Files:**
- Modify: `docs/glass-components-api-guide.md`
- Modify: `docs/项目设计与实践指南.md`

**Step 1: Update `docs/glass-components-api-guide.md`**

Add a new section:
- `## PopupManager` with:
  - `show_popup(config)` reference (brief)
  - shortcut APIs: `show_confirm`, `show_alert`
  - loading APIs: `show_loading`, `hide_loading` with semantics (A+B) and examples

**Step 2: Update `docs/项目设计与实践指南.md`**

In the popup system chapter, add a short subsection:
- Loading/interaction lock pattern
- Example: show a popup, then `PopupManager.show_loading(...)`, then `PopupManager.hide_loading({ ... })`

---

### Task 6: Verification

**Manual verification checklist:**
- Phase3 test still works: `res://scenes/test/test_popup_phase3.tscn`
- Phase4 test still works: `res://scenes/test/test_popup_phase4.tscn`
- Phase5 test covers:
  - loading enter/exit with snapshot restore
  - restore via explicit `restore_config`
  - confirm/alert callbacks do not leak across invocations
