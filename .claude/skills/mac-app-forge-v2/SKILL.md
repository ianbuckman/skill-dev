---
name: mac-app-forge-v2
description: 从创意到 .dmg 的全自动 macOS 应用构建流水线（v2 — 含 7 个反衰减 pattern）。当用户说"帮我做个 Mac app""做个桌面应用""build a macOS app""我想要一个能...的工具""做个 menu bar 小工具""帮我做个...的 Mac 软件""forge an app""造个 app"等时触发。也适用于用户描述了一个工具需求、痛点或创意，暗示可以做成 macOS 桌面应用的场景。本 skill 覆盖从构思→技术方案→编码→测试→打包 .dmg→使用手册的完整流程，交付物是一个可安装的 .dmg 文件和使用说明。即使用户只是说"这个能不能做成个 app"，也应该触发。注意：本 skill 用于创建新的 macOS 应用，不用于修改已有项目（已有项目请直接在项目中工作）。
---

# Mac App Forge v2 — CIV 架构全自动流水线

将一句话需求变成可安装的 macOS 应用。采用 Coordinator-Implementor-Verifier (CIV) 三层架构 + 7 个反衰减 pattern，通过 sub-agent 隔离和 Task 依赖链确保长任务全程合规。

## 环境要求

- macOS（M1/M2/M3/M4 系列推荐）
- Xcode Command Line Tools（`xcode-select --install`）
- 可选：`create-dmg` (`brew install create-dmg`)，若未安装则 fallback 到 `hdiutil`

---

## Pipeline Overview

<!-- PATTERN 1: Five-node chain (Gate-Log-Phase-Log-Memory) shown explicitly in diagram -->

```
用户输入（一句话需求）
    ↓
[Phase 1] 创意细化 → phase1_concept.md + 创建全部 Tasks
    ↓
Gate 2 → Log → [Phase 2] 技术方案 → Log → Memory
    ↓
Gate 3 → Log → [Phase 3] 脚手架生成 → Log → Memory
    ↓
Gate 4 → Log → [Phase 4] CIV 编码循环（按批次）→ Log → Memory
    ↓
Gate 5 → Log → [Phase 5] 集成验证 → Log → Memory
    ↓
Gate 6 → Log → [Phase 6] 打包发布 → Log → Memory
    ↓
[Phase 7] 交付与用户验证 ← 反馈循环（最多 3 轮）
    ↓
交付确认 ✅
```

---

## CIV 核心架构

<!-- EVIDENCE: SnapCraft 单 agent 模式下 26 模块 1 commit 11 分钟，所有 per-module compile+commit 规则被无视。
     CIV 通过物理隔离 context 阻止这种行为。 -->

```
┌────────────────────────────────────────────────┐
│              Coordinator（你自己）                │
│  • 全局编排、状态管理、门控决策                      │
│  • 通过 Task 系统追踪进度，决定下一步做什么          │
│  • 执行 swift build / git commit / 状态更新        │
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
│  │ • 不碰 Task  │  │   陷阱清单   │           │
│  └──────────────┘  └──────────────┘           │
└────────────────────────────────────────────────┘
```

### 为什么用 CIV

| 问题 | 旧架构（自管理） | CIV 架构 |
|------|---------------|---------|
| LLM 跳过中间步骤 | Coordinator 和 Implementor 是同一个 agent，可自由跳步 | Coordinator 控制流程，Implementor 无法跳过 |
| 上下文过长导致规则遗忘 | 写到第 15 个模块时早期规则已衰减 | 每个 sub-agent 获得新鲜 context |
| 自己审查自己 | 写代码和审查代码是同一个 agent | Verifier 独立于 Implementor |
| 状态更新被跳过 | LLM 可以选择不更新状态文件 | Task 系统由运行时持续提醒 |

### Coordinator 职责边界（严格遵守）

**Coordinator 做的事：**
- 管理 Tasks（TaskCreate / TaskUpdate）追踪所有 Phase 和模块进度
- 执行 `swift build` / `npm run build`
- 执行 `git add` + `git commit`
- 启动 Implementor 和 Verifier sub-agents
- 运行功能验证脚本
- 决定是否进入下一步或回退修复

**Coordinator 不做的事：**
- ❌ 不自己写模块实现代码（全部委托给 Implementor sub-agent）
- ❌ 不自己做代码审查（全部委托给 Verifier sub-agent）

