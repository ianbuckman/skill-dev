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

Verifier sub-agent 审查时逐项检查。共 15 项，按领域分组。

### A. App 生命周期（3 项）

1. **AppDelegate 双实例** — `@NSApplicationDelegateAdaptor` 时不要 `static let shared = AppDelegate()`，用 `NSApp.delegate as? AppDelegate`。否则有两个 AppDelegate 实例，事件只发到 SwiftUI 创建的那个。

2. **@Observable 环境断裂** — View 用 `@Environment(X.self)` 但父级缺 `.environment(x)`。编译通过但运行时 crash（fatalError: no Observable found）。**必须检查每个 @Environment 使用处的注入链是否完整。**

3. **LSUIElement 与窗口焦点** — `LSUIElement = true` 的 app 默认不在 Dock 显示，但也导致 NSPanel/NSWindow 可能**无法获取焦点**。需要设置 `NSApp.setActivationPolicy(.accessory)` 并在需要时临时切换为 `.regular`。

### B. 窗口与 UI（4 项）

4. **NSPanel 创建时机** — 应在 `applicationDidFinishLaunching` 或 `.task {}` 中创建，不要在 Scene body 或 View init 中创建。Scene body 会被 SwiftUI 多次求值，导致创建多个 panel。

5. **NSPanel level 与交互** — `NSPanel` 的 `level`、`collectionBehavior`、`styleMask` 组合决定窗口是否可见、可交互、置顶。常见错误组合：
   - `level = .floating` 但没设 `styleMask` 含 `.nonactivatingPanel` → 窗口激活时抢焦点
   - `collectionBehavior` 缺 `.canJoinAllSpaces` → 切换 Space 后窗口消失
   - `isMovableByWindowBackground = true` 但忘设 `acceptsMouseMovedEvents = true` → 鼠标事件不传递

6. **全屏 overlay 窗口的鼠标事件** — 用 NSWindow 做全屏透明 overlay 时：
   - 必须设 `ignoresMouseEvents = false` 才能接收点击
   - 必须设 `acceptsMouseMovedEvents = true` 才能接收移动事件
   - `isOpaque = false` + `backgroundColor = .clear` 才能透明
   - `level` 必须高于被覆盖的窗口

7. **SwiftUI Sheet/Popover 在 Menu Bar App 中的行为** — MenuBarExtra 的 popover 中使用 `.sheet()` 或 `.popover()` 可能不显示或显示在错误位置。解决方案：用独立的 NSWindow/NSPanel 代替 sheet。

### C. 系统 API（4 项）

8. **全局快捷键权限** — `NSEvent.addGlobalMonitorForEvents` 和 Carbon `RegisterEventHotKey` 都需要辅助功能授权。未授权时不报错，只是静默不触发。**README 中必须提醒用户授权。** Carbon API 还需要注意：`InstallEventHandler` 的 target 必须是 `GetApplicationEventTarget()`，不是 `GetEventMonitorTarget()`。

9. **ScreenCaptureKit 权限与 stream 生命周期** — `SCShareableContent.excludingDesktopWindows` 首次调用时弹出权限请求。用户授权后**必须重新创建 SCStream**（不是重用旧的）。SCStream 的 output delegate 必须被强引用持有，否则被 ARC 回收后回调不触发。

10. **AVAssetWriter 时序严格** — 调用顺序必须是：`startWriting()` → `startSession(atSourceTime:)` → `append(sampleBuffer)` → `finishWriting()`。任何顺序错误都会**静默失败**（不抛异常，但输出文件为空或损坏）。`canWrite` 属性必须在 append 前检查。音频和视频的 `sourceTime` 必须对齐。

11. **CGEvent 权限** — 用 `CGEvent` 模拟鼠标/键盘事件（如滚动截图中的滚动模拟）需要辅助功能权限。未授权时 `CGEvent.post()` 静默失败。

### D. 数据与持久化（2 项）

12. **Timer/Monitor 引用丢失** — `Timer.scheduledTimer()` 和 `NSEvent.addGlobalMonitorForEvents` 返回值必须被属性强引用持有。如果是局部变量，ARC 会立即回收，定时器/监视器立即失效。

13. **UserDefaults 与 @AppStorage 同步** — 在 Service 中用 `UserDefaults.standard` 修改值，在 View 中用 `@AppStorage` 读取同一个 key 时，视图可能不会自动更新。需要通过 `NotificationCenter.default.post(name: UserDefaults.didChangeNotification)` 或直接操作 `@AppStorage` 的绑定来触发更新。

### E. 并发与性能（2 项）

14. **@MainActor 隔离与回调** — 系统框架的 delegate 回调（如 `AVCaptureVideoDataOutputSampleBufferDelegate`、`SCStreamOutput`）**不在 MainActor 上**。在这些回调中直接修改 @MainActor 标注的属性会产生数据竞争。必须用 `Task { @MainActor in ... }` 或 `DispatchQueue.main.async` 转到主线程。

15. **NSImage/CGImage 线程安全** — `NSImage` 不是线程安全的。在后台线程创建的 `NSImage` 不能直接传给主线程的 UI。应在后台线程使用 `CGImage`，只在主线程转换为 `NSImage`。

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
