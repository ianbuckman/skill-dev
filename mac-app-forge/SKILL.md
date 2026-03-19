---
name: mac-app-forge
description: 从创意到 .dmg 的全自动 macOS 应用构建流水线。当用户说"帮我做个 Mac app""做个桌面应用""build a macOS app""我想要一个能...的工具""做个 menu bar 小工具""帮我做个...的 Mac 软件""forge an app""造个 app"等时触发。也适用于用户描述了一个工具需求、痛点或创意，暗示可以做成 macOS 桌面应用的场景。本 skill 覆盖从构思→技术方案→编码→测试→打包 .dmg→使用手册的完整流程，交付物是一个可安装的 .dmg 文件和使用说明。即使用户只是说"这个能不能做成个 app"，也应该触发。注意：本 skill 用于创建新的 macOS 应用，不用于修改已有项目（已有项目请直接在项目中工作）。
---

# Mac App Forge — 从创意到 .dmg 全自动流水线

将一句话需求变成可安装的 macOS 应用。Claude 自主完成构思、编码、测试、打包全流程，最终交付 .dmg 安装包 + 使用手册。

## 环境要求

- macOS（M1/M2/M3 系列推荐）
- Xcode Command Line Tools（`xcode-select --install`）
- 可选：`create-dmg` (`brew install create-dmg`)，若未安装则 fallback 到 `hdiutil`

## 流水线总览

```
用户输入（一句话需求）
    ↓
[Phase 1] 创意细化 → _task_state.md + phase1_concept.md
    ↓
[Phase 2] 技术方案 → ARCHITECTURE.md（更新 _task_state.md 技术栈+模块清单）
    ↓
[Phase 3] 脚手架生成 → 项目骨架 + CLAUDE.md + git init
    ↓
[Phase 4] 编码实现 → 逐模块实现（每模块 compile + commit + 更新进度）
    ↓
[Phase 5] 构建测试 → phase5_build_report.md
    ↓
[Phase 6] 打包发布 → dist/[AppName].dmg
    ↓
[Phase 7] 使用手册 → README.md
    ↓
交付：.dmg + 使用手册
```

---

## 长任务韧性机制

这条流水线从头跑到尾可能几百次工具调用，context 会逐渐被中间产物淹没，后期阶段容易偏离初始目标。以下机制是流水线的"脊柱"：

### _task_state.md — 任务北极星

Phase 1 结束后在项目根目录创建 `_task_state.md`，这是整个流水线的唯一真相来源：
- **目标区**（创建后不可修改）：App 名称、一句话描述、核心功能、App 类型、技术栈、项目路径
- **进度区**（每个 Phase 结束时更新）：哪些完成了、当前在哪
- **模块清单**（Phase 2 完成后填写）：Phase 4 逐模块实现时的检查点

为什么这很重要：到 Phase 5/6 时，对话上下文中可能已经积累了几千行编译输出和代码。如果不重读 `_task_state.md`，模型很容易忘记 App 叫什么名字、核心功能是什么。重读一个文件的成本极低，偏离目标的成本极高。

### 文件接力 — 不依赖对话记忆

每个 Phase 把产出写入文件，下一个 Phase 从文件读取输入。这样即使对话上下文被压缩，关键信息也不会丢失。

### Phase 转场协议

**进入新 Phase 时（强制）：**
1. 重读 `_task_state.md` — 确认目标和当前进度
2. 读取上一阶段的输出文件 — 获取具体输入

**完成当前 Phase 时（强制）：**
1. 将产出写入指定文件
2. 更新 `_task_state.md`（勾选当前 Phase，更新"当前阶段"描述）
3. 向用户一句话汇报，然后自动进入下一阶段（需要用户决策才暂停）

### 编译输出压缩

编译/构建命令的输出往往很长，会挤占上下文中的有效信息。规则：
- `swift build` 或 `npm run build` 的输出，只关注 error 和 warning
- 如果输出超过 50 行，用 `2>&1 | tail -30` 只保留尾部
- 构建成功时，只需记录"编译成功，0 errors，N warnings"

---

## Phase 1: 创意细化

### 输入
用户的一句话需求，可能很模糊（"帮我做个能 XXX 的工具"）。

### 任务
1. 从用户描述中提取：**核心功能**、**目标用户**、**使用场景**
2. 补充 Claude 认为合理的辅助功能（不超过 2-3 个）
3. 生成 App Concept 展示给用户：

```markdown
## App Concept: [App 名称]
- **一句话描述**: ...
- **核心功能**: 1. ... 2. ... 3. ...
- **目标用户**: ...
- **App 类型**: [Menu Bar App / 标准窗口 App / 文档型 App]
```

4. 将 App Concept 展示给用户，等待确认或修改
5. 用户确认后，执行两件事：

**写入 `phase1_concept.md`** — 保存确认后的完整 concept