**唯一例外**：
- Phase 3 脚手架代码可以由 Coordinator 直接完成
- **Warning/Info** 级别的小型修复（< 20 行）可以由 Coordinator 直接完成
- **Critical 级别问题必须委托给 Implementor sub-agent，无论修复大小**

---

## Anti-Decay Enforcement Rules

<!-- 这 7 条规则是从 FloatTodo/ClipVault 构建审计中提炼的结构性要求。不是建议，是硬性规则。 -->

### Pattern 1: Phase-Gate-Log 链

<!-- EVIDENCE: FloatTodo _forge_log.md 前半段完整，后半段缺 Phase 2/5/6 Complete 和 Gate 6 记录。
     日志追加仅是文本指令，无结构性强制。 -->

**规则**：每个 Phase 转场必须经过五节点链：Gate Task → Log Task → Phase Task → Log Task → Memory Task。

**强制机制**：
- Task `blockedBy` 依赖链使下游 Task 在上游未完成前显示为 blocked
- Log Task 的完成条件包含 `Grep _forge_log.md confirm entry exists`
- Coordinator 必须调用 Grep 工具并看到匹配结果后，才可标记 Log Task 为 completed

### Pattern 2: CIV Sub-Agent 隔离

（见上方 CIV 架构部分）

### Pattern 3: 目标不可变门控

<!-- EVIDENCE: FloatTodo click-through 功能被 Coordinator 直接移除，未询问用户。
     phase1_concept.md 标注"不可修改"但无执行机制。 -->

**规则**：phase1_concept.md 创建后不可修改。如有功能需降级、简化或移除，**必须调用 `mcp__conductor__AskUserQuestion`** 获得用户授权。

**强制机制**：
- Phase 转场协议要求对照 phase1_concept.md 核查所有功能仍在计划中
- Verifier sub-agent（新鲜 context）独立检查功能完整性，缺失/降级标为 Critical
- Critical 触发 `addBlockedBy`，阻止 Phase 继续
- AskUserQuestion 是阻塞式工具调用——管线在用户响应前无法继续

### Pattern 4: 批次硬阻塞检查点

<!-- EVIDENCE: SnapCraft 26 模块无检查点，全部一次性生成。 -->

**规则**：模块总数 > 5 时，分批执行。每批结束后 Coordinator 必须调用 `mcp__conductor__AskUserQuestion` 阻塞等待用户确认。

**强制机制**：
- Batch N+1 的 Task 通过 `blockedBy` 依赖 Checkpoint Task
- Checkpoint Task 要求 AskUserQuestion 工具调用（不是文本输出）
- 用户选择"有问题" → 在当前批次内修复后重新 AskUserQuestion

### Pattern 5: Verifier 作为衰减探测器

<!-- EVIDENCE: FloatTodo ARCHITECTURE.md 仍描述已移除的 isClickThrough；CLAUDE.md 写 WindowGroup 但代码已改为 Window。 -->

**规则**：Verifier sub-agent 在新鲜 context 中运行，强制检查以下衰减信号：
1. 实现完整性 vs phase1_concept.md（Pattern 3 的第二道防线）
2. 文档-代码一致性（ARCHITECTURE.md / CLAUDE.md vs 实际代码）
3. 审计日志完整性

**强制机制**：
- Verifier 是 sub-agent，context 不受长任务衰减影响
- Critical 发现触发 `addBlockedBy`，创建新验证 Task 阻止 Phase 继续
- Coordinator 不得在有未完成验证 Task 时标记当前 Phase 为 completed

### Pattern 6: 早期工具检测

<!-- EVIDENCE: FloatTodo 有 swiftui-pro、swift-concurrency-pro 可用但从未检测或调用。 -->

**规则**：Gate 2 必须检测可用专业 skills 并记录结果。结果注入后续所有 sub-agent prompt。

**强制机制**：
- Gate 2 Task description 硬编码检测步骤
- 检测结果写入 _forge_log.md，由 Log Task 的 Grep 验证确认
- Implementor/Verifier prompt 模板包含 `[injected: 可用 skills]` 字段

### Pattern 7: 对话恢复协议

<!-- EVIDENCE: FloatTodo 对话中断后 memory 停留 Phase 3，实际已到 Phase 4+。 -->

