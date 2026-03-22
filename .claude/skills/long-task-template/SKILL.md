<!-- TEMPLATE: Copy this file to .claude/skills/[your-skill]/SKILL.md and fill in all [FILL] placeholders -->
---
name: [FILL: skill-name]
description: [FILL: trigger description — include "long-task pipeline" somewhere for LLM context]
---

# [FILL: Skill Name] — Long-Task Pipeline

[FILL: one-sentence purpose — what the pipeline produces from what input]

采用 Coordinator-Implementor-Verifier (CIV) 三层架构，通过 sub-agent 隔离和 Task 依赖链确保长任务全程合规。

## 环境要求

- [FILL: runtime requirements, e.g., macOS + Xcode CLI, Node.js, Docker, etc.]

---

## Pipeline Overview

<!-- PATTERN 1: Five-node chain (Gate-Log-Phase-Log-Memory) shown explicitly in diagram -->

```
用户输入
    ↓
[Phase 1] [FILL: 创意/需求细化] → [FILL: concept_doc]
    ↓
Gate 2 → Log → [Phase 2] [FILL: 设计/方案] → Log → Memory
    ↓
Gate 3 → Log → [Phase 3] [FILL: 初始化/脚手架] → Log → Memory
    ↓
Gate 4 → Log → [Phase 4] [FILL: 实现]（按批次，CIV 循环）→ Log → Memory
    ↓
Gate 5 → Log → [Phase 5] [FILL: 验证/测试] → Log → Memory
    ↓
Gate 6 → Log → [Phase 6] [FILL: 打包/发布] → Log → Memory
    ↓
[Phase 7] [FILL: 交付/用户验证] ← 反馈循环
    ↓
交付确认 ✅
```

[FILL: 根据实际需要增删 Phase。最少 4 Phase（概念→实现→验证→交付），最多 8 Phase。]

---

## CIV 核心架构

<!-- EVIDENCE: SnapCraft 单 agent 模式下 26 模块 1 commit 11 分钟，所有 per-module compile+commit 规则被无视。
     CIV 通过物理隔离 context 阻止这种行为。 -->

```
┌────────────────────────────────────────────────┐
│              Coordinator（你自己）                │
│  • 全局编排、状态管理、门控决策                      │
│  • 通过 Task 系统追踪进度                          │
│  • 执行构建/编译、git commit、状态更新              │
│  • 绝不自己写实现代码（委托给 Implementor）           │
├──────────┬─────────────────┬───────────────────┤
│          ▼                 ▼                   │
│  ┌──────────────┐  ┌──────────────┐           │
│  │ Implementor  │  │  Verifier    │           │
│  │ (sub-agent)  │  │ (sub-agent)  │           │
│  │              │  │              │           │
│  │ • 只实现 1 个 │  │ • 独立审查   │           │
│  │   工作单元    │  │ • 检查衰减   │           │
│  │ • 隔离context │  │ • 核查目标   │           │
│  │ • 不碰 Task  │  │ • 不改代码   │           │
│  └──────────────┘  └──────────────┘           │
└────────────────────────────────────────────────┘
```

### 为什么用 CIV

| 问题 | 单 Agent | CIV |
|------|---------|-----|
| LLM 跳过中间步骤 | 可自由跳步 | Coordinator 控制流程，Implementor 无法跳过 |
| Context 过长规则遗忘 | 后半段规则衰减 | 每个 sub-agent 获得新鲜 context |
| 自己审查自己 | 写和审是同一个 agent | Verifier 独立于 Implementor |
| 状态更新被跳过 | LLM 可选择不更新 | Task 系统由运行时持续提醒 |

### Coordinator 职责边界

**Coordinator 做的事：**
- 管理 Tasks（TaskCreate / TaskUpdate）
- 执行构建命令：[FILL: e.g., `swift build`, `npm run build`]
- 执行 `git add` + `git commit`
- 启动 Implementor 和 Verifier sub-agents
- 运行验证脚本
- 决定是否进入下一步或回退

**Coordinator 不做的事：**
- ❌ 不自己写实现代码（全部委托给 Implementor sub-agent）
- ❌ 不自己做代码审查（全部委托给 Verifier sub-agent）

