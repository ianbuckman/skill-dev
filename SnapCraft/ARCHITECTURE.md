# SnapCraft — Architecture

## 技术栈
- **Swift 5.10 + SwiftUI** — 原生 macOS 体验，系统 API 直接调用
- **ScreenCaptureKit** — 现代屏幕捕获 API（macOS 12.3+）
- **AVFoundation** — 屏幕录制、摄像头捕获、音频录制
- **ImageIO** — GIF 生成
- **Vision** — (预留) 文字识别
- **CoreGraphics** — 窗口列表、屏幕截图 fallback
- **Carbon** — 全局快捷键注册（RegisterEventHotKey）

## 项目结构

```
SnapCraft/
├── Package.swift
├── Sources/
│   └── SnapCraft/
│       ├── SnapCraftApp.swift              # @main 入口
│       ├── AppState.swift                  # 全局状态 @Observable
│       │
│       ├── Services/
│       │   ├── CaptureService.swift        # 截图核心（区域/全屏/窗口）
│       │   ├── ScrollCaptureService.swift   # 滚动截图
│       │   ├── RecordingService.swift       # 屏幕录制
│       │   ├── GifService.swift            # GIF 生成
│       │   ├── CameraService.swift         # 摄像头捕获
│       │   ├── AudioService.swift          # 音频采集
│       │   ├── HotkeyManager.swift         # 全局快捷键
│       │   └── DesktopManager.swift        # 隐藏桌面图标
│       │
│       ├── Views/
│       │   ├── MenuBarView.swift           # 菜单栏下拉面板
│       │   ├── OverlayWindow.swift         # 截图选区覆盖层
│       │   ├── QuickPreviewPanel.swift     # 快速预览悬浮窗
│       │   ├── PinWindow.swift             # 钉图窗口
│       │   ├── CountdownOverlay.swift      # 定时截图倒计时
│       │   ├── RecordingControls.swift      # 录制控制条
│       │   ├── VideoTrimmerView.swift       # 视频修剪界面
│       │   ├── SettingsView.swift           # 设置窗口
│       │   │
│       │   └── Annotation/
│       │       ├── AnnotationEditorView.swift    # 标注编辑器主视图
│       │       ├── AnnotationCanvas.swift        # 绘制画布（NSView）
│       │       ├── AnnotationToolbar.swift       # 工具栏
│       │       └── AnnotationModels.swift        # 标注数据模型
│       │
│       ├── Models/
│       │   ├── CaptureMode.swift           # 截图模式枚举
│       │   ├── RecordingMode.swift         # 录制模式枚举
│       │   └── AnnotationTool.swift        # 标注工具枚举
│       │
│       └── Resources/
│           └── Info.plist
│
├── CLAUDE.md
├── ARCHITECTURE.md
└── README.md
```

## 核心模块设计

### 1. AppShell（入口 + 菜单栏）
- `SnapCraftApp` — @main 入口，配置 MenuBarExtra + Settings scene
- `AppState` — @Observable 全局状态：当前模式、设置偏好、临时截图数据
- `MenuBarView` — 菜单栏下拉面板，列出所有操作入口

### 2. CaptureService（截图核心）
- 使用 `ScreenCaptureKit` (SCScreenshotManager) 进行截图
- 三种模式：区域选择、全屏、窗口
- 区域选择通过全屏透明 `OverlayWindow` 实现拖拽选区
- 窗口截图通过 `CGWindowListCopyWindowInfo` 获取窗口列表，高亮选中
- 截图完成后触发 QuickPreview 或直接复制到剪贴板

### 3. OverlayWindow（选区覆盖层）
- 全屏无边框透明窗口（NSPanel, level: .screenSaver）
- 支持鼠标拖拽绘制矩形选区
- 实时显示选区尺寸
- 按 ESC 取消
- 用于区域截图和区域录制