**规则**：检测到 forge-*-progress memory 时，必须执行 6 步恢复序列（见 Recovery Protocol 部分）。

**强制机制**：
- 每个 Gate Task description 包含 "如 memory 阶段与 TaskList 不符，以 TaskList 为准更新 memory"
- TaskList 由运行时维护，不受 LLM 衰减影响

---

## 专业 Skill 编排

| Skill | 阶段 | 职责 | 未安装时 Fallback |
|-------|------|------|-------------------|
| /swiftui-pro | Phase 4 (Verifier) | SwiftUI 审查 | references/macos-patterns.md |
| /swift-concurrency-pro | Phase 4 (Verifier) | 并发正确性 | macos-patterns.md fallback 段 |
| /swift-testing-pro | Phase 5 | 关键模块测试 | 跳过（功能验证仍执行） |
| /swift-api-design-guidelines-skill | Phase 4 (Implementor) | API 命名 | 跳过 |
| /swiftdata-pro | Phase 4 (Verifier) | SwiftData 审查 | 跳过 |
| /review | Phase 5 | 结构性审查 | 内置陷阱扫描 |

**检测方式**：Gate 2 强制执行检测，结果记录在 _forge_log.md。后续 Verifier/Implementor prompt 中注入可用 skills 列表。

---

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
1. 核心功能模块放第一批（让用户尽早验证核心价值）
2. 有依赖关系的模块放同一批
3. UI 模块和其依赖的 Service 模块放同一批

---

## 长任务韧性机制

本流水线可能跨越数百次工具调用甚至多个对话 session，以下四层机制协同防止偏离：

### 第一层：Task 系统 — 运行时级进度追踪（平台强制）

利用 Claude Code 内置的 Task 系统（TaskCreate / TaskUpdate）管理所有进度。**Task 列表在 system context 中持续可见，且运行时会主动提醒更新**。

**Task 初始化时机**：Phase 1 完成后，Coordinator 创建全部 Phase 级 Tasks（含 Gate + Log 节点）。Phase 4 开始前（Gate 4 完成条件），创建全部模块级 Tasks + 批次级 Tasks。

**Task 更新时机**：
1. 进入新 Phase → 将对应 Task 标记为 `in_progress`
2. 完成当前 Phase → 标记为 `completed`
3. 完成一个模块 → 标记为 `completed`
4. 遇到问题需要回退 → 在 Task 描述中追加说明

**只有 Coordinator 操作 Tasks，sub-agent 不碰。**

### 第二层：Claude Code Memory — 跨对话恢复（自动加载）

**Memory 写入时机（Coordinator 在以下节点执行）：**

1. **Phase 1 完成后** — 保存 memory：
   ```markdown
   ---
   name: forge-[AppName]-progress
   description: mac-app-forge-v2 正在构建 [AppName]，当前进度 Phase [N]
   type: project
   ---
   正在构建: [AppName] — [一句话描述]
   项目路径: [path]
   当前阶段: Phase [N]
   技术栈: [tech]
   phase1_concept.md 位置: [path]/phase1_concept.md
   ```

2. **每个批次完成后** — 更新同一个 memory 文件的 `当前阶段` 和进度

3. **每次 Phase 转场时** — 更新 memory

4. **交付完成后** — 删除该 memory（项目结束）

### 第三层：文件接力

| Phase | 输入文件 | 输出文件 |
|-------|---------|---------|
| 1 | 用户输入 | phase1_concept.md |
| 2 | phase1_concept.md | ARCHITECTURE.md |
| 3 | ARCHITECTURE.md | 项目骨架 + CLAUDE.md |
| 4 | ARCHITECTURE.md + CLAUDE.md | 模块代码 |
| 5 | phase1_concept.md | phase5_build_report.md |
| 6 | phase5_build_report.md | .dmg + README.md |
| 7 | .dmg + README.md | 用户确认 |

### 第四层：执行审计日志（`_forge_log.md`）

Coordinator 在每个 Gate 完成和 Phase 完成时，向项目目录的 `_forge_log.md` 追加一条记录：

```
## [Gate N / Phase N Complete / Batch N Checkpoint]
- 读取: [文件列表及关键事实，如"phase1_concept.md: App=DeskPet, 3 core features"]
- 进度: [已完成/待完成摘要]
- 时间: [当前时间]
```