**创建 `_task_state.md`：**
```markdown
# Task State — [App Name]

## 目标（创建后不可修改）
- App 名称: [name]
- 一句话描述: [description]
- 核心功能:
  1. [功能1]
  2. [功能2]
  3. [功能3]
- App 类型: [Menu Bar / 标准窗口 / 文档型]
- 技术栈: [待定]
- 项目路径: [path]

## 进度
- [x] Phase 1: 创意细化 → phase1_concept.md
- [ ] Phase 2: 技术方案 → ARCHITECTURE.md
- [ ] Phase 3: 脚手架生成
- [ ] Phase 4: 编码实现
- [ ] Phase 5: 构建测试 → phase5_build_report.md
- [ ] Phase 6: 打包发布 → dist/[AppName].dmg
- [ ] Phase 7: 使用手册 → README.md

## 当前阶段
Phase 2: 根据 phase1_concept.md 选择技术栈，设计项目架构。

## Phase 4 模块清单（Phase 2 完成后填写）
[待填写]
```

6. 进入 Phase 2

### 关键原则
- 倾向于做**小而精**的工具，不要过度设计
- 如果用户没指定，默认做 Menu Bar App（最轻量）
- 功能点控制在 3-5 个以内，避免范围膨胀

---

## Phase 2: 技术方案

### 转场读取
- 重读 `_task_state.md` 目标区
- 读取 `phase1_concept.md`

### 技术栈选择（自动判断，不需要问用户）

读取 `references/tech-stack-guide.md` 了解各技术栈的详细对比和选择逻辑。

**快速决策树**：
- 需要系统级 API（menu bar、通知、文件系统监控、快捷键）→ **Swift/SwiftUI**
- 需要复杂富文本 UI、web 技术、大量现有 npm 生态 → **Electron**
- 简单数据处理/脚本类工具 → **Swift/SwiftUI**（默认选项）

### 输出
生成 `ARCHITECTURE.md`，包含：
- 技术栈选择及理由（一句话）
- 项目结构树
- 核心模块划分（每个模块一句话描述其职责）
- 数据存储方案
- 第三方依赖列表（尽量少）

### 转场写入
更新 `_task_state.md`：
1. 目标区填入技术栈
2. 勾选 Phase 2
3. **填写 Phase 4 模块清单**：根据 ARCHITECTURE.md 的模块划分，列出每个待实现模块及其优先级顺序

不需要用户确认，直接进入 Phase 3。

---

## Phase 3: 脚手架生成

### 转场读取
- 重读 `_task_state.md` 目标区
- 读取 `ARCHITECTURE.md`

读取 `references/scaffold-[tech].md`（根据 Phase 2 选定的技术栈）获取项目模板。

### Swift/SwiftUI 路线
1. 创建 Swift Package 项目结构（不依赖 .xcodeproj）
2. 生成 `Package.swift` 含正确的 macOS target 和 platform 声明
3. 生成 `Sources/` 目录结构
4. 生成 App 入口文件（`@main` App struct）
5. 生成 `Info.plist` 模板
6. 生成项目级 `CLAUDE.md`（写入 Swift/SwiftUI 最佳实践规则）

### Electron 路线
1. `npm init` + 安装 electron, electron-builder
2. 生成 `main.js`, `preload.js`, `index.html` 骨架
3. 生成 `package.json` 含 build 配置
4. 生成项目级 `CLAUDE.md`

### 公共步骤
5. 生成 `.gitignore`
6. 初始化 git repo
7. 首次提交："Initial scaffold"

### 转场写入
更新 `_task_state.md` 勾选 Phase 3，进入 Phase 4。

---

## Phase 4: 编码实现

这是最长的阶段，可能占整条流水线 60-70% 的时间和工具调用。需要特别的韧性措施防止偏离。

### 转场读取
- 重读 `_task_state.md`（完整文件，包括目标区和模块清单）
- 读取 `ARCHITECTURE.md`
- 读取项目的 `CLAUDE.md`

### 工作模式

按 `_task_state.md` 中的模块清单顺序实现（核心功能 → UI → 辅助功能）。

**每个模块的工作循环：**
1. **重读 `_task_state.md` 目标区和模块清单** — 每个模块开始前都做，这是防止长编码过程中偏离方向的关键。到第 3、4 个模块时，对话中已积累大量代码和编译输出，不重读就很容易忘记整体目标
2. 读取 `ARCHITECTURE.md` 中该模块的设计描述
3. 写代码
4. 编译验证（`swift build` 或 `npm run build`），输出只看 error/warning
5. 修复编译错误（最多 5 轮自动修复）
6. 如果 5 轮后仍有问题，简化实现，不要死磕
7. git commit（commit message 包含模块名）
8. 更新 `_task_state.md` 勾选该模块

**所有模块完成后：**
1. 做一次全量编译确认
2. 更新 `_task_state.md` 勾选 Phase 4

