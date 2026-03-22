# DeskPet — Architecture

## 技术栈
- 语言: Swift 5.10+, StrictConcurrency 启用
- UI 框架: SwiftUI + AppKit 桥接（NSPanel 实现浮动透明窗口）
- 最低系统: macOS 14 (Sonoma) — 支持 @Observable
- 构建: Swift Package Manager (无 .xcodeproj)
- 数据存储: @AppStorage / UserDefaults（轻量偏好设置）

## 项目结构

```
DeskPet/
├── Package.swift
├── Sources/
│   └── DeskPet/
│       ├── DeskPetApp.swift              # @main 入口，MenuBarExtra + NSPanel 编排
│       ├── Models/
│       │   ├── PetState.swift            # @Observable 全局状态
│       │   └── SpriteData.swift          # 像素精灵帧数据定义
│       ├── Views/
│       │   ├── PetCanvasView.swift       # 精灵渲染 + 动画 SwiftUI 视图
│       │   ├── PomodoroPopoverView.swift # 番茄钟 MenuBar popover UI
│       │   └── Components/
│       │       └── PixelGridView.swift   # 像素网格渲染组件
│       ├── Services/
│       │   ├── PetAnimationEngine.swift  # 动画状态机 + 移动 AI
│       │   ├── InteractionManager.swift  # 点击/拖拽/双击处理
│       │   └── PomodoroService.swift     # 番茄钟计时器逻辑
│       ├── Window/
│       │   └── PetWindowController.swift # NSPanel 创建与管理
│       └── Resources/
│           └── Info.plist
├── Tests/
│   └── DeskPetTests/
├── CLAUDE.md
├── ARCHITECTURE.md
├── phase1_concept.md
└── _forge_log.md
```

## 核心模块设计（6 个模块）

### M1: PetState — 全局状态 (`Models/PetState.swift` + `Models/SpriteData.swift`)

`PetState` 是 @Observable 全局状态容器，持有所有运行时数据：

```swift
@Observable
final class PetState {
    // 宠物位置（屏幕坐标）
    var petPosition: CGPoint
    // 当前动画状态
    var animationState: AnimationState  // .idle, .walking, .sitting, .sleeping, .running, .reacting
    // 当前朝向
    var facingRight: Bool
    // 心情
    var mood: PetMood  // .happy, .normal, .sleepy
    // 番茄钟状态
    var pomodoroState: PomodoroState  // .idle, .working, .breaking
    var pomodoroTimeRemaining: TimeInterval
    var pomodoroSessionCount: Int
    // 宠物可见性
    var isPetVisible: Bool
    // 今日专注统计
    var todayFocusMinutes: Int
}
```

`SpriteData` 定义像素精灵的帧数据：
- 每个动画状态有 2-4 帧
- 每帧是 16x16 像素网格（Color 二维数组）
- 纯代码定义，无外部图片依赖

枚举:
```swift
enum AnimationState: String { case idle, walking, sitting, sleeping, running, reacting }
enum PetMood: String { case happy, normal, sleepy }
enum PomodoroState: String { case idle, working, breaking }
```

### M2: PetAnimationEngine — 动画引擎 (`Services/PetAnimationEngine.swift`)

负责宠物的自主行为和动画帧循环：

- **移动 AI**: 随机选择目标点 → 走向目标 → 到达后随机选择下一动作（坐下/闲逛/跑步）
- **帧循环**: Timer 驱动，每 200ms 切换动画帧
- **行为规则**:
  - 工作中 (pomodoroState == .working): 宠物安静，只有 idle/sitting/sleeping
  - 休息中 (pomodoroState == .breaking): 宠物活跃，running/walking/reacting
  - 空闲 (pomodoroState == .idle): 正常行为循环
- **心情影响**: happy → 更多 running/reacting; sleepy → 更多 sleeping/sitting
- **屏幕边界**: 限制在主屏幕可见范围内

关键 API:
```swift
@Observable
final class PetAnimationEngine {
    func start()    // 启动帧循环和移动 AI
    func stop()     // 停止
    func triggerReaction()  // 触发互动反应动画
}
```

持有 Timer 引用为属性（避免 ARC 回收 — 陷阱 #12）。

### M3: PetWindowController — 浮动窗口 (`Window/PetWindowController.swift`)

NSPanel 管理器，创建透明悬浮窗口：

- **窗口属性**:
  - `level = .floating` — 悬浮于普通窗口之上
  - `styleMask = [.borderless, .nonactivatingPanel]` — 无边框，不抢焦点
  - `isOpaque = false`, `backgroundColor = .clear` — 透明背景
  - `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]` — 跟随 Space 切换
  - `ignoresMouseEvents = false` — 接收鼠标事件
  - `hasShadow = false` — 无窗口阴影
