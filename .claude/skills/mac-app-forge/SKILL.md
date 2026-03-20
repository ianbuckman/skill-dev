---
name: mac-app-forge
description: 从创意到 .dmg 的全自动 macOS 应用构建流水线。当用户说"帮我做个 Mac app""做个桌面应用""build a macOS app""我想要一个能...的工具""做个 menu bar 小工具""帮我做个...的 Mac 软件""forge an app""造个 app"等时触发。也适用于用户描述了一个工具需求、痛点或创意，暗示可以做成 macOS 桌面应用的场景。本 skill 覆盖从构思→技术方案→编码→测试→打包 .dmg→使用手册的完整流程，交付物是一个可安装的 .dmg 文件和使用说明。即使用户只是说"这个能不能做成个 app"，也应该触发。注意：本 skill 用于创建新的 macOS 应用，不用于修改已有项目（已有项目请直接在项目中工作）。
---

# Mac App Forge — CIV 架构全自动流水线

将一句话需求变成可安装的 macOS 应用。采用 Coordinator-Implementor-Verifier (CIV) 三层架构，通过 sub-agent 隔离确保每个模块的实现质量。

## 环境要求

- macOS（M1/M2/M3/M4 系列推荐）
- Xcode Command Line Tools（`xcode-select --install`）
- 可选：`create-dmg` (`brew install create-dmg`)，若未安装则 fallback 到 `hdiutil`

## CIV 核心架构

```
┌────────────────────────────────────────────────┐
│              Coordinator（你自己）                │
│  • 全局编排、状态管理、门控决策                      │
│  • 掌控 _task_state.md，决定下一步做什么             │
│  • 执行 git commit / swift build / 状态更新        │
│  • 绝不自己写模块代码（委托给 Implementor）           │
├──────────┬─────────────────┬───────────────────┤
│          ▼                 ▼                   │
│  ┌──────────────┐  ┌──────────────┐           │
│  │ Implementor  │  │  Verifier    │           │
│  │ (sub-agent)  │  │ (sub-agent)  │           │
│  │              │  │              │           │
│  │ • 只实现 1 个 │  │ • 对照 ARCH  │           │
│  │   模块的代码  │  │   审查实现   │           │
│  │ • 隔离 context│  │ • 检查运行时 │           │
│  │ • 不碰状态文件│  │   陷阱清单   │           │
│  └──────────────┘  └──────────────┘           │
└────────────────────────────────────────────────┘
```

### 为什么用 CIV

| 问题 | 旧架构（自管理） | CIV 架构 |
|------|---------------|---------|
| LLM 跳过中间步骤 | Coordinator 和 Implementor 是同一个 agent，可自由跳步 | Coordinator 控制流程，Implementor 无法跳过 |
| 上下文过长导致规则遗忘 | 写到第 15 个模块时早期规则已衰减 | 每个 sub-agent 获得新鲜 context，只包含当前模块的信息 |
| 自己审查自己 | 写代码和审查代码是同一个 agent | Verifier 独立于 Implementor |
| 状态更新被跳过 | LLM 可以选择不更新 _task_state.md | 状态更新在 Coordinator 的代码路径中，sub-agent 不涉及 |

### Coordinator 职责边界（严格遵守）

**Coordinator 做的事：**
- 读写 `_task_state.md`
- 执行 `swift build` / `npm run build`
- 执行 `git add` + `git commit`
- 启动 Implementor 和 Verifier sub-agents
- 运行功能验证脚本
- 决定是否进入下一步或回退修复

**Coordinator 不做的事：**
- ❌ 不自己写模块实现代码（全部委托给 Implementor sub-agent）
- ❌ 不自己做代码审查（全部委托给 Verifier sub-agent）

**唯一例外**：Phase 3 脚手架代码和小型修复（< 20 行）可以由 Coordinator 直接完成。

## 专业 Skill 编排

mac-app-forge 专注流水线编排 + macOS 应用特有知识，编码质量委托给专业 skills：

