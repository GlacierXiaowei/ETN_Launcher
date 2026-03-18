# Scene Loading API 参考

> 场景加载动画系统 - 三种加载模式与三段式动画切换

**版本：** 1.0  
**最后更新：** 2026-03-18

---

## 🚀 快速开始

### 30 秒上手

**Scene Loading System** 是一个基于信号的场景加载动画系统，支持三种加载模式，提供流畅的场景切换体验。

外部只需**调用 1 个方法**即可完成带动画的场景切换。

---

### 基础用法

```gdscript
# 硬切加载（无动画）
SceneManager.switch_scene_with_loading("res://scenes/main.tscn", SceneManager.LOADING_MODE_HARD)

# 模糊加载（仅模糊效果）
SceneManager.switch_scene_with_loading("res://scenes/main.tscn", SceneManager.LOADING_MODE_BLUR)

# 黑屏加载（黑屏淡入淡出）
SceneManager.switch_scene_with_loading("res://scenes/main.tscn", SceneManager.LOADING_MODE_BLACK)

# 完整加载（模糊 + 视频动画）
SceneManager.switch_scene_with_loading("res://scenes/main.tscn", SceneManager.LOADING_MODE_FULL)
```

---

## 1. 四种加载模式

| 模式 | 常量 | 说明 | 适用场景 |
|------|------|------|----------|
| 硬切 | `LOADING_MODE_HARD` | 直接切换，无动画 | 快速切换、不需要过渡效果 |
| 模糊 | `LOADING_MODE_BLUR` | 仅模糊效果，无视频 | 轻量过渡、保持简洁 |
| 黑屏 | `LOADING_MODE_BLACK` | 黑屏淡入淡出 | 简洁过渡、经典效果 |
| 完整 | `LOADING_MODE_FULL` | 模糊 + 视频动画 | 重要场景切换、沉浸体验 |

---

## 2. 动画流程

### 2.1 FULL 模式（完整加载）

```
┌─────────────────────────────────────────────────────────────────┐
│                    完整加载模式流程                              │
└─────────────────────────────────────────────────────────────────┘

开始
  │
  ▼
[1] SceneManager 切换到 loading_scene
  │
  ▼
[2] loading_scene 播放模糊动画 (0→8.0) + 开始播放视频
  │
  ▼
[3] 到达 8.0 时发出 blur_animation_completed（视频继续播放）
  │
  ▼
[4] SceneManager 清理原始场景
  │
  ▼
[5] SceneManager 调用 _load_target_scene_async()
  │
  ▼
[6] SceneManager 添加新场景到根节点，发出 scene_load_completed
  │
  ▼
[7] loading_scene 播放恢复动画 (8.0→0)（视频继续播放）
  │
  ▼
[8] 恢复完成，停止视频，发出 transition_completed
  │
  ▼
[9] SceneManager 清理 loading_scene
  │
  ▼
完成
```

**动画时间：**
- 模糊动画：0.5 秒
- 恢复动画：0.5 秒
- 总计：1 秒

---

### 2.2 BLACK 模式（黑屏加载）

```
开始
  │
  ▼
[1] SceneManager 切换到 loading_scene
  │
  ▼
[2] loading_scene 黑屏淡入 (0→1.0)
  │
  ▼
[3] 发出 blur_animation_completed
  │
  ▼
[4] SceneManager 清理原始场景
  │
  ▼
[5] SceneManager 加载新场景并添加到根节点
  │
  ▼
[6] 发出 scene_load_completed
  │
  ▼
[7] loading_scene 黑屏淡出 (1.0→0)
  │
  ▼
[8] 发出 transition_completed
  │
  ▼
[9] SceneManager 清理 loading_scene
  │
  ▼
完成
```

**动画时间：**
- 黑屏淡入：0.3 秒
- 黑屏淡出：0.3 秒
- 总计：0.6 秒

**注意：** BLACK 模式只操作 `BlackBackground` 的 `modulate.a`，不涉及 blur shader，性能更优。

---

## 3. SceneManager API

**路径：** `script/managers/scene_manager.gd`

### 3.1 常量

```gdscript
const LOADING_MODE_HARD = "hard"    # 硬切加载
const LOADING_MODE_BLUR = "blur"    # 背景模糊
const LOADING_MODE_BLACK = "black"  # 黑屏加载
const LOADING_MODE_FULL = "full"    # 完整加载
```