**唯一例外**：
- [FILL: 允许 Coordinator 直接完成的阶段，e.g., Phase 3 脚手架代码]
- Warning/Info 级别的小型修复（< 20 行）Coordinator 可直接完成
- **Critical 级别问题必须委托给 Implementor，无论修复大小**

---

## Anti-Decay Enforcement Rules

<!-- 这 7 条规则是模板的核心。它们是硬编码的结构性要求，不是建议。 -->

### Pattern 1: Phase-Gate-Log 链

<!-- EVIDENCE: FloatTodo _forge_log.md 前半段完整，后半段缺 Phase 2/5/6 Complete 和 Gate 6 记录。
     日志追加仅是文本指令，无结构性强制。 -->

**规则**：每个 Phase 转场必须经过五节点链：Gate Task → Log Task → Phase Task → Log Task → Memory Task。

**强制机制**：
- Task `blockedBy` 依赖链使下游 Task 在上游未完成前显示为 blocked
- Log Task 的完成条件包含 `Grep [FILL: audit_log_name] confirm entry exists`
- Coordinator 必须调用 Grep 工具并看到匹配结果后，才可标记 Log Task 为 completed

### Pattern 2: CIV Sub-Agent 隔离

（见上方 CIV 架构部分）

### Pattern 3: 目标不可变门控

<!-- EVIDENCE: FloatTodo click-through 功能被 Coordinator 直接移除，未询问用户。
     concept doc 标注"不可修改"但无执行机制。 -->

**规则**：[FILL: concept_doc] 创建后不可修改。如有功能需降级、简化或移除，**必须调用 `mcp__conductor__AskUserQuestion`** 获得用户授权。

**强制机制**：
- Phase 转场协议要求对照 concept doc 核查所有功能仍在计划中
- Verifier sub-agent（新鲜 context）独立检查功能完整性，缺失/降级标为 Critical
- Critical 触发 `addBlockedBy`，阻止 Phase 继续
- AskUserQuestion 是阻塞式工具调用——管线在用户响应前无法继续

### Pattern 4: 批次硬阻塞检查点

<!-- EVIDENCE: SnapCraft 26 模块无检查点，全部一次性生成。 -->

**规则**：工作单元总数 > [FILL: checkpoint_threshold, default 5] 时，分批执行。每批结束后 Coordinator 必须调用 `mcp__conductor__AskUserQuestion` 阻塞等待用户确认。

**强制机制**：
- Batch N+1 的 Task 通过 `blockedBy` 依赖 Checkpoint Task
- Checkpoint Task 要求 AskUserQuestion 工具调用（不是文本输出）
- 用户选择"有问题" → 在当前批次内修复后重新 AskUserQuestion

### Pattern 5: Verifier 作为衰减探测器

<!-- EVIDENCE: FloatTodo ARCHITECTURE.md 仍描述已移除的 isClickThrough；CLAUDE.md 写 WindowGroup 但代码已改为 Window。
     无 Verifier 检查捕获文档漂移。 -->

**规则**：Verifier sub-agent 在新鲜 context 中运行，强制检查以下衰减信号：
1. 实现完整性 vs concept doc（Pattern 3 的第二道防线）
2. 文档-代码一致性（architecture doc / project config vs 实际代码）
3. 审计日志完整性

**强制机制**：
- Verifier 是 sub-agent，context 不受长任务衰减影响
- Critical 发现触发 `addBlockedBy`，创建新验证 Task 阻止 Phase 继续
- Coordinator 不得在有未完成验证 Task 时标记当前 Phase 为 completed

### Pattern 6: 早期工具检测

<!-- EVIDENCE: FloatTodo 有 swiftui-pro、swift-concurrency-pro 可用但从未检测或调用。 -->

**规则**：第一个 Gate（Gate 2）必须检测可用的专业 skills 并记录结果。结果注入后续所有 sub-agent prompt。