此文件为**追加写入（append-only）**，不删除已有条目。

### 编译输出压缩

输出超 50 行用 `2>&1 | tail -30`。成功时只记"编译成功，0 errors，N warnings"。

### Phase 转场协议

**进入新 Phase 时（强制）：**
1. 重读 `phase1_concept.md`（不可变目标）+ 上一阶段输出文件
2. 对照 phase1_concept.md 核心功能列表，确认所有功能仍在计划中。如有功能被降级、简化或移除，**必须调用 mcp__conductor__AskUserQuestion** 获得用户授权后才能继续 <!-- PATTERN 3 -->
3. 用 TaskList 检查当前进度，确认与 memory 一致（不一致则以 TaskList 为准，更新 memory）<!-- PATTERN 7 -->
4. TaskUpdate 将当前 Phase Task 标记为 `in_progress`

**完成当前 Phase 时（强制）：**
1. 写入产出文件
2. TaskUpdate → `completed`
3. 更新 memory（forge-[AppName]-progress）
4. 一句话汇报

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

4. 用户确认后，写入 `phase1_concept.md`
5. 检测可用专业 skills：检查系统中可用的 skills 列表（对照：swiftui-pro, swift-concurrency-pro, swift-testing-pro, swift-api-design-guidelines-skill, swiftdata-pro, review），将结果记录到 _forge_log.md <!-- PATTERN 6 -->
6. 创建 **Gate-Log-Phase-Log-Memory 五节点依赖链** Tasks：

```
TaskCreate: "Gate 2: 读取 phase1_concept.md + 检测专业 skills"
  description: "1. Read phase1_concept.md 2. TaskList 确认进度（如 memory 与 TaskList 不符以 TaskList 为准）3. 确认 skills 检测结果已在 _forge_log.md 4. 标记完成"

TaskCreate: "Log: Gate 2" (blockedBy: Gate 2)
  description: "1. 追加 _forge_log.md（Gate 2 记录）2. Grep _forge_log.md 确认包含 'Gate 2' 条目 3. 标记完成"

TaskCreate: "Phase 2: 技术方案 → ARCHITECTURE.md" (blockedBy: Log Gate 2)

TaskCreate: "Log: Phase 2 Complete" (blockedBy: Phase 2)
  description: "1. 追加 _forge_log.md（Phase 2 Complete）2. Grep 确认 3. 标记完成"

TaskCreate: "Memory: Phase 2" (blockedBy: Log Phase 2)
  description: "更新 forge-[AppName]-progress memory 到 Phase 3。标记完成。"

TaskCreate: "Gate 3: 读取 phase1_concept.md + ARCHITECTURE.md" (blockedBy: Memory 2)
  description: "1. Read phase1_concept.md + ARCHITECTURE.md 2. TaskList + memory 核对 3. 标记完成"

TaskCreate: "Log: Gate 3" (blockedBy: Gate 3)
  description: "1. 追加 _forge_log.md（Gate 3）2. Grep 确认 3. 标记完成"

TaskCreate: "Phase 3: 脚手架生成" (blockedBy: Log Gate 3)

TaskCreate: "Log: Phase 3 Complete" (blockedBy: Phase 3)
  description: "同上 pattern"

TaskCreate: "Memory: Phase 3" (blockedBy: Log Phase 3)

TaskCreate: "Gate 4: 读取设计文档 + 创建编码 Tasks" (blockedBy: Memory 3)
  description: "1. Read phase1_concept.md + ARCHITECTURE.md + CLAUDE.md 2. 为每个模块创建 Task 3. 为每个批次创建 Batch Verifier + Checkpoint + Memory Tasks（用 blockedBy 串联）4. TaskList 确认所有 batch Tasks 已创建 5. 标记完成"

TaskCreate: "Log: Gate 4" (blockedBy: Gate 4)
  description: "同上 pattern"

TaskCreate: "Phase 4: 编码实现" (blockedBy: Log Gate 4)

TaskCreate: "Log: Phase 4 Complete" (blockedBy: Phase 4)
  description: "同上 pattern"

TaskCreate: "Memory: Phase 4" (blockedBy: Log Phase 4)

TaskCreate: "Gate 5: 读取 phase1_concept.md + 验证准备" (blockedBy: Memory 4)
  description: "1. Read phase1_concept.md + ARCHITECTURE.md 2. TaskList + memory 核对 3. 标记完成"

TaskCreate: "Log: Gate 5" (blockedBy: Gate 5)
  description: "同上 pattern"

TaskCreate: "Phase 5: 集成验证" (blockedBy: Log Gate 5)

TaskCreate: "Log: Phase 5 Complete" (blockedBy: Phase 5)
  description: "同上 pattern"

TaskCreate: "Memory: Phase 5" (blockedBy: Log Phase 5)

TaskCreate: "Gate 6: 读取 phase1_concept.md + phase5_build_report.md" (blockedBy: Memory 5)
  description: "1. Read phase1_concept.md + phase5_build_report.md 2. TaskList + memory 核对 3. 标记完成"

TaskCreate: "Log: Gate 6" (blockedBy: Gate 6)
  description: "同上 pattern"

TaskCreate: "Phase 6: 打包发布 → .dmg + README.md" (blockedBy: Log Gate 6)

TaskCreate: "Log: Phase 6 Complete" (blockedBy: Phase 6)
  description: "同上 pattern"

TaskCreate: "Phase 7: 交付与用户验证" (blockedBy: Log Phase 6)
```