| Skill | 阶段 | 职责 | 未安装时 Fallback |
|-------|------|------|-------------------|
| /swiftui-pro | Phase 4 (Verifier) | SwiftUI 审查 | references/macos-patterns.md |
| /swift-concurrency-pro | Phase 4 (Verifier) | 并发正确性 | macos-patterns.md fallback 段 |
| /swift-testing-pro | Phase 5 | 关键模块测试 | 跳过（功能验证仍执行） |
| /swift-api-design-guidelines-skill | Phase 4 (Implementor) | API 命名 | 跳过 |
| /swiftdata-pro | Phase 4 (Verifier) | SwiftData 审查 | 跳过 |
| /review | Phase 5 | 结构性审查 | 内置陷阱扫描 |

**检测方式**：流水线开始时检查可用 skills 列表，记录哪些已安装。

## 规模控制（硬性规则）

**在 Phase 2 确定模块清单后，强制执行以下规则：**

| 模块数 | 策略 |
|--------|------|
| ≤ 5 | 单批交付 |
| 6-10 | 分 2 批，每批结束后编译+功能验证+用户确认 |
| 11-15 | 分 3 批 |
| > 15 | **停下来**，向用户说明风险，协商精简需求或拆分为多个 app |

**每批不超过 5 个模块。违反此规则的唯一理由是用户明确指示。**

批次划分原则：
1. 核心功能模块放第一批（让用户尽早能验证核心价值）
2. 有依赖关系的模块放同一批
3. UI 模块和其依赖的 Service 模块放同一批

## 流水线总览

```
用户输入（一句话需求）
    ↓
[Phase 1] 创意细化 → _task_state.md + phase1_concept.md
    ↓
[Phase 2] 技术方案 → ARCHITECTURE.md（含批次划分）
    ↓
[Phase 3] 脚手架生成 → 项目骨架 + CLAUDE.md + git init
    ↓
[Phase 4] CIV 编码循环（按批次）：
    ┌─ 对每个批次：
    │   ┌─ 对每个模块：
    │   │   Implementor sub-agent 写代码
    │   │   → Coordinator 编译
    │   │   → Coordinator commit
    │   │   → 更新 _task_state.md
    │   └─
    │   Verifier sub-agent 审查本批全部代码
    │   → Coordinator 修复 + 重新编译
    │   → 功能验证（可执行的验证脚本）
    │   → git commit "Batch N complete"
    │   → 如果还有下一批且模块总数 > 5：暂停，请用户确认
    └─
    ↓
[Phase 5] 集成验证 ← 功能验证循环（编译→启动测试→功能验证→审查，最多3轮）
    ↓
[Phase 6] 打包发布 → .dmg + README.md
    ↓
[Phase 7] 交付与用户验证 ← 用户反馈循环（最多3轮）
    ↓
交付确认：用户满意 ✅
```

---

## 长任务韧性机制

本流水线可能跨越数百次工具调用甚至多个对话 session，以下三层机制协同防止偏离：

### 第一层：_task_state.md — 项目级状态（详细）

Phase 1 结束后创建，**只有 Coordinator 可以写入**。包含完整的模块清单、批次进度、验证记录。是流水线的唯一详细真相来源。

### 第二层：Claude Code Memory — 跨对话恢复（自动加载）

利用 Claude Code 的 memory 机制，在每个关键节点保存进度快照。**Memory 会在新对话启动时自动加载到上下文**，即使对话 context 被重置或用户开启新对话，Coordinator 也能立刻知道当前进度。

**Memory 写入时机（Coordinator 在以下节点执行）：**

1. **Phase 1 完成后** — 保存 memory：
   ```markdown
   ---
   name: forge-[AppName]-progress
   description: mac-app-forge 正在构建 [AppName]，当前进度 Phase [N]
   type: project
   ---
   正在构建: [AppName] — [一句话描述]
   项目路径: [path]
   当前阶段: Phase [N]
   技术栈: [tech]
   _task_state.md 位置: [path]/_task_state.md
   ```

