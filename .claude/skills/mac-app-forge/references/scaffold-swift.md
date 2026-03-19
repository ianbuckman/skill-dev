# Swift/SwiftUI 脚手架模板

## 项目结构

### Menu Bar App

```
[AppName]/
├── Package.swift
├── Sources/
│   └── [AppName]/
│       ├── [AppName]App.swift          # @main 入口
│       ├── MenuBarManager.swift         # Menu bar 控制
│       ├── Views/
│       │   ├── ContentView.swift        # 主 popover 视图
│       │   ├── SettingsView.swift       # 设置窗口
│       │   └── Components/             # 可复用组件
│       ├── Models/
│       │   └── AppState.swift           # @Observable 状态
│       ├── Services/
│       │   └── [功能]Service.swift      # 业务逻辑
│       └── Resources/
│           ├── Assets.xcassets/         # 图标和资源
│           └── Info.plist
├── Tests/
│   └── [AppName]Tests/
├── CLAUDE.md
├── ARCHITECTURE.md
└── README.md
```

### 标准窗口 App

```
[AppName]/
├── Package.swift
├── Sources/
│   └── [AppName]/
│       ├── [AppName]App.swift
│       ├── Views/
│       │   ├── MainView.swift
│       │   ├── SidebarView.swift
│       │   ├── DetailView.swift
│       │   ├── SettingsView.swift
│       │   └── Components/
│       ├── Models/
│       ├── Services/
│       └── Resources/
├── Tests/
├── CLAUDE.md
├── ARCHITECTURE.md
└── README.md
```

## Package.swift 模板

```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "[AppName]",
    platforms: [
        .macOS(.v14) // Sonoma — 支持 @Observable
    ],
    targets: [
        .executableTarget(
            name: "[AppName]",
            path: "Sources/[AppName]",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "[AppName]Tests",
            dependencies: ["[AppName]"],
            path: "Tests/[AppName]Tests"
        )
    ]
)
```

## App 入口模板

### Menu Bar App
```swift
import SwiftUI

@main
struct [AppName]App: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("[AppName]", systemImage: "[sf.symbol.name]") {
            ContentView()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
```

### 标准窗口 App
```swift
import SwiftUI

@main
struct [AppName]App: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .defaultSize(width: 800, height: 600)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
```

## AppState 模板
```swift
import SwiftUI

@Observable
final class AppState {
    var isLoading = false
    // 添加 app 级别的状态
}
```

## 项目级 CLAUDE.md 模板

```markdown
# [AppName] — CLAUDE.md

## 项目概述
[一句话描述]

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
- 编译: `swift build`
- Release: `swift build -c release`
- 测试: `swift test`
- 产物位置: `.build/release/[AppName]`

### 数据存储
- 用户偏好: `@AppStorage` / `UserDefaults`
- 结构化数据: SwiftData 或 JSON 文件存 `~/Library/Application Support/[AppName]/`
- 不要用 CoreData

### 常见陷阱
- ⚠️ 不要在 View.body 中做耗时操作
- ⚠️ 不要忘记 `@MainActor` 标注 UI 相关代码
- ⚠️ SwiftUI 编译器报 "unable to type-check" → 拆分 View
- ⚠️ 不要用 `AnyView` 做类型擦除，用 `@ViewBuilder` 或 `some View`
```

## Info.plist 模板

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>[AppName]</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.[appname]</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>[AppName]</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>  <!-- Menu bar app: true; 标准 app: 删除此行 -->
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. All rights reserved.</string>
</dict>
</plist>
```