<!-- 关键：每个 Gate description 包含 "如 memory 与 TaskList 不符以 TaskList 为准" — PATTERN 7 -->
<!-- 关键：Gate 4 description 包含批次 Task 创建 — PATTERN 4 enforcement -->

**Log Task 完成条件（硬性，不可跳过）**：
1. Coordinator 追加一条审计记录到 `_forge_log.md`
2. Coordinator 用 `Grep` 工具搜索 `_forge_log.md` 确认刚写入的条目存在
3. Grep 返回匹配结果后，才可标记 Log Task 为 completed
4. **下游 Phase Task 在 Log Task 未完成前显示为 blocked**

**Memory Task 完成条件**：Coordinator 更新 `forge-[AppName]-progress` memory 文件后标记为 completed。

7. 创建 Claude Code memory `forge-[AppName]-progress`
8. 创建 `_forge_log.md` 审计日志文件

### 关键原则
- 小而精，功能 3-5 个，不膨胀
- 如果用户需求暗示 > 15 个模块，在此阶段就协商精简
- 未指定则默认 Menu Bar App

### phase1_concept.md 模板

```markdown
# App Concept — [App Name]

## 目标（创建后不可修改）
- App 名称: [name]
- 一句话描述: [description]
- 核心功能:
  1. [功能1]
  2. [功能2]
  3. [功能3]
- App 类型: [类型]
- 目标用户: [target users]
- 项目路径: [path]
```

---

## Phase 2: 技术方案

### 转场读取
- 重读 `phase1_concept.md` 目标区
- 对照功能列表确认无偏离 <!-- PATTERN 3 -->
- TaskList + memory 核对 <!-- PATTERN 7 -->
- TaskUpdate: Phase 2 → `in_progress`

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
验证标准: [具体的可验证行为]
```

每个批次必须附带**可执行的验证标准**。

### 转场写入
TaskUpdate: Phase 2 → `completed`。更新 memory。

---

## Phase 3: 脚手架生成

### 转场读取
- 重读 `phase1_concept.md` + `ARCHITECTURE.md` + `references/scaffold-[tech].md`
- 对照功能列表确认无偏离 <!-- PATTERN 3 -->
- TaskUpdate: Phase 3 → `in_progress`

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
TaskUpdate: Phase 3 → `completed`。

---

## Phase 4: CIV 编码循环

**最长阶段。Coordinator 绝不自己写模块代码，全部通过 sub-agent 完成。**

### 转场读取
- 重读 `phase1_concept.md` + `ARCHITECTURE.md`（完整，含模块清单和批次计划）
- 读取项目 `CLAUDE.md`
- 对照功能列表确认无偏离 <!-- PATTERN 3 -->
- TaskList + memory 核对 <!-- PATTERN 7 -->
- TaskUpdate: Phase 4 → `in_progress`
- TaskList 确认模块 Tasks 和批次 Tasks 已存在（Gate 4 应已创建）。如缺失立即补创建。 <!-- PATTERN 4 enforcement -->

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

## 可用专业 Skills
[injected: 从 _forge_log.md 读取的 Gate 2 检测结果]

## 要求
1. 只实现 [模块名] 的代码，不要修改其他模块
2. 读取依赖模块的接口（如果有），确保调用方式正确
3. 写完后运行 `swift build 2>&1 | tail -30` 确认编译通过
4. 如果编译失败，修复错误后重新编译（最多 5 轮）
5. 5 轮后仍失败，简化实现并说明简化了什么
6. 不要操作 Tasks（TaskCreate / TaskUpdate 等）
7. 不要执行 git commit
```