2. **每个批次完成后** — 更新同一个 memory 文件的 `当前阶段` 和进度

3. **每次 Phase 转场时** — 更新 memory

4. **交付完成后** — 删除该 memory（项目结束，不再需要）

**Memory 读取时机：**
- 新对话启动时 memory 自动加载 → 如果看到 `forge-*-progress` 的 memory，说明有未完成的 forge 项目 → 立刻读取对应的 `_task_state.md` 恢复上下文

### 第三层：文件接力

每个 Phase 从文件读取输入、把产出写入文件。不依赖对话记忆。

### Phase 转场协议

**进入新 Phase 时（强制）：**
1. 重读 `_task_state.md` + 上一阶段输出文件
2. 检查 memory 中的进度是否与 `_task_state.md` 一致（不一致则以 `_task_state.md` 为准）

**完成当前 Phase 时（强制）：**
1. 写入产出文件
2. 更新 `_task_state.md`
3. 更新 memory（forge-[AppName]-progress）
4. 一句话汇报

### 编译输出压缩

输出超 50 行用 `2>&1 | tail -30`。成功时只记"编译成功，0 errors，N warnings"。

---

## Phase 1: 创意细化

### 输入
用户的一句话需求。

### 任务
1. 提取：**核心功能**、**目标用户**、**使用场景**
2. 补充合理辅助功能（不超过 2-3 个）
3. 展示 App Concept 给用户确认：

```markdown
## App Concept: [App 名称]
- **一句话描述**: ...
- **核心功能**: 1. ... 2. ... 3. ...
- **目标用户**: ...
- **App 类型**: [Menu Bar App / 标准窗口 App / 文档型 App]
```

4. 用户确认后，写入 `phase1_concept.md`，创建 `_task_state.md`（模板见下方）
5. 创建 Claude Code memory `forge-[AppName]-progress`，内容包含 App 名称、项目路径、当前阶段（Phase 2）

### 关键原则
- 小而精，功能 3-5 个，不膨胀
- 如果用户需求暗示 > 15 个模块，在此阶段就协商精简
- 未指定则默认 Menu Bar App

### _task_state.md 模板

```markdown
# Task State — [App Name]

## 目标（创建后不可修改）
- App 名称: [name]
- 一句话描述: [description]
- 核心功能:
  1. [功能1]
  2. [功能2]
  3. [功能3]
- App 类型: [类型]
- 技术栈: [待定]
- 项目路径: [path]

## 进度
- [x] Phase 1: 创意细化 → phase1_concept.md
- [ ] Phase 2: 技术方案 → ARCHITECTURE.md
- [ ] Phase 3: 脚手架生成
- [ ] Phase 4: 编码实现
- [ ] Phase 5: 集成验证 → phase5_build_report.md
- [ ] Phase 6: 打包发布 → dist/[AppName].dmg + README.md
- [ ] Phase 7: 交付与用户验证

## 当前阶段
Phase 2

## 批次计划（Phase 2 完成后填写）
[待填写]

## Phase 4 模块清单（Phase 2 完成后填写）
[待填写]

## 验证记录（Phase 7 使用）
[待填写]
```

---

## Phase 2: 技术方案

### 转场读取
- 重读 `_task_state.md` 目标区
- 读取 `phase1_concept.md`
- 读取 `references/tech-stack-guide.md`

### 快速决策树
- 系统级 API（menu bar、通知、文件监控、快捷键）→ **Swift/SwiftUI**
- 复杂富文本 UI、web 技术、npm 生态 → **Electron**
- 默认 → **Swift/SwiftUI**

### 输出
生成 `ARCHITECTURE.md`：技术栈、项目结构树、核心模块划分（每模块一句话）、数据存储方案、依赖列表

### 批次划分

在 `ARCHITECTURE.md` 末尾增加批次划分：

