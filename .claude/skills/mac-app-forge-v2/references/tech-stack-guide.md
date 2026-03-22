# 技术栈选择指南

## 决策矩阵

| 特征 | → Swift/SwiftUI | → Electron |
|------|----------------|------------|
| Menu bar app | ✅ 最佳 | ❌ 过重 |
| 系统 API（文件监控、快捷键、通知） | ✅ 原生支持 | ⚠️ 需要 node 模块 |
| 复杂 UI（多 panel、富文本编辑器） | ⚠️ 可以但费力 | ✅ Web 技术擅长 |
| 包体大小敏感 | ✅ 几 MB | ❌ 100MB+ |
| Claude 编码能力 | 中上 | 最强 |
| 需要 npm 生态（markdown 解析、图表等） | ❌ 不适用 | ✅ 直接用 |
| 数据库/本地存储 | SwiftData / UserDefaults | better-sqlite3 / electron-store |

## 默认选择

**如果没有明确理由选 Electron，一律选 Swift/SwiftUI。**

理由：
1. 包体小，用户体验原生
2. 不需要安装 Node.js 运行时
3. 系统集成能力强
4. 适合工具类 app（这是本 skill 最常见的场景）

## 何时选 Electron

仅在以下情况选择 Electron：
1. 核心功能依赖 Web 技术（如内嵌浏览器、Markdown 实时预览）
2. 需要大量 npm 生态包且没有 Swift 替代
3. 用户明确要求跨平台

## 关于 Tauri

Tauri 理论上优于 Electron（包体小、性能好），但：
- Rust 后端代码 Claude 生成质量不稳定
- 调试成本高
- 当前阶段不推荐作为默认选项
- 如果用户明确要求 Tauri，可以尝试，但需警告风险

## Swift/SwiftUI 的已知坑

来源：Indragie (Context app 作者)、Paul Hudson、Peter Steinberger 等实战经验

1. **Swift Concurrency** — Claude 对 async/await 和 actor 的使用经常出错。
   - 对策：CLAUDE.md 中明确要求使用 `@MainActor` 和现代 concurrency 模式
   - 参考 steipete/agent-rules 的 swift-concurrency.md

2. **SwiftUI type-check 超时** — 复杂 View body 导致编译器报 "unable to type-check this expression in reasonable time"
   - 对策：及时拆分 View body 为子 View，每个 body 不超过 20 行

3. **AppKit vs SwiftUI 混用** — Claude 经常回退到 Objective-C / AppKit API
   - 对策：CLAUDE.md 中明确 "SwiftUI first, AppKit only when SwiftUI cannot do it"

4. **Legacy API** — Claude 会用 `foregroundColor()` 而非 `foregroundStyle()`、用 `ObservableObject` 而非 `@Observable`
   - 对策：CLAUDE.md 中列出常见 deprecated API 映射

5. **Swift Package Manager vs Xcode project** — SPM 项目更容易被 Claude 操作（纯文本 Package.swift vs 二进制 .xcodeproj）
   - 对策：优先使用 SPM，避免 .xcodeproj