**注意**：如果两个模块之间没有依赖关系，可以并行启动两个 Implementor sub-agent。

**1b. Coordinator 编译验证**

```bash
swift build 2>&1 | tail -30
```

编译失败 → 启动新的 Implementor sub-agent 修复（最多 3 轮）。3 轮后标记 ⚠️ 继续。

**1c. Coordinator commit + 更新进度**

```bash
git add [该模块的文件]
git commit -m "M{N}: [模块名]"
```

TaskUpdate: `M{N}: [模块名]` → `completed`

#### Step 2: 批次验证（Verifier sub-agent）

当前批次所有模块实现完毕后，启动 Verifier sub-agent：

```
你是一个 macOS 应用代码审查专家。审查以下模块的实现质量。

## 审查范围
本批次模块: [列出文件路径]
架构设计: [从 ARCHITECTURE.md 摘取本批次模块的设计]

## 可用专业 Skills
[injected: 从 _forge_log.md 读取的 Gate 2 检测结果]           <!-- PATTERN 6 -->
对于 SwiftUI 代码，调用 /swiftui-pro 审查。
对于并发代码，调用 /swift-concurrency-pro 审查。
对于 SwiftData 代码，调用 /swiftdata-pro 审查。
未安装的 skill 使用 references/ 目录下的 fallback 文档。

## 审查清单
1. 每个模块是否实现了 ARCHITECTURE.md 中描述的全部功能？列出缺失项。
2. 模块间的调用关系是否正确？参数类型、返回值是否匹配？
3. 检查 references/macos-patterns.md 中的运行时陷阱（逐项检查）：
   [粘贴完整陷阱清单]
4. 是否有明显的逻辑错误（如空函数体、未连接的回调、永远为 false 的条件）？
5. 异步代码是否正确使用 @MainActor？是否有潜在的数据竞争？
6. 对照 phase1_concept.md 核心功能列表，是否有功能被省略、简化或 stubbed out？
   列出每个功能实现状态: ✅完整 / ⚠️简化 / ❌缺失                <!-- PATTERN 3 -->

## 输出格式
对每个发现的问题：
- 文件: [路径]
- 行号: [行号范围]
- 问题: [描述]
- 严重度: [Critical / Warning / Info]
- 建议修复: [代码片段]
```

Verifier 返回后，Coordinator 处理：
- **Critical**: 必须启动 Implementor sub-agent 修复。**无例外。** 修复后必须重新启动 Verifier 确认。
- **Warning**: 小修复 (< 20 行) Coordinator 直接做。大修复委托 Implementor。
- **Info**: 记录但不阻塞。

#### Step 3: 批次功能验证

Coordinator 运行编译 + 启动测试：

```bash
# 编译
swift build -c release 2>&1 | tail -10

# 启动测试（5 秒超时）
timeout 5 .build/release/[AppName] 2>&1 || true
```

#### Step 4: 批次间用户检查点（硬阻塞）<!-- PATTERN 4 -->

**如果项目模块总数 > 5 且还有后续批次：**

Coordinator **必须调用 `mcp__conductor__AskUserQuestion` 工具**阻塞执行。

**不要用普通文本输出代替 AskUserQuestion。不要在用户响应前继续下一批次。**

AskUserQuestion 内容：
- 本批次完成的模块列表及状态
- 编译状态和 Verifier 审查结果摘要
- 本批次的验证标准（供用户手动验证）
- 选项："继续下一批" / "有问题需要修复"

**Task 依赖保障**（应在 Gate 4 时已创建）：
```
TaskCreate: "Batch 1 Verifier 审查" (blockedBy: [batch 1 所有模块])
TaskCreate: "Checkpoint: Batch 1 用户确认" (blockedBy: Batch 1 Verifier)
TaskCreate: "Memory: Batch 1 完成" (blockedBy: Checkpoint)
TaskCreate: "M6: ..." (blockedBy: Memory Batch 1)
```