```markdown
## 实现批次

### Batch 1: 核心基础（模块 M1-M3）
- M1: AppState — 全局状态
- M2: CoreService — 核心业务逻辑
- M3: MainView — 主界面
验证标准: 应用启动，主界面显示，核心操作可执行

### Batch 2: 扩展功能（模块 M4-M6）
- M4: ...
- M5: ...
- M6: ...
验证标准: [具体的可验证行为]
```

每个批次必须附带**可执行的验证标准**（不是"看起来对"，而是"执行 X 操作后 Y 结果出现"）。

### 转场写入
更新 `_task_state.md`：填入技术栈、勾选 Phase 2、填写模块清单和批次计划。

---

## Phase 3: 脚手架生成

### 转场读取
- 重读 `_task_state.md` 目标区
- 读取 `ARCHITECTURE.md` + `references/scaffold-[tech].md`

### Swift/SwiftUI 路线
1. Swift Package 结构（不用 .xcodeproj）
2. `Package.swift` + `Sources/` + App 入口 + `Info.plist`
3. 项目级 `CLAUDE.md`

### Electron 路线
1. `npm init` + electron + electron-builder
2. `main.js` + `preload.js` + `index.html` + `package.json`
3. 项目级 `CLAUDE.md`

### 公共步骤
`.gitignore` → git init → "Initial scaffold" commit → 编译确认脚手架可构建

### 转场写入
更新 `_task_state.md` 勾选 Phase 3。

---

## Phase 4: CIV 编码循环

**最长阶段。Coordinator 绝不自己写模块代码，全部通过 sub-agent 完成。**

### 转场读取
- 重读 `_task_state.md`（完整，含模块清单和批次计划）
- 读取 `ARCHITECTURE.md` + 项目 `CLAUDE.md`

### 批次循环

对每个批次，执行以下完整循环：

#### Step 1: 逐模块实现（Implementor sub-agent）

对当前批次的每个模块，Coordinator 按顺序执行：

**1a. 启动 Implementor sub-agent**

使用 Agent tool 启动 sub-agent，prompt 模板：

```
你是一个 Swift/SwiftUI 开发者。你只需要实现一个模块。

## 你的任务
实现模块: [模块名]
功能描述: [从 ARCHITECTURE.md 摘取的该模块设计]

## 项目信息
- 项目路径: [path]
- 技术栈: [tech stack]
- 已有代码: [列出该模块依赖的已实现模块的文件路径]

## 编码规则
- [从项目 CLAUDE.md 摘取关键规则]
- [从 references/macos-patterns.md 摘取相关规则]

## 要求
1. 只实现 [模块名] 的代码，不要修改其他模块
2. 读取依赖模块的接口（如果有），确保调用方式正确
3. 写完后运行 `swift build 2>&1 | tail -30` 确认编译通过
4. 如果编译失败，修复错误后重新编译（最多 5 轮）
5. 5 轮后仍失败，简化实现并说明简化了什么
6. 不要修改 _task_state.md
7. 不要执行 git commit
```

**注意**：如果两个模块之间没有依赖关系，可以并行启动两个 Implementor sub-agent（使用 Agent tool 的并行调用）。

**1b. Coordinator 编译验证**

Sub-agent 完成后，Coordinator 自己运行编译确认：

```bash
swift build 2>&1 | tail -30
# 或 Electron:
npm run build 2>&1 | tail -30
```

编译失败 → 启动新的 Implementor sub-agent 修复（提供错误信息），最多 3 轮。3 轮后仍失败 → 标记该模块为 ⚠️，继续下一个模块。

**1c. Coordinator commit + 更新状态**

```bash
git add [该模块的文件]
git commit -m "M{N}: [模块名]"
```

更新 `_task_state.md`：`- [x] M{N}: [模块名]`

#### Step 2: 批次验证（Verifier sub-agent）

当前批次所有模块实现完毕后，启动 Verifier sub-agent：

