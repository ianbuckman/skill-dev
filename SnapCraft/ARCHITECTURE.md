# SnapCraft — 技术架构

## 技术栈

| 组件 | 技术 |
|------|------|
| 语言 | Swift 5.10+ |
| UI 框架 | SwiftUI + AppKit 桥接（标注画布、屏幕选区） |
| 平台 | macOS 14+ (Sonoma) |
| 构建 | Swift Package Manager |
| 截图 | ScreenCaptureKit + CoreGraphics |
| 录屏 | ScreenCaptureKit + AVAssetWriter |
| 标注画布 | NSView 子类（CoreGraphics 绘制） |
| GIF 生成 | ImageIO (CGImageDestination) |
| OCR | Vision framework (VNRecognizeTextRequest) |
| 摄像头 | AVCaptureSession + AVCaptureVideoDataOutput |
| 系统音频 | ScreenCaptureKit audio stream |
| 全局快捷键 | NSEvent.addGlobalMonitorForEvents + Carbon RegisterEventHotKey |
| 数据存储 | UserDefaults (@AppStorage) + JSON 文件 |
| 并发 | Swift Concurrency (async/await, @MainActor) |

## 项目结构

```
SnapCraft/
├── Package.swift
├── Sources/SnapCraft/
│   ├── SnapCraftApp.swift              # @main 入口
│   ├── AppState.swift                  # @Observable 全局状态
│   ├── Models/
│   │   ├── CaptureMode.swift           # 捕获模式枚举
│   │   ├── AnnotationItem.swift        # 标注元素模型
│   │   ├── RecordingConfig.swift       # 录制配置模型
│   │   ├── CaptureHistoryItem.swift    # 历史记录模型
│   │   └── AppPreset.swift             # 预设模型
│   ├── Services/
│   │   ├── ScreenCaptureService.swift  # 截图核心（区域/窗口/全屏）
│   │   ├── ScrollCaptureService.swift  # 滚动截图
│   │   ├── ScreenRecordingService.swift # 录屏核心
│   │   ├── GifEncoderService.swift     # GIF 编码
│   │   ├── AudioCaptureService.swift   # 音频捕获
│   │   ├── CameraCaptureService.swift  # 摄像头捕获
│   │   ├── OCRService.swift            # 文字识别
│   │   ├── HotkeyService.swift         # 全局快捷键
│   │   ├── HistoryService.swift        # 捕获历史管理
│   │   ├── FileNamingService.swift     # 文件命名规则
│   │   ├── DesktopIconService.swift    # 桌面图标隐藏
│   │   └── PresetService.swift         # 预设管理
│   ├── Views/
│   │   ├── MenuBar/
│   │   │   └── MenuBarView.swift       # Menu Bar 弹出菜单
│   │   ├── Capture/
│   │   │   ├── AreaSelectionOverlay.swift    # 区域选择覆盖层
│   │   │   ├── WindowPickerOverlay.swift     # 窗口选择覆盖层
│   │   │   ├── AllInOneOverlay.swift         # All-In-One 模式 UI
│   │   │   ├── FreezeOverlay.swift           # 冻结屏幕覆盖层
│   │   │   └── TimerCountdownView.swift      # 延时倒计时 UI
│   │   ├── Annotation/
│   │   │   ├── AnnotationWindow.swift        # 标注窗口容器
│   │   │   ├── AnnotationCanvas.swift        # NSView 绘制画布
│   │   │   ├── AnnotationToolbar.swift       # 工具栏
│   │   │   └── ToolOptions/
│   │   │       ├── ShapeOptionsView.swift    # 形状选项
│   │   │       ├── ArrowOptionsView.swift    # 箭头选项
│   │   │       ├── TextOptionsView.swift     # 文字选项
│   │   │       ├── BlurOptionsView.swift     # 模糊/马赛克选项
│   │   │       └── ColorPickerView.swift     # 颜色/粗细选择器
│   │   ├── Recording/
│   │   │   ├── RecordingControlBar.swift     # 录制控制条
│   │   │   ├── VideoEditorView.swift         # 视频编辑器
│   │   │   └── CameraPreviewView.swift       # 摄像头预览
│   │   ├── Overlay/
│   │   │   ├── QuickAccessOverlay.swift      # Quick Access 浮窗
│   │   │   └── PinWindow.swift               # Pin 钉图窗口
│   │   ├── Background/
│   │   │   └── BackgroundToolView.swift      # 背景美化工具
│   │   ├── History/
│   │   │   └── HistoryView.swift             # 捕获历史列表
│   │   └── Settings/
│   │       ├── SettingsView.swift            # 设置主界面
│   │       ├── GeneralSettingsView.swift     # 通用设置
│   │       ├── CaptureSettingsView.swift     # 截图设置
│   │       ├── RecordingSettingsView.swift   # 录制设置
│   │       ├── ShortcutsSettingsView.swift   # 快捷键设置
│   │       ├── AppearanceSettingsView.swift  # 外观设置
│   │       └── PresetsSettingsView.swift     # 预设管理
│   └── Resources/
│       ├── Info.plist
│       └── Assets.xcassets/
│           └── AppIcon.appiconset/
├── Tests/SnapCraftTests/
│   └── SnapCraftTests.swift
├── CLAUDE.md
├── ARCHITECTURE.md
├── _task_state.md
└── README.md
```

