# Game Card Component - Phase 2: 漂浮、阴影与 3D 倾斜

> **开发模式:** 助手提供代码和指导，用户手动创建和修改文件
> **重要原则:** 未经用户许可，助手不得直接修改 .tscn 场景文件

**Goal:** 实现 Oscillator 物理漂浮系统、动态阴影偏移、鼠标悬停"拾起"效果（漂浮增强 + 缩放 + 平滑过渡）。

---

## 工作流规则

### ✅ 已达成共识

1. **Oscillator 设计**: 使用纯类（非 Node），轻量级工具类
   - 原因: 一个卡片需要2个振荡器，做成 Node 会臃肿
   - 使用方式: `var osc = Oscillator.new()` 后手动调用 `update(delta)`

2. **文件创建方式**: 
   - 助手提供完整代码+详细注释
   - 用户自行创建文件
   - 助手检查并提供反馈

3. **TSCN 文件保护**:
   - ❌ 助手绝不直接修改现有 .tscn 文件
   - ✅ 可以提供节点添加指南，由用户在 Godot 编辑器中操作

---

## Phase 1 交接文档

### ✅ Phase 1 完成清单

#### 1. Shader 资源
| 文件 | 状态 |
|------|------|
| `assets/shaders/fake_3d.gdshader` | ✅ 已存在 |
| `assets/shaders/dissolve.gdshader` | ✅ 已创建 |

#### 2. 组件脚本
| 文件 | 状态 |
|------|------|
| `scenes/card/components/card_visual_component.gd` | ✅ 已创建 |
| `scenes/card/components/card_input_handler.gd` | ✅ 已创建 |

#### 3. GameCard 主场景
| 文件 | 状态 |
|------|------|
| `scenes/card/game_card.gd` | ✅ 已创建 |
| `scenes/card/game_card.tscn` | ✅ 已创建 |

#### 4. 测试场景
| 文件 | 状态 |
|------|------|
| `scenes/test/game_card/test_phase_1.gd` | ✅ 已创建 |
| `scenes/test/game_card/test_phase_1.tscn` | ✅ 已创建 |

### 🔧 Phase 1 核心功能

| 功能 | 实现方式 |
|------|----------|
| 鼠标悬停检测 | `mouse_entered` / `mouse_exited` 信号 |
| 点击检测 | `pressed` 信号 |
| 3D 倾斜 | `fake_3d.gdshader` + `_on_gui_input()` |
| 悬停缩放 | Tween + `TRANS_ELASTIC` |
| 信号系统 | 5 个自定义信号 |
| 调试输出 | 完整 `print()` 日志 |

### 📐 Phase 1 最终参数配置（已调整）

```gdscript
# 卡片尺寸
card_scale = 0.4                # 卡片尺寸（视口 40%）

# 倾斜角度
angle_x_max = 8.0°              # X 轴最大倾斜（已降低）
angle_y_max = 8.0°              # Y 轴最大倾斜（已降低）

# 悬停动画
hover_scale = 1.075             # 悬停放大倍数（7.5%）
hover_duration = 0.4s           # 悬停动画时长
recover_duration = 0.75s        # 恢复动画时长
tilt_reset_duration = 0.3s      # 倾斜复位时长
```

### ⚠️ 重要注意事项

#### 1. UID 冲突问题
- 已修复 `game_card.tscn` 和 `shader_test_scene.tscn` 的 UID 冲突
- `game_card.tscn` UID 改为 `uid://c8yvxg3ulq3a`

#### 2. 信号连接
- 依赖场景文件的 `[connection]`，脚本中不重复连接
- 4 个信号：`gui_input`, `mouse_entered`, `mouse_exited`, `pressed`

#### 3. 角度单位
- 使用弧度制（`deg_to_rad()` 转换）
- `_ready()` 中转换：`angle_x_max = deg_to_rad(angle_x_max)`

#### 4. 场景操作 ⚠️ 重要

**问题**：`game_card.tscn` 中有硬编码尺寸，会覆盖脚本的 `card_scale` 设置

**硬编码值**（第 22-34 行）：
```ini
custom_minimum_size = Vector2(1152, 648)  # 硬编码
offset_left = -576.0                       # 硬编码
pivot_offset = Vector2(576, 324)           # 硬编码
```

**解决方案**：
1. 在 Godot 中打开 `scenes/card/game_card.tscn`
2. 选中根节点 `GameCard`
3. 右键重置以下属性为默认值：
   - `Custom Minimum Size`
   - `Offset Left/Top/Right/Bottom`
   - `Pivot Offset`
4. 保存场景

**原因**：只有 `card_scale = 0.6` 时计算结果 (1920×0.6=1152) 与硬编码值一致，其他值会冲突

#### 5. 缩放中心问题
- 脚本中已正确设置：`pivot_offset = custom_minimum_size / 2.0`
- 但场景文件的硬编码 `pivot_offset` 会覆盖脚本设置
- 必须先重置场景文件中的硬编码值