```
你是一个代码审查专家。审查以下模块的实现质量。

## 审查范围
本批次模块: [列出文件路径]
架构设计: [从 ARCHITECTURE.md 摘取本批次模块的设计]

## 审查清单
1. 每个模块是否实现了 ARCHITECTURE.md 中描述的全部功能？列出缺失项。
2. 模块间的调用关系是否正确？参数类型、返回值是否匹配？
3. 检查 references/macos-patterns.md 中的运行时陷阱（逐项检查）：
   [粘贴完整陷阱清单]
4. 是否有明显的逻辑错误（如空函数体、未连接的回调、永远为 false 的条件）？
5. 异步代码是否正确使用 @MainActor？是否有潜在的数据竞争？

## 输出格式
对每个发现的问题：
- 文件: [路径]
- 行号: [行号范围]
- 问题: [描述]
- 严重度: [Critical / Warning / Info]
- 建议修复: [代码片段]
```

Verifier 返回问题列表后，Coordinator 处理：
- **Critical**: 必须修复。启动 Implementor sub-agent 修复，然后重新编译。
- **Warning**: 尽量修复。小修复 (< 20 行) Coordinator 直接做。
- **Info**: 记录但不阻塞。

#### Step 3: 批次功能验证

Coordinator 运行编译 + 启动测试：

```bash
# 编译
swift build -c release 2>&1 | tail -10

# 启动测试（5 秒超时）
timeout 5 .build/release/[AppName] 2>&1 || true
```

对于 Swift Menu Bar App，额外检查：
```bash
# 检查进程是否存在
pgrep -x [AppName] && echo "✅ 进程存活" || echo "❌ 进程不存在"

# 检查 menu bar item（如果有 Accessibility 权限）
# 如果无法自动验证，记录为"需手动验证"
```

#### Step 4: 批次间用户检查点

**如果项目模块总数 > 5 且还有后续批次：**

向用户报告当前批次完成状态：
```
📦 Batch [N]/[Total] 完成

已实现模块:
- [x] M1: [名称] — [一句话描述]
- [x] M2: [名称] — [一句话描述]

编译状态: ✅ 通过
启动测试: ✅ 通过

请验证以下功能：
- [ ] [本批次的验证标准 1]
- [ ] [本批次的验证标准 2]

确认 OK 后我继续实现下一批。如有问题请告诉我。
```

等待用户确认后继续。如用户报告问题，在当前批次内修复后再推进。

#### Step 5: 全量编译（最后一个批次完成后）

```bash
swift build -c release 2>&1 | tail -30
```

更新 `_task_state.md` 勾选 Phase 4。

---

## Phase 5: 集成验证

**编译通过 ≠ 能正常运行。** 本阶段通过多层验证尽可能在交付前发现问题。

### 转场读取
- 重读 `_task_state.md` 目标区和核心功能列表
- 读取 `ARCHITECTURE.md`

### 验证循环（最多 3 轮）

```
round = 1
while round <= 3:
    Step 1: 编译 → 失败则修复 → 重新编译
    Step 2: 启动与功能验证 → 失败则修复 → 回到 Step 1
    Step 3: 集成审查（Verifier sub-agent）→ 发现问题则修复 → 回到 Step 1
    全部通过 → break
    round += 1
3轮后仍有问题 → 写入报告并标注风险
```

### Step 1: 编译构建

```bash
# Swift
swift build -c release 2>&1 | tail -30
# Electron
npm run build 2>&1 | tail -30
```

编译失败 → 启动 Implementor sub-agent 修复 → 重新编译（最多 5 轮）

### Step 2: 启动与功能验证

**2a: 启动测试**

```bash
.build/release/[AppName] &
APP_PID=$!
sleep 5
if kill -0 $APP_PID 2>/dev/null; then
    echo "✅ 启动测试通过 (PID: $APP_PID)"
else
    echo "❌ 启动崩溃"
    # 查找 crash 日志
    ls -lt ~/Library/Logs/DiagnosticReports/ 2>/dev/null | head -5
fi
```

