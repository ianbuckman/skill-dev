# Task State — SnapCraft

## 目标（创建后不可修改）
- App 名称: SnapCraft
- 一句话描述: 对标 CleanShot X 的全功能 macOS 截图录屏工具，纯本地运行，无云依赖
- 核心功能:
  1. 多模式截图捕获（区域/窗口/全屏/滚动/延时/冻结/All-In-One）
  2. 全能屏幕录制（MP4/GIF/摄像头/音频/点击高亮/按键显示/视频编辑器）
  3. 专业标注编辑器（形状/箭头/文字/模糊/马赛克/聚光灯/计数器/裁剪/合成）
  4. Quick Access Overlay & Pin 钉图
  5. 背景美化工具 & OCR 文字识别
  6. 捕获历史 & 系统集成（预设/快捷键/自定义）
- App 类型: Menu Bar App
- 技术栈: Swift 5.10+ / SwiftUI / ScreenCaptureKit / AVFoundation / SPM
- 项目路径: /Users/nqt/conductor/workspaces/skill-dev/helsinki/SnapCraft

## 进度
- [x] Phase 1: 创意细化 → phase1_concept.md
- [x] Phase 2: 技术方案 → ARCHITECTURE.md
- [x] Phase 3: 脚手架生成
- [x] Phase 4: 编码实现 — 26 模块全部完成
- [x] Phase 5: 构建与自动验证 → phase5_build_report.md (1.3MB arm64, 烟雾测试通过)
- [x] Phase 6: 打包发布 → dist/SnapCraft.dmg (1.6MB) + README.md
- [ ] Phase 7: 交付与用户验证

## 当前阶段
Phase 7

## Phase 4 模块清单
- [x] M1: AppState
- [x] M2: Models (CaptureMode, AnnotationItem, RecordingConfig, CaptureHistoryItem, AppPreset)
- [x] M3: HotkeyService
- [x] M4: ScreenCaptureService
- [x] M5: AreaSelectionOverlay
- [x] M6: WindowPickerOverlay
- [x] M7: ScrollCaptureService
- [x] M8: ScreenRecordingService
- [x] M9: GifEncoderService
- [x] M10: AudioCaptureService
- [x] M11: CameraCaptureService
- [x] M12: AnnotationCanvas
- [x] M13: AnnotationWindow + Toolbar
- [x] M14: QuickAccessOverlay
- [x] M15: PinWindow
- [x] M16: BackgroundToolView
- [x] M17: OCRService
- [x] M18: VideoEditorView
- [x] M19: HistoryService + HistoryView
- [x] M20: FileNamingService
- [x] M21: DesktopIconService
- [x] M22: PresetService
- [x] M23: SettingsView (6 tabs)
- [x] M24: MenuBarView (wired to CaptureCoordinator)
- [x] M25: FreezeOverlay + TimerCountdown
- [x] M26: AllInOneOverlay
- [x] CaptureCoordinator (main orchestrator)

## 验证记录（Phase 7 使用）
[待用户反馈]