### Swift/SwiftUI 编码规则
读取 `references/swift-coding-rules.md` 获取详细规则。核心要点：
- 用 SwiftUI，不用 AppKit（除非 SwiftUI 不支持）
- 用 `@Observable` 而非 `ObservableObject`
- 用 SF Symbols 做图标
- View body 不要太复杂，及时拆分子 View
- 遵循 Apple Human Interface Guidelines

### Electron 编码规则
读取 `references/electron-coding-rules.md` 获取详细规则。

### 通用规则
- 不要引入不必要的第三方依赖
- 错误处理要到位，不要 crash
- 用户数据存到合理位置（`~/Library/Application Support/[AppName]/`）

---

## Phase 5: 构建测试

### 转场读取
- 重读 `_task_state.md` 目标区 — 确认 App 名称和核心功能
- 读取 `ARCHITECTURE.md` — 了解应该验证哪些模块

### 构建
- Swift: `swift build -c release 2>&1 | tail -30`
- Electron: `npm run build 2>&1 | tail -30`

### 基础验证
由于 Claude Code 无法直接启动 GUI 应用并交互，验证范围有限：
1. **编译通过** — 零 error
2. **Warning 审查** — 修复关键 warning
3. **单元测试** — 如果有测试，运行并确认通过
4. **二进制检查** — 确认产物存在且大小合理

### 如果构建失败
1. 读取错误信息
2. 自动修复（最多 5 轮）
3. 如果仍失败，向用户报告具体错误，请求协助

### 转场写入
将构建结果写入 `phase5_build_report.md`：
```markdown
## 构建报告
- 状态: 成功/失败
- 编译警告数: N
- 二进制路径: [path]
- 二进制大小: [size]
- 需要关注的问题: [如果有]
```
更新 `_task_state.md` 勾选 Phase 5。

---

## Phase 6: 打包 .dmg

### 转场读取
- 重读 `_task_state.md` 目标区（确认 App 名称、类型）
- 读取 `phase5_build_report.md`（确认二进制路径和状态）

读取 `references/packaging-guide.md` 获取详细打包流程。

### Swift 路线
```bash
# 1. Release build
swift build -c release

# 2. 创建 .app bundle
# 脚本会处理：Info.plist、可执行文件复制、资源文件、图标
# 详见 references/packaging-guide.md

# 3. 生成 .dmg
# 优先用 create-dmg（美观），fallback 到 hdiutil（基础）
```

### Electron 路线
```bash
npx electron-builder --mac dmg
```

### 图标生成
- 如果用户没提供图标，使用 `references/icon-generation.md` 中的方法生成一个简单的 SF Symbol 或文字 icon
- 生成 1024x1024 PNG → 转换为 .icns

### 最终检查
1. .dmg 文件存在
2. 双击可挂载（`hdiutil attach` 验证）
3. .app 在挂载卷中存在
4. 记录文件大小

### 转场写入
更新 `_task_state.md` 勾选 Phase 6。

---

## Phase 7: 使用手册

### 转场读取
- 重读 `_task_state.md` 目标区（确认 App 名称、功能列表）
- 读取 `phase1_concept.md`（获取完整功能描述，确保使用手册覆盖所有功能）

在项目根目录生成 `README.md`：

```markdown
# [App 名称]

[一句话描述]

## 安装

1. 双击 `[AppName].dmg`
2. 将 [AppName] 拖入 Applications 文件夹
3. 首次打开：右键 → 打开（绕过 Gatekeeper）

## 使用方法

[截图位置预留]

### [功能 1]
...

### [功能 2]
...

## 卸载

将 [AppName] 从 Applications 拖入废纸篓。

## 技术信息

- 技术栈: [Swift/SwiftUI | Electron]
- 最低系统要求: macOS [版本]
- 架构: Apple Silicon (arm64)
```

### 转场写入
更新 `_task_state.md` 勾选 Phase 7。

---

## 交付

最终向用户报告：

```
✅ Mac App Forge 完成！

📦 安装包: [项目路径]/dist/[AppName].dmg ([大小])
📖 使用手册: [项目路径]/README.md
📁 源代码: [项目路径]/

安装方法：双击 .dmg → 拖入 Applications → 右键打开

⚠️ 注意：未经 Apple Developer 签名，首次打开需要右键→打开。
```

---

## 重要原则

1. **自主决策，少问多做** — 除了 Phase 1 确认 App Concept 外，尽量自主推进，不要反复问用户技术细节
2. **小而美** — 宁可功能少一点、做得精一点，也不要做半成品
3. **快速失败，优雅降级** — 某个功能实现不了就简化，不要卡住整条流水线
4. **每阶段 git commit** — 方便回滚和查看进展
5. **编译驱动** — 写完就编译，编译就修，不要攒一堆代码最后一起编译
6. **读文件不读记忆** — 跨阶段的信息传递通过文件（`_task_state.md`、`ARCHITECTURE.md`、`phase1_concept.md` 等），不要依赖对话历史中"之前看到的内容"。重读一个文件的成本极低，偏离目标的成本极高
