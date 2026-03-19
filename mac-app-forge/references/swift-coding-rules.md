# Swift/SwiftUI 编码规则

综合 Paul Hudson (twostraws)、Peter Steinberger (steipete)、Indragie Karunaratne 等实战经验。

## API 现代化映射

Claude 经常使用过时 API。遇到左侧用法时，替换为右侧：

| ❌ 过时 | ✅ 现代替代 |
|---------|-----------|
| `ObservableObject` + `@Published` | `@Observable` 宏 |
| `@StateObject` | `@State` (配合 @Observable) |
| `@ObservedObject` | 直接传参或 `@Environment` |
| `@EnvironmentObject` | `@Environment` |
| `.foregroundColor()` | `.foregroundStyle()` |
| `.background(Color.x)` | `.background(.x)` 或 `.background { }` |
| `NavigationView` | `NavigationStack` 或 `NavigationSplitView` |
| `List { ForEach }` selection | `.navigationDestination(for:)` |
| `.onAppear { Task { } }` | `.task { }` |
| `.onChange(of:) { newValue in }` | `.onChange(of:) { oldValue, newValue in }` |
| `Text(x) + Text(y)` | `Text("\(x)\(y)")` 或 `HStack` |
| `AnyView(...)` | `@ViewBuilder` 或 `some View` |
| `GeometryReader` (布局用) | `.containerRelativeFrame()` 或 `Layout` protocol |
| `UIColor` / `NSColor` 直接使用 | `Color` 或 Asset Catalog |

## SwiftUI View 规则

### 结构
1. **每个 View body 不超过 20 行** — 超过就提取子 View
2. **子 View 用独立 struct**，不要用 computed property 返回 `some View`
3. **一个文件一个主 View**，相关子 View 可以放同一文件
4. 使用 `#Preview` 宏而非 `PreviewProvider`

### 状态管理
1. 局部 UI 状态 → `@State`
2. 跨 View 共享 → `@Observable` class + `@Environment`
3. 持久化设置 → `@AppStorage`
4. **不要在 View.init 中做任何副作用操作**
5. **不要在 View.body 中做计算密集或 async 操作**

### 布局
1. 优先使用 `VStack`, `HStack`, `ZStack` 组合
2. 用 `.frame(maxWidth: .infinity)` 而非 `GeometryReader` 做撑满
3. 用 `.padding()` 而非硬编码间距
4. 用 `.containerRelativeFrame()` 替代大部分 `GeometryReader` 场景

### 列表
1. `ForEach` 的数据必须是 `Identifiable` 或提供 `id:` 参数
2. 大列表用 `List` 而非 `ScrollView + LazyVStack`（List 自带优化）
3. 用 `.listStyle(.insetGrouped)` 或 `.listStyle(.sidebar)` 指定样式

## Swift 语言规则

### Concurrency
1. UI 更新必须在 `@MainActor` 上下文
2. 用 `async/await` 而非 completion handler
3. 用 `Task { }` 而非 `DispatchQueue.main.async`
4. 用 `actor` 保护共享可变状态
5. 标记 `Sendable` 的类型确保线程安全
6. **不要用 `Task.detached` 除非你确切知道为什么需要它**

### 错误处理
1. 用 `do/catch` + 自定义 `Error` 枚举
2. 不要 `try!` 或 `force unwrap`（除非是已知安全的情况，如 Bundle resource）
3. 向用户展示的错误用 `LocalizedError` protocol

### 文件 I/O
1. 用 `FileManager.default` 获取路径
2. App 数据存到 `applicationSupportDirectory`
3. 临时文件存到 `temporaryDirectory`
4. 用 `JSONEncoder/JSONDecoder` 做序列化

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

## 开源 Agent Skills 推荐

如果已安装以下 skills，本 skill 在编码阶段会自动受益：

- `npx skills add https://github.com/twostraws/swiftui-agent-skill --skill swiftui-pro`
- `npx skills add https://github.com/rshankras/claude-code-apple-skills --skill macos-development`
- Peter Steinberger 的 agent-rules: `https://github.com/steipete/agent-rules`

这些 skill 提供了更详细的 SwiftUI 最佳实践检查，与本 skill 互补。