#### Step 5: 全量编译（最后一个批次完成后）

```bash
swift build -c release 2>&1 | tail -30
```

TaskUpdate: Phase 4 → `completed`。

---

## Phase 5: 集成验证

**编译通过 ≠ 能正常运行。**

### 转场读取
- 重读 `phase1_concept.md` 目标区和核心功能列表
- 读取 `ARCHITECTURE.md`
- 对照功能列表确认无偏离 <!-- PATTERN 3 -->
- TaskList + memory 核对 <!-- PATTERN 7 -->
- TaskUpdate: Phase 5 → `in_progress`

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
swift build -c release 2>&1 | tail -30
```

编译失败 → 启动 Implementor sub-agent 修复 → 重新编译（最多 5 轮）

### Step 2: 启动与功能验证

```bash
.build/release/[AppName] &
APP_PID=$!
sleep 5
if kill -0 $APP_PID 2>/dev/null; then
    echo "✅ 启动测试通过 (PID: $APP_PID)"
else
    echo "❌ 启动崩溃"
    ls -lt ~/Library/Logs/DiagnosticReports/ 2>/dev/null | head -5
fi
```

崩溃 → 读取日志 → Implementor sub-agent 修复 → 回到 Step 1

### Step 2.5: 关键模块测试（Swift 路线，可选）

调用 /swift-testing-pro 为关键 Service 模块编写测试，运行 `swift test`。
> 未安装时跳过。

### Step 3: 集成审查（Verifier sub-agent）

```
你是一个 macOS 应用审查专家。对完整项目做集成审查。

## 审查范围
项目路径: [path]
读取所有源代码文件。

## 可用专业 Skills
[injected: 从 _forge_log.md 读取的 Gate 2 检测结果]           <!-- PATTERN 6 -->

## 审查清单

### A. macOS 运行时陷阱（逐项检查，见 references/macos-patterns.md）
[粘贴完整陷阱清单]

### B. 集成正确性
1. App 入口 (@main) 是否正确注入了所有需要的 environment 对象？
2. 所有 Service 是否被正确初始化并持有引用（不是局部变量）？
3. 所有 UI 操作的回调链是否完整连通？
4. 所有异步操作是否有错误处理？

### C. 功能完整性
对照以下核心功能清单，检查每个功能的代码路径是否完整：
[粘贴 phase1_concept.md 的核心功能列表]
对每个功能: "代码路径完整" 或 "断裂在 [具体位置]"
如果有功能被移除或降级，在 Critical 列表中标记为"目标偏离: [功能名]" <!-- PATTERN 3 -->

### D. 文档-代码一致性                                        <!-- PATTERN 5 -->
对照实际代码检查：
1. ARCHITECTURE.md — 模块列表、API 名称、数据流描述是否与代码匹配？已移除或重命名的内容标为 Critical。
2. CLAUDE.md — 编码规则、API 引用是否与当前代码一致？过时内容标为 Warning。
3. README.md（如已存在）— 功能描述是否与实际行为匹配？

## 输出格式
1. Critical 问题列表（必须修复）
2. Warning 列表（建议修复）
3. 功能完整性评估表
4. 文档一致性评估
```

发现 Critical → **二次验证强制机制**：

1. Coordinator 创建新 Task：`TaskCreate: "验证轮次 [N+1]: Critical 修复后重新验证"`
2. 将此 Task 设为 Phase 5 完成的前置依赖（`addBlockedBy`）
3. 委托 Implementor sub-agent 修复（**Critical 必须走 sub-agent**）
4. 修复 + 编译通过后，启动新 Verifier 重新审查
5. Verifier 无 Critical → 标记验证轮次 Task 为 completed

**Coordinator 不得在有未完成的验证轮次 Task 时标记 Phase 5 为 completed。**

### Step 4: 生成验证清单

已自动验证通过的项标注为 ✅，无法自动验证的标注为 ⬜ 需手动验证。

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
- 文档一致性: [已同步/有偏差]
- 验证轮次: X/3

## 手动验证清单
- [ ] [无法自动验证的功能]
```

TaskUpdate: Phase 5 → `completed`。

---

