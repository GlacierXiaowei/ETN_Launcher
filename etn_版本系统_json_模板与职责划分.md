# ETN 版本系统 JSON 模板与职责划分

目标： 明确：

- 游戏本体是否需要版本号
- 版本号存储在哪里
- 启动器与游戏分别使用哪些 JSON
- 如何进行版本对比

---

# 一、核心设计原则

1. 游戏本体必须有“内置基础版本号”
2. 启动器维护“运行时版本状态”
3. 服务器提供“最新版本信息”
4. 三者职责分离

---

# 二、版本号分层结构

建议使用三层版本体系：

- build\_version      → 游戏编译版本（写死在程序内）
- game\_version       → 对外显示版本
- patch\_level        → 补丁等级（递增数字）

示例语义：

build\_version = 1.0.0 patch\_level  = 3

最终显示版本 = 1.0.0 + Patch 3

---

# 三、游戏本体需要什么？

游戏内部：

✅ 必须有一个“内置版本号常量”

例如：

```
const BUILD_VERSION = "1.0.0"
```

作用：

- 用于 UI 显示
- 用于日志
- 用于与启动器校验

⚠ 不建议让游戏自己写版本 JSON。 版本管理应由启动器负责。

---

# 四、启动器使用的本地 JSON 模板

文件位置： user://version.json

模板：

{ "build\_version": "1.0.0", "patch\_level": 3, "installed\_patches": [ "patch\_001.pck", "patch\_002.pck", "patch\_003.pck" ], "files": { "ETN.pck": "sha256\_hash\_here", "patch\_001.pck": "sha256\_hash\_here", "patch\_002.pck": "sha256\_hash\_here", "patch\_003.pck": "sha256\_hash\_here" }, "last\_update\_time": "2026-02-21T12:00:00" }

字段说明：

build\_version → 当前基础版本（必须与游戏内置一致）

patch\_level → 当前最高补丁编号

installed\_patches → 实际存在的补丁文件列表

files → 文件完整性校验

last\_update\_time → 记录更新时间

---

# 五、服务器端 version.json 模板

服务器提供的文件：

{ "latest\_build\_version": "1.0.0", "latest\_patch\_level": 5, "patches": [ { "name": "patch\_004.pck", "hash": "sha256\_hash\_here", "size": 10485760 }, { "name": "patch\_005.pck", "hash": "sha256\_hash\_here", "size": 2097152 } ], "force\_update": false }

字段说明：

latest\_build\_version → 若变化，说明需要整包更新

latest\_patch\_level → 启动器需要补齐到此等级

patches → 可下载补丁信息

force\_update → 是否强制更新

---

# 六、版本对比逻辑

启动器启动流程：

1. 读取 user://version.json

2. 请求服务器 version.json

3. 对比：

   如果 latest\_build\_version != build\_version → 必须整包更新

   如果 latest\_patch\_level > patch\_level → 下载缺失补丁

4. 校验 Hash

5. 更新本地 version.json

6. 启动游戏

---

# 七、游戏是否需要读取 version.json？

建议：

游戏只读取：

- build\_version（内部常量）
- 当前 patch\_level（从启动参数传入）

启动器启动游戏时可以传入：

```
ETN.exe --patch_level=3
```

游戏只用于显示，不参与下载决策。

---

# 八、职责最终划分

启动器负责：

- 网络
- 下载
- 校验
- 写入 version.json
- 决定是否允许启动

游戏负责：

- 加载 PCK
- 显示版本
- 正常运行

服务器负责：

- 提供最新版本信息
- 提供补丁文件

---

# 九、当前阶段建议

第一阶段可以简化为：

本地 version.json 仅包含：

{ "build\_version": "1.0.0", "patch\_level": 0 }

等系统跑通后，再加入：

- hash
- installed\_patches
- 日志字段

---

# 十、关键认知

版本号不是用来炫耀的。

它的作用是：

- 决定更新路径
- 保证结构一致
- 提供排错依据

当版本体系清晰时，热更新就不会失控。

