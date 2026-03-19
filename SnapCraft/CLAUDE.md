# SnapCraft — CLAUDE.md

## 项目概述
macOS 截图录屏工具，媲美 CleanShot X，无云服务，所有数据本地存储。

## 技术约束

### Swift & SwiftUI
- 目标平台: macOS 14+ (Sonoma)
- 使用 Swift 5.10+，启用 StrictConcurrency
- **SwiftUI first** — 仅在 SwiftUI 无法实现时使用 AppKit
- 使用 `@Observable` 宏，**不要**使用 `ObservableObject` / `@Published`
- 使用 `@Environment` 传递共享状态，**不要**使用 singletons
- 使用 SF Symbols 做图标（`systemImage:` 参数）
- 遵循 Apple Human Interface Guidelines

### 代码风格
- View body 不超过 20 行，超过就拆分子 View
- 使用 `foregroundStyle()` 而非 `foregroundColor()`
- 使用 `.task {}` 而非 `.onAppear` 中调 async
- 错误使用 Swift 原生 Error + do/catch，不要用 Result 包装
- 文件命名: PascalCase，与主类型同名

### 构建
- 编译: `cd SnapCraft && swift build`
- Release: `cd SnapCraft && swift build -c release`
- 产物位置: `.build/release/SnapCraft`

### 数据存储
- 用户偏好: `@AppStorage` / `UserDefaults`
- 截图文件: 默认 `~/Desktop/SnapCraft/`
- 临时文件: `FileManager.temporaryDirectory`

### 常见陷阱
- ⚠️ 不要在 View.body 中做耗时操作
- ⚠️ 不要忘记 `@MainActor` 标注 UI 相关代码
- ⚠️ SwiftUI 编译器报 "unable to type-check" → 拆分 View
- ⚠️ 不要用 `AnyView` 做类型擦除，用 `@ViewBuilder` 或 `some View`
- ⚠️ ScreenCaptureKit API 需要 async/await，注意线程安全