## Phase 6: 打包发布

### 转场读取
- 重读 `phase1_concept.md` 目标区
- 读取 `phase5_build_report.md`
- 读取 ARCHITECTURE.md + 项目 CLAUDE.md，对照当前代码确认文档准确。过时内容先更新再打包。 <!-- PATTERN 5 -->
- TaskList + memory 核对 <!-- PATTERN 7 -->
- TaskUpdate: Phase 6 → `in_progress`

### 打包流程
读取 `references/packaging-guide.md`。

**Swift**: release build → .app bundle 组装 → 图标生成（`references/icon-generation.md`）→ .dmg
**Electron**: `npx electron-builder --mac dmg`

### DMG 验证
1. `hdiutil attach` 验证可挂载
2. .app 存在
3. 记录文件大小

### 生成 README.md
重读 `phase1_concept.md` 目标区，确保覆盖所有功能。
包含：安装方法、使用方法（每个核心功能一节）、快捷键、数据存储位置、卸载方法。

### 转场写入
TaskUpdate: Phase 6 → `completed`。git commit。

---

## Phase 7: 交付与用户验证循环

### 首次交付

TaskUpdate: Phase 7 → `in_progress`。

向用户报告：
```
✅ Mac App Forge v2 初版完成！

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

**Step 1: 问题分类**

重读 `phase1_concept.md` 目标区，分析问题类型：

| 问题类型 | 处理方式 |
|---------|---------|
| 代码 Bug | Implementor sub-agent 修复 |
| UI/交互问题 | Implementor sub-agent 修改 View |
| 架构缺陷 | 回退 Phase 2 修订 |
| 功能缺失 | 回退 Phase 1 确认变更 |
| 环境问题 | 更新 README |

**Step 2: 修复**
1. Implementor sub-agent 修复
2. Coordinator 编译验证
3. Verifier sub-agent 确认
4. Coordinator commit + 重新打包

**Step 3: 重新交付**

```
🔧 修复完成（第 N 轮）

修复内容：
- [问题1]: [修复方式]

📦 新安装包: [路径]/dist/[AppName].dmg
请重新安装并验证。
```

**Step 4: 循环判断**
- 用户说 OK → ✅ → TaskUpdate: Phase 7 → `completed` → 删除 memory
- 还有问题 → 回到 Step 1
- 3 轮后未解决 → 说明限制 → memory 标注"已搁置"

---

## Recovery Protocol

<!-- PATTERN 7: Conversation recovery — TaskList is the single authoritative source -->

**当新对话检测到 forge-*-progress memory 时，必须立即执行：**

1. **TaskList** — 获取所有 Tasks 的当前状态（**唯一权威进度源**）
2. **Read phase1_concept.md** — 恢复项目目标
3. **Read ARCHITECTURE.md** — 恢复技术上下文
4. **对比** memory 阶段 vs TaskList 实际阶段：
   - 一致 → 继续当前 Phase
   - 不一致 → **以 TaskList 为准**，立即更新 memory
5. **Read _forge_log.md** — 确认最后记录与 TaskList 一致
6. **从当前 Phase 对应的 Gate Task 重新开始**

```
⚠️ 原则：TaskList 是唯一权威进度源。
   Memory 和 _forge_log.md 是辅助参考。三者不一致时以 TaskList 为准。
```

---

## 重要原则

1. **Coordinator 不写代码** — 模块实现和审查全部通过 sub-agent 完成
2. **小而美** — 功能少但精，> 15 模块强制精简
3. **编译是 Coordinator 的责任** — 每个 sub-agent 完成后 Coordinator 亲自编译确认
4. **状态更新是 Coordinator 的责任** — sub-agent 不碰 Tasks 和 git
5. **批次交付，增量验证** — 不要一口气写完所有模块再验证
6. **四层韧性** — Task 依赖链（五节点强制顺序）+ Memory（跨对话恢复）+ 文件接力 + 审计日志（_forge_log.md + Grep 验证）
7. **测试通过 = 用户说 OK** — 自动验证只是预筛，用户确认才是终点
8. **快速失败，优雅降级** — Implementor 5 轮编译失败则简化实现，不卡住流水线
9. **重要的规则必须结构性强制执行，不能靠自律** — 如果规则只是文本建议，LLM 在长任务后半段会跳过它