---

### 3.2 信号

```gdscript
signal scene_switch_started(scene_path)      # 场景切换开始
signal scene_switch_completed(scene_path)    # 场景切换完成
signal scene_switch_failed(error_message)    # 场景切换失败
signal scene_load_completed(loaded_scene)    # 新场景加载完成
```

**信号触发时机：**

| 信号 | 触发时机 | 参数 |
|------|----------|------|
| `scene_switch_started` | 调用 `switch_scene_with_loading` 时 | 场景路径 |
| `scene_load_completed` | 新场景实例化并添加到场景树后 | 新场景节点 |
| `scene_switch_completed` | 场景切换完全结束后 | 场景路径 |
| `scene_switch_failed` | 场景不存在或加载失败时 | 错误信息 |

---

### 3.3 方法

#### `switch_scene(scene_path: String) -> void`

直接切换场景（无动画）。

**参数：**
- `scene_path`: 目标场景路径

**示例：**

```gdscript
SceneManager.switch_scene("res://scenes/main.tscn")
```

---

#### `switch_scene_with_loading(scene_path: String, mode: String = LOADING_MODE_FULL) -> void`

带动画的场景切换。

**参数：**
- `scene_path`: 目标场景路径
- `mode`: 加载模式（默认为 FULL）

**示例：**

```gdscript
# 使用默认模式（FULL）
SceneManager.switch_scene_with_loading("res://scenes/game.tscn")

# 指定模式
SceneManager.switch_scene_with_loading("res://scenes/menu.tscn", SceneManager.LOADING_MODE_BLUR)

# 硬切模式
SceneManager.switch_scene_with_loading("res://scenes/splash.tscn", SceneManager.LOADING_MODE_HARD)
```

---

#### `get_current_scene() -> Node`

获取当前场景节点。

**返回值：** 当前场景节点

**示例：**

```gdscript
var current = SceneManager.get_current_scene()
print("当前场景：", current.name)
```

---

#### `is_scene_loading() -> bool`

检查是否正在加载场景。

**返回值：** `true` 表示正在加载

**示例：**

```gdscript
if SceneManager.is_scene_loading():
    print("场景正在加载中...")
```

---

### 3.4 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `current_scene` | Node | 当前场景节点 |
| `is_loading` | bool | 是否正在加载 |

---

## 4. LoadingScene API

**路径：** `scenes/loading/loading_scene.gd`

### 4.1 枚举与属性

```gdscript
enum LoadingMode { FULL, BLUR, BLACK }
var loading_mode: LoadingMode = LoadingMode.FULL
```

**加载模式说明：**

| 模式 | 效果 |
|------|------|
| `FULL` | 模糊 + 视频动画 |
| `BLUR` | 仅模糊效果 |
| `BLACK` | 黑屏淡入淡出 |

---

### 4.2 信号

```gdscript
signal blur_animation_completed      # 第一段动画完成
signal transition_completed          # 第三段动画完成
```

**信号触发时机：**

| 信号 | 触发时机 |
|------|----------|
| `blur_animation_completed` | 进入动画完成时（模糊到 8.0 或黑屏淡入完成） |
| `transition_completed` | 退出动画完成时（模糊恢复或黑屏淡出完成） |

---

## 5. 完整使用示例

### 5.1 基础场景切换

```gdscript
extends Control

func _on_play_button_pressed() -> void:
    SceneManager.switch_scene_with_loading("res://scenes/game.tscn", SceneManager.LOADING_MODE_FULL)

func _on_settings_button_pressed() -> void:
    SceneManager.switch_scene_with_loading("res://scenes/settings.tscn", SceneManager.LOADING_MODE_BLUR)
```

---

### 5.2 监听切换事件

```gdscript
extends Node

func _ready() -> void:
    SceneManager.scene_switch_started.connect(_on_scene_switch_started)
    SceneManager.scene_switch_completed.connect(_on_scene_switch_completed)
    SceneManager.scene_switch_failed.connect(_on_scene_switch_failed)

func _on_scene_switch_started(scene_path: String) -> void:
    print("开始切换到：", scene_path)
    # 可以在这里禁用UI交互

func _on_scene_switch_completed(scene_path: String) -> void:
    print("切换完成：", scene_path)
    # 可以在这里重新启用UI交互

func _on_scene_switch_failed(error_message: String) -> void:
    print("切换失败：", error_message)
    # 可以在这里显示错误提示
```