**强制机制**：
- Gate 2 Task description 硬编码检测步骤（具体工具调用，不是建议）
- 检测结果写入 [FILL: audit_log_name]，由 Log Task 的 Grep 验证确认记录
- Implementor/Verifier prompt 模板包含 `[injected: 可用 skills]` 字段

### Pattern 7: 对话恢复协议

<!-- EVIDENCE: FloatTodo 对话中断后 memory 停留 Phase 3，实际已到 Phase 4+。
     Coordinator 未与 TaskList 对照。 -->

**规则**：检测到 [FILL: progress_memory_pattern] memory 时，必须执行 6 步恢复序列（见 Recovery Protocol 部分）。

**强制机制**：
- 每个 Gate Task description 包含 "如 memory 阶段与 TaskList 不符，以 TaskList 为准更新 memory"
- TaskList 由运行时维护，不受 LLM 衰减影响
- Gate 是 blockedBy 链中的必经节点，Coordinator 无法绕过

---

## 规模控制

**在设计阶段确定工作单元清单后，强制执行：**

| [FILL: 工作单元] 数 | 策略 |
|-------------------|------|
| ≤ [FILL: 5] | 单批交付 |
| [FILL: 6-10] | 分 2 批，每批结束后 AskUserQuestion |
| [FILL: 11-15] | 分 3 批 |
| > [FILL: 15] | **停下来**，向用户说明风险，协商精简 |

**每批不超过 [FILL: 5] 个工作单元。违反此规则的唯一理由是用户明确指示。**

批次划分原则：
1. 核心功能放第一批（让用户尽早验证核心价值）
2. 有依赖关系的工作单元放同一批
3. [FILL: domain-specific batching principles]

---

## 长任务韧性机制

本流水线可能跨越数百次工具调用甚至多个对话，以下四层机制协同防止偏离：

### 第一层：Task 系统 — 运行时级进度追踪（平台强制）

利用 Task 系统（TaskCreate / TaskUpdate）管理所有进度。**Task 列表在 system context 中持续可见，运行时主动提醒更新**。

**Task 初始化时机**：Phase 1 完成后创建全部 Phase 级 Tasks。Phase 4 开始前创建全部工作单元 Tasks + 批次级 Tasks。

**Task 更新时机**：
1. 进入新 Phase → `in_progress`
2. 完成 Phase → `completed`
3. 完成工作单元 → `completed`
4. 遇到问题 → Task 描述追加说明

**只有 Coordinator 操作 Tasks，sub-agent 不碰。**

### 第二层：Claude Code Memory — 跨对话恢复

**Memory 写入时机：**
1. Phase 1 完成后 — 保存：
   ```markdown
   ---
   name: [FILL: progress_memory_pattern]-[ProjectName]-progress
   description: [FILL: skill-name] 正在构建 [ProjectName]，当前 Phase [N]
   type: project
   ---
   正在构建: [ProjectName]
   项目路径: [path]
   当前阶段: Phase [N]
   [FILL: domain-specific fields, e.g., tech stack]
   [FILL: concept_doc] 位置: [path]
   ```
2. 每个批次完成后 — 更新阶段
3. 每次 Phase 转场 — 更新阶段
4. 交付完成后 — 删除 memory

### 第三层：文件接力

每个 Phase 从文件读取输入、把产出写入文件。不依赖对话记忆。

| Phase | 输入文件 | 输出文件 |
|-------|---------|---------|
| 1 | 用户输入 | [FILL: concept_doc] |
| 2 | [FILL: concept_doc] | [FILL: architecture_doc] |
| 3 | [FILL: architecture_doc] | [FILL: project skeleton] |
| 4 | [FILL: architecture_doc] + [FILL: project config] | 实现代码 |
| 5 | [FILL: concept_doc] | [FILL: verification_report] |
| 6 | [FILL: verification_report] | [FILL: final deliverable] |
| 7 | [FILL: final deliverable] | 用户确认 |

### 第四层：执行审计日志（`[FILL: audit_log_name]`）

Coordinator 在每个 Gate 完成和 Phase 完成时追加记录：

```
## [Gate N / Phase N Complete / Batch N Checkpoint]
- 读取: [文件列表及关键事实]
- 进度: [已完成/待完成摘要]
- 时间: [当前时间]
```

