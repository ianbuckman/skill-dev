# SnapCraft — CLAUDE.md

## 项目概述
对标 CleanShot X 的全功能 macOS 截图录屏工具，纯本地运行，无云依赖。

## 技术约束

### 平台与构建
- 目标平台: macOS 14+ (Sonoma)
- 使用 Swift 5.10+，启用 StrictConcurrency
- 编译: `swift build` / Release: `swift build -c release` / 测试: `swift test`
- 产物位置: `.build/release/SnapCraft`

### SwiftUI 规则
- 使用 `@Observable` 而非 `ObservableObject` + `@Published`
- 使用 `@State` 配合 `@Observable`，不用 `@StateObject`
- 使用 `.foregroundStyle()` 而非 `.foregroundColor()`
- 使用 `NavigationStack` 而非 `NavigationView`
- 使用 `.task { }` 而非 `.onAppear { Task { } }`
- View body 不超过 20 行，超过则拆分子 View
- SwiftUI first, AppKit only when SwiftUI cannot do it

### 并发规则
- 使用 `@MainActor` 标注所有 UI 相关代码
- 使用 async/await，避免 DispatchQueue
- Service 类使用 actor 或 @MainActor

### 数据存储
- 用户偏好: `@AppStorage` / `UserDefaults`
- 历史/预设: JSON 文件存 `~/Library/Application Support/SnapCraft/`
- 截图/录屏: 用户配置的保存目录

### macOS 陷阱
- 不要用 `static let shared = AppDelegate()`，用 `NSApp.delegate as? AppDelegate`
- @Observable 对象必须通过 `.environment()` 从父 View 注入
- Timer/Monitor 必须持有为属性引用，不能是局部变量
- NSPanel 在 `applicationDidFinishLaunching` 中创建，不在 Scene body 中
- 全局快捷键需要辅助功能权限，在 README 中说明
