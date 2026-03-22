# ClipVault — CLAUDE.md

## 项目概述
简洁优美的 macOS Menu Bar 剪贴板管理工具，自动记录复制历史并支持快速检索。

## 技术约束

### 平台与构建
- 目标平台: macOS 14+ (Sonoma)
- 使用 Swift 5.10+，启用 StrictConcurrency
- 编译: `swift build` / Release: `swift build -c release` / 测试: `swift test`
- 产物位置: `.build/release/ClipVault`

### 编码质量
- 使用 @Observable 而非 ObservableObject
- 使用 @Environment 而非 @EnvironmentObject
- 使用 .task {} 而非 .onAppear { Task {} }
- 使用 .foregroundStyle() 而非 .foregroundColor()
- macOS 特有规则参见 mac-app-forge 的 references/macos-patterns.md

### 数据存储
- 用户偏好: @AppStorage / UserDefaults
- 历史记录: JSON 文件存 ~/Library/Application Support/ClipVault/
- 不要用 CoreData 或 SwiftData
