# Loading Scene Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create an independent LoadingScene for smooth scene transitions with background blur and loading animation.

**Architecture:** Create a dedicated LoadingScene that handles background blurring via shader and displays loading animation, integrated with enhanced SceneManager for seamless transitions.

**Tech Stack:** Godot 4.x, GDScript, transition_blur.gdshader, VideoStreamPlayer

---

### Task 1: Create Loading Scene Structure

**Files:**
- Create: `scenes/loading/loading_scene.tscn`
- Create: `scenes/loading/loading_scene.gd`

**Step 1: Create directory structure**

```bash
mkdir -p scenes/loading
```

**Step 2: Create LoadingScene script**

```gdscript
# scenes/loading/loading_scene.gd
extends Control

@onready var background_blur = $CanvasLayer/BackgroundBlur
@onready var loading_player = $CanvasLayer/SmallLodingPlayer

func _ready() -> void:
	# Ensure blur is active
	background_blur.material.set_shader_parameter("blur_amount", 2.0)
	
	# Start loading animation if not already playing
	if not loading_player.is_playing():
		loading_player.play()

func set_target_scene(target_path: String) -> void:
	# Store target scene path for later use
	# This will be called by SceneManager before switching
	pass

func finish_loading() -> void:
	# Called when loading is complete
	# Will trigger scene switch back to SceneManager
	pass
```

**Step 3: Create LoadingScene.tscn structure**

Create scene with following node hierarchy:
- LoadingScene (Control)
  - CanvasLayer (layer=5)
    - BackgroundBlur (ColorRect with transition_blur.gdshader material)
    - SmallLodingPlayer (instance of component/small_loding_player.tscn)
  - Timer (wait_time=0.5, one_shot=true)

**Step 4: Configure BackgroundBlur**

Set BackgroundBlur properties:
- anchors_preset = 15 (full rect)
- material = New ShaderMaterial with transition_blur.gdshader
- Set rect_size_px uniform to match screen size in _ready()

**Step 5: Commit**

```bash
git add scenes/loading/
git commit -m "feat: create loading scene structure"
```

### Task 2: Enhance SceneManager

**Files:**
- Modify: `script/managers/scene_manager.gd`

**Step 1: Add new methods to SceneManager**

```gdscript
# Add to scene_manager.gd
var loading_scene_path = "res://scenes/loading/loading_scene.tscn"
var target_scene_to_load = ""

func switch_scene_with_loading(scene_path: String) -> void:
	target_scene_to_load = scene_path
	call_deferred("_switch_to_loading_scene")

func _switch_to_loading_scene() -> void:
	if not ResourceLoader.exists(loading_scene_path):
		push_error("Loading scene not found: " + loading_scene_path)
		return
	
	var loading_scene = load(loading_scene_path).instantiate()
	get_tree().root.add_child(loading_scene)
	
	if current_scene:
		current_scene.queue_free()
	
	current_scene = loading_scene
	
	# Start async loading of target scene
	await _load_and_switch(target_scene_to_load)

func _load_and_switch(target_scene_path: String) -> void:
	if not ResourceLoader.exists(target_scene_path):
		push_error("Target scene not found: " + target_scene_path)
		return
	
	# Simulate loading time or actually load resource
	await get_tree().create_timer(0.5).timeout
	
	var new_scene = load(target_scene_path).instantiate()
	get_tree().root.add_child(new_scene)
	
	if current_scene:
		current_scene.queue_free()
	
	current_scene = new_scene
	target_scene_to_load = ""
```

**Step 2: Update existing _switch_scene method**

Modify `_switch_scene` to handle loading scene properly:

```gdscript
func _switch_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_error("Scene not found: " + scene_path)
		return
	 
	var new_scene = load(scene_path).instantiate()
	get_tree().root.add_child(new_scene)
	
	if current_scene and current_scene.name != "LoadingScene":
		current_scene.queue_free()
	
	current_scene = new_scene
```

**Step 3: Test SceneManager enhancement**

Create simple test to verify methods exist and can be called.

**Step 4: Commit**

```bash
git add script/managers/scene_manager.gd
git commit -m "feat: enhance scene manager with loading support"
```

### Task 3: Implement LoadingScene Logic

**Files:**
- Modify: `scenes/loading/loading_scene.gd`

**Step 1: Add signal connection for completion**

```gdscript
# Add to _ready() in loading_scene.gd
func _ready() -> void:
	background_blur.material.set_shader_parameter("blur_amount", 2.0)
	
	if not loading_player.is_playing():
		loading_player.play()
	
	# Connect to SceneManager's loading completion
	# Since we can't directly reference SceneManager, use timer-based approach
	$Timer.start()

func _on_timer_timeout() -> void:
	# Notify SceneManager that loading is complete
	# SceneManager will handle the actual scene switch
	if SceneManager:
		SceneManager._load_and_switch(SceneManager.target_scene_to_load)
```

**Step 2: Handle screen size updates**

Add method to update blur shader parameters when screen resizes:

```gdscript
func _process(_delta: float) -> void:
	# Update rect_size_px for proper corner rendering
	var screen_size = get_viewport().get_visible_rect().size
	background_blur.material.set_shader_parameter("rect_size_px", screen_size)
```

**Step 3: Add error handling**

Add try-catch around critical operations and proper cleanup.

**Step 4: Commit**

```bash
git add scenes/loading/loading_scene.gd
git commit -m "feat: implement loading scene logic"
```

### Task 4: Update Splash Screen Transition

**Files:**
- Modify: `scenes/splash/splash_screen.gd` (assuming it exists)

**Step 1: Change splash completion to use loading scene**

Find where splash screen currently switches to main menu and update:

```gdscript
# Replace direct scene switch with loading scene switch
# Old: SceneManager.switch_scene("res://scenes/main/main_menu.tscn")
# New: SceneManager.switch_scene_with_loading("res://scenes/main/main_menu.tscn")
```

**Step 2: Verify splash screen integration**

Test that splash → loading → main menu flow works correctly.

**Step 3: Commit**

```bash
git add scenes/splash/splash_screen.gd
git commit -m "feat: update splash screen to use loading scene"
```

### Task 5: Testing and Validation

**Files:**
- Create: `scenes/test/loading_test_scene.tscn`

**Step 1: Create test scene**

Create simple test scene to verify loading functionality.

**Step 2: Manual testing procedure**

1. Run project from start
2. Verify splash shows, then loading scene with blur + animation
3. Verify main menu loads correctly
4. Test direct scene switches using new method

**Step 3: Performance validation**

Ensure loading scene doesn't cause memory leaks or performance issues.

**Step 4: Commit test files**

```bash
git add scenes/test/loading_test_scene.tscn
git commit -m "test: add loading scene test"
```