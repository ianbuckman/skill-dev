# DeskPet — CLAUDE.md

## 项目概述
桌面浮动宠物，陪你工作、帮你专注。像素风小猫在桌面自由走动，内置番茄钟。

## 技术约束

### 平台与构建
- 目标平台: macOS 14+ (Sonoma)
- 使用 Swift 5.10+，启用 StrictConcurrency
- 编译: `swift build` / Release: `swift build -c release` / 测试: `swift test`
- 产物位置: `.build/release/DeskPet`

### 架构
- 浮动透明窗口: NSPanel (borderless, nonactivatingPanel, transparent)
- 菜单栏: MenuBarExtra + .menuBarExtraStyle(.window)
- 状态管理: @Observable PetState 单一数据源
- LSUIElement = true (无 Dock 图标)

### 编码质量
- SwiftUI 规则由 /swiftui-pro 提供，并发规则由 /swift-concurrency-pro 提供
- macOS 特有规则参见 mac-app-forge 的 references/macos-patterns.md
- Timer/Monitor 返回值必须被属性强引用持有（避免 ARC 回收）
- NSPanel 在 applicationDidFinishLaunching 或 .task {} 中创建，不在 Scene body 中
- @Environment 使用处必须检查注入链完整

### 数据存储
- 用户偏好: @AppStorage / UserDefaults
- 无需持久化复杂数据