**追加写入（append-only）**，不删除。Phase 5 Verifier 审查时检查日志完整性。

### Phase 转场协议

**进入新 Phase 时（强制）：**
1. 重读 [FILL: concept_doc]（不可变目标）+ 上一阶段输出文件
2. 对照 concept doc 核心功能列表，确认所有功能仍在计划中。如有功能偏离，**必须 AskUserQuestion 获得用户授权后才能继续** <!-- PATTERN 3 -->
3. TaskList 检查当前进度，确认与 memory 一致（不一致以 TaskList 为准，更新 memory）<!-- PATTERN 7 -->
4. TaskUpdate 将当前 Phase Task 标记为 `in_progress`

**完成当前 Phase 时（强制）：**
1. 写入产出文件
2. TaskUpdate → `completed`
3. 更新 memory
4. 一句话汇报

---

## Phase 1: [FILL: 概念/需求细化]

### 输入
用户的需求描述。

### 任务
1. 提取核心功能、目标用户、使用场景
2. 补充合理辅助功能（不超过 2-3 个）
3. 展示 Concept 给用户确认
4. 用户确认后写入 [FILL: concept_doc]
5. 检测可用专业 skills：[FILL: 检测命令，e.g., `ls .claude/skills/`]，记录到 [FILL: audit_log_name] <!-- PATTERN 6 -->
6. 创建 **Gate-Log-Phase-Log-Memory 五节点依赖链**：

```
TaskCreate: "Gate 2: 读取 [FILL: concept_doc] + 检测专业 skills"
  description: "1. Read [concept_doc] 2. TaskList 确认进度（如 memory 与 TaskList 不符以 TaskList 为准）3. 检测可用 skills 4. 标记完成"

TaskCreate: "Log: Gate 2" (blockedBy: Gate 2)
  description: "1. 追加 [audit_log]（Gate 2 记录 + skills 检测结果）2. Grep [audit_log] 确认 'Gate 2' 条目存在 3. 标记完成"

TaskCreate: "Phase 2: [FILL]" (blockedBy: Log Gate 2)

TaskCreate: "Log: Phase 2 Complete" (blockedBy: Phase 2)
  description: "1. 追加 [audit_log]（Phase 2 Complete）2. Grep 确认 3. 标记完成"

TaskCreate: "Memory: Phase 2" (blockedBy: Log Phase 2)
  description: "更新 memory 到 Phase 3。标记完成。"

TaskCreate: "Gate 3: 读取 [FILL: concept_doc] + [FILL: architecture_doc]" (blockedBy: Memory 2)
  description: "1. Read [files] 2. TaskList + memory 核对 3. 标记完成"

TaskCreate: "Log: Gate 3" (blockedBy: Gate 3)
  description: "同上 pattern"

[... 对每个 Phase 重复五节点链 ...]

TaskCreate: "Phase 7: [FILL: 交付]" (blockedBy: [FILL: 上游依赖])
```

<!-- 关键：每个 Gate description 包含 "如 memory 与 TaskList 不符以 TaskList 为准" — PATTERN 7 -->

7. 创建 memory `[FILL: progress_memory_pattern]-[ProjectName]-progress`
8. 创建 [FILL: audit_log_name] 审计日志文件

### [FILL: concept_doc] 模板

```markdown
# Concept — [ProjectName]

## 目标（创建后不可修改）
- 名称: [name]
- 一句话描述: [description]
- 核心功能:
  1. [功能1]
  2. [功能2]
  3. [功能3]
- [FILL: domain-specific fields]
- 项目路径: [path]
```

### 关键原则
- 小而精，功能 3-5 个
- 如果需求暗示 > [FILL: 15] 个工作单元，在此阶段就协商精简

---

## Phase [N] 骨架（可复制模板）

### 转场读取
- 重读 [FILL: concept_doc] 目标区
- 读取 [FILL: 上一阶段输出文件]
- 对照功能列表确认无偏离（偏离 → AskUserQuestion）<!-- PATTERN 3 -->
- TaskList + memory 核对（不一致以 TaskList 为准）<!-- PATTERN 7 -->
- TaskUpdate: Phase [N] → `in_progress`