- **创建时机**: `applicationDidFinishLaunching` 中创建（避免陷阱 #4）
- **内容**: 托管 `PetCanvasView` (SwiftUI) 通过 `NSHostingView`
- **窗口大小**: 固定 80x80 pt（对应 16x16 像素 × 5x 缩放）

关键 API:
```swift
final class PetWindowController {
    func setupWindow(with petState: PetState)
    func updatePosition(_ point: CGPoint)  // 跟随 PetState.petPosition
    func show() / func hide()
}
```

### M4: InteractionManager — 互动管理 (`Services/InteractionManager.swift`)

处理用户与宠物的交互：

- **点击**: 单击宠物 → triggerReaction() → 播放反应动画（跳一下 + 心情变 happy）
- **拖拽**: 按住拖动宠物 → 更新 petPosition → 宠物跟随鼠标移动
- **双击**: 双击宠物 → 特殊动作（旋转跳跃动画）
- **实现方式**: NSView 的 mouseDown/mouseDragged/mouseUp 事件，通过 NSPanel 的 contentView 捕获

关键 API:
```swift
@Observable
final class InteractionManager {
    func handleMouseDown(at point: NSPoint)
    func handleMouseDragged(to point: NSPoint)
    func handleMouseUp(at point: NSPoint)
    func handleDoubleClick(at point: NSPoint)
}
```

### M5: PomodoroService — 番茄钟 (`Services/PomodoroService.swift`)

番茄钟计时器核心逻辑：

- **标准循环**: 25 分钟工作 → 5 分钟休息 → 重复
- **状态转换**: idle → working → breaking → working → ...
- **通知**: 每个阶段结束时发送 macOS 通知 (UNUserNotificationCenter)
- **统计**: 跟踪今日完成的专注周期数和总专注分钟数
- **与宠物联动**: 状态变化时更新 PetState.pomodoroState，触发动画引擎行为切换

关键 API:
```swift
@Observable
final class PomodoroService {
    func startPomodoro()   // 开始工作阶段
    func pausePomodoro()   // 暂停（保留剩余时间）
    func resetPomodoro()   // 重置到空闲
    func skipPhase()       // 跳过当前阶段
}
```

持有 Timer 引用为属性（避免陷阱 #12）。

### M6: MenuBarManager — 菜单栏 (`DeskPetApp.swift` 中的 MenuBarExtra + `Views/PomodoroPopoverView.swift`)

不是独立类，而是 App Scene 中的 MenuBarExtra 配置 + popover 视图：

- **MenuBarExtra**: 显示猫咪图标 + 番茄钟剩余时间
- **Popover 内容** (PomodoroPopoverView):
  - 番茄钟控制（开始/暂停/重置/跳过）
  - 当前状态显示（工作中/休息中/空闲）
  - 剩余时间倒计时
  - 今日专注统计（完成周期数、总分钟数）
  - 显示/隐藏宠物开关
  - 退出按钮
- **图标**: 使用 SF Symbol `cat.fill`

## 数据流

```
PetState (单一数据源)
  ├── PetAnimationEngine 读写 (animationState, petPosition, facingRight)
  ├── PomodoroService 读写 (pomodoroState, timeRemaining, sessionCount, focusMinutes)
  ├── InteractionManager 读写 (petPosition, mood, animationState)
  ├── PetCanvasView 读取 (渲染当前帧)
  ├── PetWindowController 读取 (窗口位置)
  └── PomodoroPopoverView 读取 (显示状态和统计)
```

所有 Service 在 App 入口初始化，通过 @State 持有（避免 ARC 回收）。PetState 通过 .environment() 注入 SwiftUI 视图。

## 实现批次

### Batch 1: 核心基础（M1-M3）
- M1: PetState — 全局状态 + SpriteData 像素帧数据
- M2: PetAnimationEngine — 动画状态机 + 移动 AI + 帧循环
- M3: PetWindowController — NSPanel 浮动窗口 + PetCanvasView 渲染

**验证标准**: 应用启动后，一只像素小猫出现在桌面上，自动走动/坐下/闲逛，窗口透明悬浮

### Batch 2: 交互功能（M4-M6）
- M4: InteractionManager — 点击/拖拽/双击互动
- M5: PomodoroService — 番茄钟计时 + 通知 + 宠物行为联动
- M6: MenuBarManager — MenuBarExtra popover UI + 控制面板

**验证标准**: 可以点击/拖拽宠物，番茄钟可启动并倒计时，菜单栏显示控制面板和统计
