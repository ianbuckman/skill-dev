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
- [ ] Phase 3: 脚手架生成
- [ ] Phase 4: 编码实现
- [ ] Phase 5: 构建与自动验证 → phase5_build_report.md
- [ ] Phase 6: 打包发布 → dist/SnapCraft.dmg + README.md
- [ ] Phase 7: 交付与用户验证

## 当前阶段
Phase 3

## Phase 4 模块清单
- [ ] M1: AppState — 全局状态 (@Observable)
- [ ] M2: Models — CaptureMode, AnnotationItem, RecordingConfig, CaptureHistoryItem, AppPreset
- [ ] M3: HotkeyService — 全局快捷键 (Carbon API)
- [ ] M4: ScreenCaptureService — 截图核心 (区域/窗口/全屏)
- [ ] M5: AreaSelectionOverlay — 区域选择 UI (十字准线 + 放大镜)
- [ ] M6: WindowPickerOverlay — 窗口选择 UI
- [ ] M7: ScrollCaptureService — 滚动截图
- [ ] M8: ScreenRecordingService — 录屏核心 (MP4)
- [ ] M9: GifEncoderService — GIF 编码
- [ ] M10: AudioCaptureService — 音频捕获 (系统 + 麦克风)
- [ ] M11: CameraCaptureService — 摄像头画中画
- [ ] M12: AnnotationCanvas — 标注画布 (NSView + CoreGraphics)
- [ ] M13: AnnotationWindow + Toolbar — 标注窗口容器
- [ ] M14: QuickAccessOverlay — 快速操作浮窗
- [ ] M15: PinWindow — 钉图窗口
- [ ] M16: BackgroundToolView — 背景美化工具
- [ ] M17: OCRService — 文字识别
- [ ] M18: VideoEditorView — 视频编辑器
- [ ] M19: HistoryService + HistoryView — 捕获历史
- [ ] M20: FileNamingService — 文件命名规则
- [ ] M21: DesktopIconService — 桌面图标管理
- [ ] M22: PresetService — 预设管理
- [ ] M23: SettingsView — 设置面板 (多 Tab)
- [ ] M24: MenuBarView — 菜单栏 UI
- [ ] M25: FreezeOverlay + TimerCountdown — 冻结屏幕 + 延时 UI
- [ ] M26: AllInOneOverlay — All-In-One 模式 UI

## 验证记录（Phase 7 使用）
[待填写]
