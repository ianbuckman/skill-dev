# macOS 应用模式与规则

mac-app-forge 专属的 macOS 平台知识。SwiftUI/Swift 通用编码规则由专业 skills 覆盖（swiftui-pro、swift-concurrency-pro 等），本文件只保留 macOS 特有内容。

## macOS 特有规则

### Menu Bar App
1. 用 `MenuBarExtra` scene（macOS 13+）
2. `.menuBarExtraStyle(.window)` 显示 popover
3. `LSUIElement = true` 在 Info.plist 中隐藏 Dock 图标
4. 用 `NSStatusBar` 仅在 `MenuBarExtra` 不够用时

### 窗口管理
1. 用 `WindowGroup` 做多窗口
2. 用 `.defaultSize(width:height:)` 设置默认大小
3. 用 `Settings { }` scene 做偏好设置窗口
4. 用 `@Environment(\.openWindow)` 打开新窗口

### 键盘快捷键
1. 用 `.keyboardShortcut()` 修饰符
2. Menu bar item 用 `Button` + `.keyboardShortcut`
3. 全局快捷键需要 AppKit 桥接（`NSEvent.addGlobalMonitorForEvents`）

### 系统集成
1. 通知用 `UNUserNotificationCenter`
2. 分享用 `NSSharingServicePicker`
3. 文件对话框用 `fileImporter()` / `fileExporter()` 修饰符
4. 拖放用 `.draggable()` / `.dropDestination()`

---

## macOS 运行时陷阱（编译器不报错但导致功能失效）

Phase 5 代码审查时逐项检查：

1. **AppDelegate 双实例** — `@NSApplicationDelegateAdaptor` 时不要 `static let shared = AppDelegate()`，用 `NSApp.delegate as? AppDelegate`
2. **@Observable 环境断裂** — View 用 `@Environment(X.self)` 但父级缺 `.environment(x)`
3. **Timer/Monitor 引用丢失** — 必须被属性强引用持有
4. **NSPanel 创建时机** — 应在 `applicationDidFinishLaunching` 中创建，不要在 Scene body 中
5. **全局快捷键权限** — `addGlobalMonitorForEvents` 需辅助功能授权，README 中提醒

---

## Fallback 段（仅当专业 skill 未安装时使用）

> 以下规则在 /swiftui-pro、/swift-concurrency-pro 等专业 skill 已安装时**跳过**，由专业 skill 提供更全面的覆盖。

### API 现代化映射（Top 10）

| ❌ 过时 | ✅ 现代替代 |
|---------|-----------|
| `ObservableObject` + `@Published` | `@Observable` 宏 |
| `@StateObject` | `@State` (配合 @Observable) |
| `@ObservedObject` | 直接传参或 `@Environment` |
| `@EnvironmentObject` | `@Environment` |
| `.foregroundColor()` | `.foregroundStyle()` |
| `.background(Color.x)` | `.background(.x)` 或 `.background { }` |
| `NavigationView` | `NavigationStack` 或 `NavigationSplitView` |
| `.onAppear { Task { } }` | `.task { }` |
| `.onChange(of:) { newValue in }` | `.onChange(of:) { oldValue, newValue in }` |
| `AnyView(...)` | `@ViewBuilder` 或 `some View` |

### 并发核心规则（3 条）

1. UI 更新必须在 `@MainActor` 上下文
2. 用 `async/await` 而非 completion handler；用 `Task { }` 而非 `DispatchQueue`
3. 用 `actor` 保护共享可变状态，标记 `Sendable` 确保线程安全