**2b: 功能验证脚本**

根据 `_task_state.md` 中的核心功能，编写并执行可自动化的验证。举例：

```bash
# 文件输出类功能：触发操作后检查文件是否生成
ls -la ~/Desktop/[AppName]_* 2>/dev/null | head -5

# 剪贴板类功能：检查剪贴板内容
pbpaste | head -1

# 网络服务类功能：检查端口是否监听
lsof -i :PORT 2>/dev/null

# Menu Bar App：检查进程是否存活并响应
kill -0 $APP_PID 2>/dev/null && echo "✅ 仍在运行"

# 终止测试进程
kill $APP_PID 2>/dev/null
```

**无法自动验证的功能**（如 UI 交互、快捷键响应）标记为"需手动验证"，加入 Phase 7 的验证清单。

崩溃 → 读取日志 → 启动 Implementor sub-agent 修复 → 回到 Step 1

### Step 2.5: 关键模块测试（Swift 路线，可选）

调用 /swift-testing-pro 为关键 Service 模块编写测试，运行 `swift test`。
> 未安装时跳过。

### Step 3: 集成审查（Verifier sub-agent）

启动 Verifier sub-agent 做全量审查：

```
你是一个 macOS 应用审查专家。对完整项目做集成审查。

## 审查范围
项目路径: [path]
读取所有源代码文件。

## 审查清单

### A. macOS 运行时陷阱（逐项检查，见 references/macos-patterns.md）
[粘贴完整陷阱清单]

### B. 集成正确性
1. App 入口 (@main) 是否正确注入了所有需要的 environment 对象？
2. 所有 Service 是否被正确初始化并持有引用（不是局部变量）？
3. 所有 UI 操作的回调链是否完整连通？（按钮 → action → service → 结果）
4. 所有异步操作是否有错误处理？静默失败的代码标注出来。

### C. 功能完整性
对照以下核心功能清单，检查每个功能的代码路径是否完整：
[粘贴 _task_state.md 的核心功能列表]
对每个功能回答: "代码路径完整" 或 "断裂在 [具体位置]"

## 输出格式
1. Critical 问题列表（必须修复）
2. Warning 列表（建议修复）
3. 功能完整性评估表
```

发现 Critical 问题 → Coordinator 启动 Implementor sub-agent 修复 → 重新编译 → 回到 Step 1

### Step 4: 生成验证清单

根据功能列表和自动验证结果，生成手动验证清单。**已自动验证通过的项标注为 ✅，无法自动验证的标注为 ⬜ 需手动验证。**

### 转场写入

写入 `phase5_build_report.md`：
```markdown
## 构建报告
- 编译: 成功/失败
- 警告数: N
- 二进制: [path] ([size])
- 启动测试: 通过/失败
- 功能验证: N/M 项自动通过
- 集成审查: N 个 Critical（已修复），M 个 Warning
- 验证轮次: X/3

## 自动验证结果
- ✅ [功能1]: [验证方式和结果]
- ✅ [功能2]: [验证方式和结果]
- ⚠️ [功能3]: [无法自动验证的原因]

## 手动验证清单
请安装后逐项确认：
- [ ] [无法自动验证的功能1]
- [ ] [无法自动验证的功能2]
```

---

## Phase 6: 打包发布

### 转场读取
- 重读 `_task_state.md` 目标区
- 读取 `phase5_build_report.md`

### 打包流程
读取 `references/packaging-guide.md`。

**Swift**: release build → .app bundle 组装 → 图标生成（`references/icon-generation.md`）→ .dmg
**Electron**: `npx electron-builder --mac dmg`

### DMG 验证
1. `hdiutil attach` 验证可挂载
2. .app 存在
3. 记录文件大小