## 核心模块设计

### Module 1: AppState（全局状态）
`@Observable` 类，管理：当前捕获模式、录制状态、设置偏好、最近捕获引用。所有 Service 和 View 通过 Environment 共享。

### Module 2: ScreenCaptureService（截图核心）
使用 ScreenCaptureKit `SCScreenshotManager` 进行区域/窗口/全屏截图。窗口截图通过 `SCShareableContent.excludingDesktopWindows` 获取窗口列表。截图结果为 `CGImage`，可选添加窗口阴影（CoreGraphics 绘制投影）和背景（纯色/图片/透明）。

### Module 3: ScrollCaptureService（滚动截图）
通过模拟滚动事件 (`CGEvent`) + 定时截图 + 图像拼接实现。使用 CoreGraphics 像素比较检测滚动边界。将多张截图垂直拼接为一张长图。

### Module 4: ScreenRecordingService（录屏核心）
使用 ScreenCaptureKit `SCStream` 获取视频帧，`AVAssetWriter` 写入 H.264 MP4。支持窗口级/全屏/自定义区域录制。管理录制生命周期（开始/暂停/停止）。

### Module 5: GifEncoderService（GIF 编码）
使用 `CGImageDestination` (ImageIO) 将视频帧序列编码为 GIF。支持帧率控制（10/15/20 FPS）和优化压缩。

### Module 6: AudioCaptureService（音频捕获）
ScreenCaptureKit 的 audio stream 捕获系统音频。`AVCaptureDevice` 捕获麦克风音频。两路音频混合后通过 `AVAssetWriterInput` 写入 MP4。支持单声道/立体声转换。

### Module 7: CameraCaptureService（摄像头）
`AVCaptureSession` + `AVCaptureVideoDataOutput` 捕获摄像头画面。画中画模式下通过 `CIFilter` 合成到录屏帧上。支持圆形/矩形/圆角矩形形状裁剪。

### Module 8: AnnotationCanvas（标注画布）
NSView 子类，使用 CoreGraphics 自定义绘制。维护 `[AnnotationItem]` 数组，每个元素有类型（形状/箭头/文字/模糊/马赛克/聚光灯/计数器）、位置、颜色、粗细等属性。支持选择/移动/调整大小。模糊/马赛克通过 `CIFilter` 实现（GaussianBlur / Pixellate）。撤销/重做通过 `UndoManager` 实现。

### Module 9: AnnotationWindow（标注窗口）
NSPanel 容器，包含 AnnotationCanvas + AnnotationToolbar。工具栏提供所有工具切换、颜色/粗细选择。支持拖放其他图片进行合成。支持保存为 JSON 项目文件（非破坏性编辑）。

### Module 10: QuickAccessOverlay（快速操作浮窗）
NSPanel 浮窗，截图/录屏后显示在屏幕角落。显示缩略图 + 操作按钮（复制/保存/标注/Pin）。支持拖放到其他应用。可配置自动关闭时间。支持多显示器定位。

### Module 11: PinWindow（钉图窗口）
NSPanel，`level = .floating`，始终置顶。可调大小和透明度（`alphaValue`）。方向键移动（通过 `keyDown` 事件）。锁定模式：`ignoresMouseEvents = true`。

