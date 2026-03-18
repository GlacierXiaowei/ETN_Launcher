# Loading Scene 设计方案

## 概述
创建独立的LoadingScene用于场景切换时的加载动画，支持背景模糊和视频加载动画。

## 文件结构
```
scenes/loading/
├── loading_scene.tscn
└── loading_scene.gd
```

## LoadingScene节点结构
```
LoadingScene (Control)
├── CanvasLayer (layer=5)
│   ├── BackgroundBlur (ColorRect + transition_blur.gdshader)
│   └── SmallLodingPlayer (VideoStreamPlayer instance)
└── Timer (用于模拟加载延迟，实际使用时可移除)
```

## SceneManager增强
新增方法：
- `switch_scene_with_loading(scene_path: String)` - 切换到加载场景并异步加载目标场景
- `_load_and_switch(target_scene_path: String)` - 内部异步加载方法

## 启动流程
SplashScreen → LoadingScene → MainMenu

## 实现步骤
1. 创建scenes/loading目录
2. 创建loading_scene.tscn场景文件
3. 创建loading_scene.gd脚本
4. 增强SceneManager.gd
5. 更新启动流程