### 生成 README.md
重读 `_task_state.md` 目标区 + `phase1_concept.md`，确保覆盖所有功能。
包含：安装方法、使用方法（每个核心功能一节）、快捷键、数据存储位置、卸载方法、技术信息。
如需辅助功能权限（全局快捷键等），在安装说明中明确提醒。

### 转场写入
更新 `_task_state.md` 勾选 Phase 6，git commit。

---

## Phase 7: 交付与用户验证循环

### 首次交付

向用户报告：
```
✅ Mac App Forge 初版完成！

📦 安装包: [路径]/dist/[AppName].dmg ([大小])
📖 使用手册: [路径]/README.md
📁 源代码: [路径]/

安装方法：双击 .dmg → 拖入 Applications → 右键打开
⚠️ 未签名，首次打开需右键→打开
⚠️ 如有全局快捷键，需在 系统设置→隐私→辅助功能 中授权

📋 自动验证已通过的功能：
[列出 Phase 5 自动验证通过的项]

📋 请手动验证以下功能：
[粘贴手动验证清单]

验证完成后告诉我结果，有问题我会修复并重新打包。
```

### 用户反馈修复循环（最多 3 轮）

用户报告问题后，执行以下流程：

**Step 1: 问题分类**

重读 `_task_state.md` 目标区，分析问题类型：

| 问题类型 | 示例 | 处理方式 |
|---------|------|---------|
| 代码 Bug | "点击没反应""崩溃" | Implementor sub-agent 修复对应模块 |
| UI/交互问题 | "按钮太小""布局不对" | Implementor sub-agent 修改 View |
| 架构缺陷 | "功能路径不通" | 回退 Phase 2 修订架构 → 重新实现 |
| 功能缺失 | "少了 XX 功能" | 回退 Phase 1 确认变更 → 补充实现 |
| 环境问题 | "权限不够" | 更新 README 说明 |

**Step 2: 修复**

1. 启动 Implementor sub-agent 修复（提供问题描述 + 相关代码）
2. Coordinator 编译验证
3. Coordinator 运行功能验证
4. 启动 Verifier sub-agent 确认修复正确
5. Coordinator commit + 重新打包（Phase 5 → Phase 6）
6. 更新 `_task_state.md` 验证记录区

**Step 3: 重新交付**

```
🔧 修复完成（第 N 轮）

修复内容：
- [问题1]: [修复方式]
- [问题2]: [修复方式]

📦 新安装包: [路径]/dist/[AppName].dmg ([大小])

请重新安装并验证：
- [ ] [上次失败的检查项]
- [ ] [新增/修改的检查项]
```

**Step 4: 循环判断**

- 用户说 OK → **交付完成** ✅ → 删除 `forge-[AppName]-progress` memory（项目结束）
- 还有问题 → 回到 Step 1（下一轮）
- 3 轮后仍未解决 → 向用户说明剩余问题和限制 → 更新 memory 标注"已搁置"

### 验证记录模板

每轮修复后更新 `_task_state.md`：
```markdown
## 验证记录

### 第 1 轮
- 用户反馈: [问题描述]
- 问题分类: [类型]
- 修复: [修复方式]
- 验证: [自动验证结果]
- 结果: 已重新打包
```

---

## 重要原则

1. **Coordinator 不写代码** — 模块实现和审查全部通过 sub-agent 完成，Coordinator 只做编排和门控
2. **小而美** — 功能少但精，> 15 模块强制精简
3. **编译是 Coordinator 的责任** — 每个 sub-agent 完成后，Coordinator 亲自编译确认
4. **状态更新是 Coordinator 的责任** — sub-agent 不碰 _task_state.md 和 git
5. **批次交付，增量验证** — 不要一口气写完所有模块再验证
6. **双层状态持久化** — `_task_state.md` 存详细状态（模块级），Claude Code memory 存进度快照（跨对话恢复）
7. **测试通过 = 用户说 OK** — 自动验证只是预筛，用户确认才是终点
8. **快速失败，优雅降级** — Implementor 5 轮编译失败则简化实现，不卡住流水线