---

### 5.3 自定义加载逻辑

```gdscript
extends Node

func change_scene_with_callback(scene_path: String) -> void:
    # 监听加载完成信号
    SceneManager.scene_load_completed.connect(_on_new_scene_loaded, CONNECT_ONE_SHOT)
    SceneManager.switch_scene_with_loading(scene_path)

func _on_new_scene_loaded(new_scene: Node) -> void:
    # 新场景加载完成后执行自定义逻辑
    print("新场景已加载：", new_scene.name)
    
    # 可以在这里初始化新场景的数据
    if new_scene.has_method("initialize"):
        new_scene.initialize()
```

---

### 5.4 防止重复切换

```gdscript
extends Control

func _on_button_pressed() -> void:
    if SceneManager.is_scene_loading():
        print("场景正在加载，请稍候...")
        return
    
    SceneManager.switch_scene_with_loading("res://scenes/next.tscn")
```

---

## 6. 信号流程图

```
用户调用 switch_scene_with_loading()
    │
    │ scene_switch_started
    ▼
loading_scene 创建并添加到场景树
    │
    │ 开始模糊动画
    ▼
blur_animation_completed
    │
    │ SceneManager 清理原始场景
    ▼
加载新场景（load + instantiate）
    │
    │ 添加新场景到场景树
    │ scene_load_completed
    ▼
loading_scene 播放恢复动画
    │
    │ transition_completed
    ▼
SceneManager 清理 loading_scene
    │
    │ scene_switch_completed
    ▼
完成
```

---

## 7. 文件结构

```
scenes/
├── loading/
│   ├── loading_scene.gd      # 加载场景脚本
│   └── loading_scene.tscn    # 加载场景文件

script/
└── managers/
    └── scene_manager.gd      # 场景管理器

component/
└── small_loding_player.tscn  # 加载视频播放器组件

assets/
└── shaders/
    └── transition_blur.gdshader  # 模糊着色器
```

---

## 8. 常见问题

### Q1: 如何自定义加载动画的视频？

**答：** 修改 `component/small_loding_player.tscn` 中的视频资源。

---

### Q2: 如何调整模糊强度或动画时间？

**答：** 修改 `scenes/loading/loading_scene.gd` 中的参数：

```gdscript
func _perform_blur_animation() -> void:
    # 修改模糊强度（默认 8.0）
    var blur_amount = 8.0
    
    # 修改动画时间（默认 0.5 秒）
    var duration = 0.5
    
    tween.tween_property(background_blur.material, "shader_parameter/blur_amount", blur_amount, duration)
```

---

### Q3: 为什么 BLUR 模式也使用 loading_scene？

**答：** 为了保持代码简洁和动画一致性。BLUR 模式设置 `play_video = false`，其他流程与 FULL 模式相同。

---

### Q4: 如何在加载完成后执行特定逻辑？

**答：** 监听 `scene_load_completed` 信号：

```gdscript
SceneManager.scene_load_completed.connect(func(new_scene):
    print("新场景：", new_scene.name)
)
```

---

### Q5: 加载过程中用户点击会怎样？

**答：** loading_scene 使用 CanvasLayer（Layer 5），会覆盖所有 UI 并阻止输入事件。

---

## 9. 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.1 | 2026-03-18 | 新增 BLACK 黑屏加载模式 |
| 1.0 | 2026-03-18 | 初始版本 - 三种加载模式、三段式动画 |

---

## 附录：模式对比

| 特性 | HARD | BLUR | BLACK | FULL |
|------|------|------|-------|------|
| 动画效果 | 无 | 模糊 | 黑屏淡入淡出 | 模糊 + 视频 |
| 加载时间 | 最快 | 中等 | 中等 | 中等 |
| 视觉反馈 | 无 | 有 | 有 | 最强 |
| 适用场景 | 快速切换 | 轻量过渡 | 经典过渡 | 重要切换 |
| 动画时长 | 0秒 | 1秒 | 0.6秒 | 1秒 |