### 工作内容
[FILL: 本 Phase 的具体任务]

### Sub-Agent（如需要）
[FILL: Implementor/Verifier 调用，或 "Coordinator 直接完成"]

### 输出
[FILL: 输出文件/产物]

### 转场写入
TaskUpdate: Phase [N] → `completed`。更新 memory。

---

## Phase 4: [FILL: 实现阶段] — CIV 编码循环（完整示例）

**最长阶段。Coordinator 绝不自己写实现代码。**

### 转场读取
- 重读 [FILL: concept_doc] + [FILL: architecture_doc]
- 读取 [FILL: project config]
- TaskUpdate: Phase 4 → `in_progress`
- 为每个工作单元创建 Task
- **为每个批次创建 Verifier + Checkpoint + Memory Tasks（用 blockedBy 串联）** <!-- PATTERN 4 -->
- TaskList 确认所有 batch Tasks 已创建 <!-- PATTERN 4 enforcement -->

```
TaskCreate: "U1: [FILL: unit name]" (pending)
TaskCreate: "U2: [FILL]" (pending)
...
TaskCreate: "Batch 1 Verifier 审查" (blockedBy: [U1, U2, ...])
TaskCreate: "Checkpoint: Batch 1" (blockedBy: Batch 1 Verifier)  ← AskUserQuestion
TaskCreate: "Memory: Batch 1" (blockedBy: Checkpoint)
TaskCreate: "U6: [FILL]" (blockedBy: Memory Batch 1)  ← Batch 2 starts here
...
```

### 批次循环

对每个批次：

#### Step 1: 逐单元实现（Implementor sub-agent）

对当前批次的每个工作单元：

**1a.** 启动 Implementor sub-agent（见 Sub-Agent Prompt Templates）

**1b.** Coordinator 构建验证：
```bash
[FILL: build command] 2>&1 | tail -30
```
编译失败 → 新 Implementor 修复（最多 3 轮）→ 3 轮后标记 ⚠️ 继续

**1c.** Coordinator commit + 更新进度：
```bash
git add [该单元的文件]
git commit -m "U{N}: [unit name]"
```
TaskUpdate: `U{N}` → `completed`

#### Step 2: 批次验证（Verifier sub-agent）

启动 Verifier（见 Sub-Agent Prompt Templates），处理返回：
- **Critical**: 必须委托 Implementor 修复 → 重新启动 Verifier 确认
- **Warning**: 小修复 Coordinator 直接做，大修复委托 Implementor
- **Info**: 记录不阻塞

#### Step 3: 功能验证

Coordinator 运行构建 + 验证脚本：
```bash
[FILL: build + basic verification commands]
```

#### Step 4: 批次间检查点（硬阻塞）<!-- PATTERN 4 -->

**如果工作单元总数 > [FILL: 5] 且还有后续批次：**

Coordinator **必须调用 `mcp__conductor__AskUserQuestion`** 阻塞。

**不要用文本输出代替 AskUserQuestion。不要在用户响应前继续下一批次。**

AskUserQuestion 内容：
- 本批次完成的单元及状态
- 构建状态和 Verifier 摘要
- 验证标准（供用户手动验证）
- 选项："继续下一批" / "有问题需要修复"

#### Step 5: 全量构建（最后一个批次完成后）

TaskUpdate: Phase 4 → `completed`。

---

## Sub-Agent Prompt Templates

### Implementor Prompt

```
你是一个 [FILL: domain] 开发者。你只需要实现一个 [FILL: work_unit_name]。

## 你的任务
实现: [injected: unit name]
功能描述: [injected: from architecture doc]

## 项目信息
- 项目路径: [injected: path]
- 技术栈: [injected: tech stack]
- 已有代码: [injected: dependency file paths]

## 编码规则
- [injected: from project config / CLAUDE.md]
- [FILL: domain-specific rules, from references/]

## 可用专业 Skills
[injected: from Gate 2 detection results]

## 要求（硬编码，不要修改）
1. 只实现 [unit name]，不要修改其他模块
2. 读取依赖模块接口，确保调用正确
3. 完成后运行 `[FILL: build command] 2>&1 | tail -30` 确认通过
4. 编译失败则修复（最多 5 轮），5 轮后简化实现并说明
5. 不要操作 Tasks（TaskCreate / TaskUpdate）
6. 不要执行 git commit
```

