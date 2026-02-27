# 开屏场景 (SplashScreen) 设计

## 概述
游戏启动器开屏动画，展示两张Logo后进入主流程。

## 资源
- Logo 1: `res://assets/image/boot_logo/logo_01.png`
- Logo 2: `res://assets/image/boot_logo/logo_02.png`

## 场景结构
```
SplashScreen (Control)
├── Background (ColorRect - 深色背景 #000000)
└── LogoTexture (TextureRect - 居中显示)
```

## 动画逻辑
1. 显示 logo_01，1.5秒
2. 硬切到 logo_02，再显示1.5秒
3. 后台已触发 VersionUtils 检查启动器更新
4. 动画完成后根据更新检查结果切换场景

## 场景切换逻辑
- 需要更新 → LauncherUpdateCheck 场景
- 无需更新 → MainMenu 场景

## 后续任务
创建 splash_screen.gd 脚本和场景文件