### Module 12: BackgroundToolView（背景美化）
SwiftUI View，在截图上添加渐变/纯色/图片背景。10 种预设渐变背景。支持 padding 调整、对齐选项、纵横比控制。Auto Balance：分析截图内容边界，自动调整 padding 使内容居中。

### Module 13: OCRService（文字识别）
Vision framework 的 `VNRecognizeTextRequest`，完全本地处理。用户选择区域后截取图像，识别文字并复制到剪贴板。

### Module 14: HotkeyService（全局快捷键）
使用 Carbon API `RegisterEventHotKey` 注册全局快捷键。默认快捷键映射（用户可自定义）：
- ⌘⇧3: 全屏截图
- ⌘⇧4: 区域截图
- ⌘⇧5: 窗口截图
- ⌘⇧6: 滚动截图
- ⌘⇧7: 屏幕录制
- ⌘⇧8: GIF 录制
- ⌘⇧9: OCR 文字识别
- ⌘⇧0: All-In-One 模式

### Module 15: HistoryService（捕获历史）
JSON 文件存储历史记录（路径、类型、时间、缩略图路径）。最长保留 1 个月，自动清理过期记录。按类型筛选（截图/录制/GIF）。数据存储在 `~/Library/Application Support/SnapCraft/history.json`。

### Module 16: DesktopIconService（桌面图标管理）
通过 `defaults write com.apple.finder CreateDesktop -bool false && killall Finder` 隐藏桌面图标。恢复时写回 `true`。录制开始时自动隐藏，结束后恢复。

### Module 17: AreaSelectionOverlay（区域选择覆盖层）
全屏透明 NSWindow，绘制十字准线和放大镜。鼠标拖拽选区，实时显示选区尺寸。放大镜在鼠标附近显示 2x-4x 缩放的局部像素视图。支持 Escape 取消。

### Module 18: VideoEditorView（视频编辑器）
SwiftUI View，使用 AVPlayer 播放视频。时间轴拖拽裁剪（trim）。画质/分辨率调整通过 AVAssetExportSession 导出。音量控制和静音。

### Module 19: SettingsView（设置面板）
SwiftUI Settings scene，多 Tab 布局：通用、截图、录制、快捷键、外观、预设。所有设置通过 @AppStorage 持久化。

### Module 20: MenuBarView（菜单栏）
MenuBarExtra scene，显示截图/录屏快捷操作列表、最近捕获、设置入口、退出按钮。

### Module 21: FileNamingService（文件命名）
支持自定义命名模式（日期、时间、序号、自定义前缀）。默认：`SnapCraft_YYYY-MM-DD_HH-mm-ss.png`。默认保存目录可自定义。

### Module 22: PresetService（预设管理）
JSON 文件存储预设配置（捕获模式 + 设置组合）。支持创建/编辑/删除预设。快捷键可绑定到预设。

## 数据存储

| 数据 | 存储方式 | 位置 |
|------|---------|------|
| 用户设置 | @AppStorage (UserDefaults) | 系统默认 |
| 捕获历史 | JSON 文件 | ~/Library/Application Support/SnapCraft/history.json |
| 预设配置 | JSON 文件 | ~/Library/Application Support/SnapCraft/presets.json |
| 标注项目 | JSON 文件 | 用户选择的保存位置 |
| 截图/录屏文件 | PNG/JPG/MP4/GIF | 用户配置的保存目录（默认 ~/Desktop） |
| 历史缩略图 | PNG 文件 | ~/Library/Application Support/SnapCraft/thumbnails/ |

## 依赖

**零外部依赖** — 全部使用 Apple 原生框架：
- ScreenCaptureKit (截图 + 录屏)
- AVFoundation (音视频处理)
- CoreGraphics (绘制)
- ImageIO (GIF 编码)
- Vision (OCR)
- Carbon (全局快捷键)
- UniformTypeIdentifiers (文件类型)

## 权限需求

- **屏幕录制权限**: ScreenCaptureKit 需要用户授权
- **辅助功能权限**: 全局快捷键注册需要
- **麦克风权限**: 音频录制需要
- **摄像头权限**: 摄像头画中画需要