---

## Phase 2 实现指南

### 📋 待实现功能清单

| 功能 | 阶段 | 文件 |
|------|------|------|
| Oscillator 物理漂浮系统 | Phase 2 | `component/Card/oscillator.gd` |
| CardAnimationComponent | Phase 2 | `component/Card/card_animation_component.gd` |
| CardShadowComponent | Phase 2 | `component/Card/card_shadow_component.gd` |
| GameCard 集成 | Phase 2 | 修改 `scenes/card/game_card.gd` |
| Phase 2 测试场景 | Phase 2 | `scenes/test/game_card/test_phase_2.gd` |

---

## Task 1: Oscillator 工具类

**状态:** ✅ 已完成

**文件位置:** `component/Card/oscillator.gd`

**实现要点:**
- 纯类设计，不继承 Node
- 基于弹簧-阻尼物理模型
- 支持启用/禁用控制

**关键代码片段:**
```gdscript
func update(delta: float) -> void:
    if not enabled:
        return
    var force = -spring * displacement - damp * velocity
    velocity += force * delta
    displacement += velocity * delta
```

---

## Task 2: CardAnimationComponent

**状态:** 📝 待创建（等待用户确认路径）

**建议文件位置:** 
- 选项A: `component/Card/card_animation_component.gd`（推荐，统一放在 component 下）
- 选项B: `scenes/card/components/card_animation_component.gd`（按场景组织）

**请告诉我您选择哪个路径，我提供完整代码。**

**功能预览:**
- 管理两个 Oscillator 实例（X/Y轴）
- 提供漂浮幅度过渡动画
- 封装缩放和3D倾斜逻辑
- 所有动画支持打断和重新触发

---

## Task 3: CardShadowComponent

**状态:** 📝 待创建

**建议文件位置:** 
- 与 CardAnimationComponent 相同目录

**功能预览:**
- 根据卡片与屏幕中心的距离计算阴影偏移
- 使用 Tween 实现平滑过渡
- Balatro 风格的动态阴影效果

---

## Task 4: GameCard 集成

**状态:** 📝 待提供代码

**说明:** 
- 将提供 `game_card.gd` 的修改代码
- 包含详细的修改说明（在第几行插入什么代码）
- **不会直接修改 TSCN 文件**，只提供节点添加指南

---

## Task 5: 场景配置指南

**状态:** 📝 待提供

**将在用户创建完脚本后提供:**
1. 如何在 Godot 编辑器中添加新组件节点
2. 如何配置节点引用路径
3. 如何验证连接是否正确

---

## 参考资源

### Balatro 代码启示

从 `godot_ui_components-main/scenes/balatro/scripts/card.gd` 学到的关键技术:

1. **Oscillator 使用方式:**
```gdscript
# 声明变量
var displacement: float = 0.0 
var oscillator_velocity: float = 0.0

# _process 中更新
func rotate_velocity(delta: float) -> void:
    var force = -spring * displacement - damp * oscillator_velocity
    oscillator_velocity += force * delta
    displacement += oscillator_velocity * delta
    rotation = displacement
```

2. **阴影偏移计算:**
```gdscript
func handle_shadow(delta: float) -> void:
    var center: Vector2 = get_viewport_rect().size / 2.0
    var distance: float = global_position.x - center.x
    shadow.position.x = lerp(0.0, -sign(distance) * max_offset_shadow, abs(distance/(center.x)))
```

3. **Tween 动画最佳实践:**
```gdscript
# 总是先停止之前的动画
if tween_hover and tween_hover.is_running():
    tween_hover.kill()

# 创建新动画
tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
tween_hover.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)
```

---

## 验收标准

1. ✅ 空闲时卡面自然上下漂浮（±8-12px）
2. ✅ 鼠标悬停时漂浮幅度平滑增大至±15-20px
3. ✅ 鼠标悬停时卡面弹性放大到 1.08 倍
4. ✅ 3D 倾斜跟随鼠标位置，角度范围±15 度
5. ✅ 从边缘进入时有平滑过渡动画（Tween）
6. ✅ 鼠标离开时恢复动画流畅自然
7. ✅ 阴影随卡面水平位置偏移（Balatro 风格）
8. ✅ 所有变换以中心点为锚点
9. ✅ 组件化结构清晰，动画逻辑封装在 CardAnimationComponent 中

---

## 下一步行动

**请用户选择:**

1. **确认 CardAnimationComponent 的文件路径**
   - A: `component/Card/card_animation_component.gd`
   - B: `scenes/card/components/card_animation_component.gd`

2. **是否现在接收 CardAnimationComponent 的完整代码？**

---

*Plan version: 2.1*
*Phase: 2/5 - 漂浮、阴影与 3D 倾斜*
*Last Updated: 2026-03-02*