### 4. ScrollCaptureService（滚动截图）
- 分步截图 + 图像拼接
- 通过发送滚动事件（CGEvent）自动滚动
- 使用 CoreGraphics 对比帧间重叠区域，智能拼接
- 检测滚动到底部自动停止

### 5. RecordingService（屏幕录制）
- 使用 `SCStream` (ScreenCaptureKit) 捕获屏幕帧
- `AVAssetWriter` 写入 MP4
- 支持全屏和区域录制
- GIF 模式：捕获帧后通过 `GifService` 使用 ImageIO 生成 GIF
- 摄像头叠加：使用 `AVCaptureSession` 同时采集摄像头，合成到画面
- 音频：`AVCaptureDevice` 采集麦克风 + 系统音频（需要权限）

### 6. AnnotationEditor（标注编辑器）
- 基于 `NSView` 的自定义画布（SwiftUI Canvas 无法处理交互式绘制）
- 工具：箭头、文字、矩形、圆形、线条、马赛克/模糊、高亮、画笔、裁剪、序号标注
- 每个标注是独立的 `AnnotationItem` 对象，支持选中、移动、删除
- 马赛克/模糊通过 `CIFilter` 实现局部区域处理
- 序号标注自动递增编号
- 撤销/重做支持

### 7. QuickPreviewPanel（快速预览）
- 截图后在屏幕右下角弹出小预览窗口
- 可拖拽到其他应用（拖拽导出图片）
- 点击打开标注编辑器
- 按钮：复制、保存、标注、钉图、关闭
- 5 秒后自动消失（可配置）

### 8. PinWindow（钉图）
- 始终置顶的无边框窗口
- 显示截图，可拖拽移动
- 可调整大小
- 右键菜单：关闭、复制、保存
- 支持透明度调节

### 9. HotkeyManager（全局快捷键）
- 使用 Carbon API `RegisterEventHotKey` 注册全局快捷键
- 默认快捷键：
  - ⌘⇧3: 全屏截图
  - ⌘⇧4: 区域截图
  - ⌘⇧5: 窗口截图
  - ⌘⇧6: 滚动截图
  - ⌘⇧7: 屏幕录制
  - ⌘⇧8: GIF 录制
- 设置界面支持自定义快捷键绑定

### 10. DesktopManager（桌面图标管理）
- 通过 `defaults write com.apple.finder CreateDesktop -bool false` 隐藏桌面图标
- 截图/录制前自动隐藏，完成后恢复
- 用户可在设置中开关此功能

### 11. TimerCapture（定时截图）
- 选择延迟后显示 `CountdownOverlay`（全屏半透明倒计时）
- 倒计时结束后执行普通截图流程
- 支持 3s、5s、10s

### 12. CameraService（摄像头/自拍叠加）
- `AVCaptureSession` 采集摄像头
- 截图时合成到截图左下角（圆形头像）
- 录制时作为画中画叠加

### 13. VideoTrimmerView（视频修剪）
- 录制完成后可选打开修剪界面
- 使用 `AVPlayer` 预览 + 时间轴选择入出点
- `AVAssetExportSession` 导出修剪后的视频

### 14. SettingsView（设置）
- 通用设置：保存路径、图片格式（PNG/JPG）、快速预览停留时长
- 快捷键设置：每个操作的快捷键绑定
- 录制设置：帧率、视频质量、GIF 质量
- 外观：跟随系统 / 深色 / 浅色
- 截图时隐藏桌面图标开关

## 数据存储
- 用户偏好：`@AppStorage` / `UserDefaults`
- 截图/录屏文件：默认保存到 `~/Desktop/SnapCraft/`，可在设置中更改
- 临时文件：`FileManager.temporaryDirectory`

## 权限需求
- 屏幕录制权限（ScreenCaptureKit 自动请求）
- 摄像头权限（AVCaptureDevice 请求）
- 麦克风权限（AVCaptureDevice 请求）
- 辅助功能权限（全局快捷键，可选）

## 第三方依赖
无。全部使用系统框架。