### Verifier Prompt

```
你是一个 [FILL: domain] 审查专家。审查以下实现。

## 审查范围
文件: [injected: file paths]
架构设计: [injected: from architecture doc]

## 可用专业 Skills
[injected: from Gate 2 detection results]              <!-- PATTERN 6 -->
对于 [FILL: sub-domain] 代码，调用 /[FILL: skill]。

## 审查清单（硬编码，不要修改）
1. 每个 [work unit] 是否实现了 architecture doc 描述的全部功能？列出缺失项
2. 模块间调用关系是否正确？参数类型、返回值匹配？
3. [FILL: domain-specific runtime pitfalls checklist]
4. 空函数体、未连接的回调、永远为 false 的条件？
5. [FILL: domain-specific correctness checks]
6. **功能完整性 vs concept doc**: 对照 [concept_doc] 列出每个功能状态:
   ✅完整 / ⚠️简化 / ❌缺失。❌ 标为 Critical。                 <!-- PATTERN 3 -->
7. **文档-代码一致性**: 检查 [architecture_doc] 和 [project config]
   是否与当前代码一致。过时内容标为 Critical。                      <!-- PATTERN 5 -->

## 输出格式
对每个发现：
- 文件: [路径]
- 行号: [范围]
- 问题: [描述]
- 严重度: Critical / Warning / Info
- 建议修复: [代码片段]
```

---

## 专业 Skill 编排

<!-- PATTERN 6: Gate 2 强制检测，结果注入 sub-agent prompt -->

| Skill | 阶段 | 职责 | 未安装时 Fallback |
|-------|------|------|-------------------|
| [FILL: /skill-name] | [FILL: Phase] | [FILL: role] | [FILL: fallback] |
| [FILL: ...] | | | |

**检测方式**：Gate 2 强制执行检测，结果记录在 [FILL: audit_log_name]。后续 Verifier/Implementor prompt 中注入可用 skills 列表。

---

## Recovery Protocol

<!-- PATTERN 7: Conversation recovery — TaskList is the single authoritative source -->

**当新对话检测到 [FILL: progress_memory_pattern] memory 时，必须立即执行：**

1. **TaskList** — 获取所有 Tasks 的当前状态（**唯一权威进度源**）
2. **Read [FILL: concept_doc]** — 恢复项目目标
3. **Read [FILL: architecture_doc]** — 恢复技术上下文
4. **对比** memory 阶段 vs TaskList 实际阶段：
   - 一致 → 继续当前 Phase
   - 不一致 → **以 TaskList 为准**，立即更新 memory
5. **Read [FILL: audit_log_name]** — 确认最后记录与 TaskList 一致
6. **从当前 Phase 对应的 Gate Task 重新开始**

```
⚠️ 原则：TaskList 是唯一权威进度源。
   Memory 和审计日志是辅助参考。三者不一致时以 TaskList 为准。
```

---

## 重要原则

1. **Coordinator 不写实现代码** — 全部通过 sub-agent 完成
2. **小而美** — 功能少但精，> [FILL: 15] 工作单元强制精简
3. **构建是 Coordinator 的责任** — 每个 sub-agent 完成后 Coordinator 亲自验证
4. **状态更新是 Coordinator 的责任** — sub-agent 不碰 Tasks 和 git
5. **批次交付，增量验证** — 不要一口气写完再验证
6. **四层韧性** — Task 依赖链 + Memory + 文件接力 + 审计日志
7. **完成 = 用户说 OK** — 自动验证只是预筛，用户确认才是终点
8. **快速失败，优雅降级** — N 轮失败则简化实现，不卡住管线
9. **重要的规则必须结构性强制执行，不能靠自律** — 如果规则只是文本建议，LLM 在长任务后半段会跳过它
