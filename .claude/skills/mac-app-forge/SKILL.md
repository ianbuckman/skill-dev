---
name: mac-app-forge
description: 从创意到 .dmg 的全自动 macOS 应用构建流水线。当用户说"帮我做个 Mac app""做个桌面应用""build a macOS app""我想要一个能...的工具""做个 menu bar 小工具""帮我做个...的 Mac 软件""forge an app""造个 app"等时触发。也适用于用户描述了一个工具需求、痛点或创意，暗示可以做成 macOS 桌面应用的场景。本 skill 覆盖从构思→技术方案→编码→测试→打包 .dmg→使用手册的完整流程，交付物是一个可安装的 .dmg 文件和使用说明。即使用户只是说"这个能不能做成个 app"，也应该触发。注意：本 skill 用于创建新的 macOS 应用，不用于修改已有项目（已有项目请直接在项目中工作）。
---

# Mac App Forge — 从创意到 .dmg 全自动流水线

将一句话需求变成可安装的 macOS 应用。Claude 自主完成构思、编码、测试、打包全流程，最终交付 .dmg 安装包 + 使用手册。

## 环境要求

- macOS（M1/M2/M3/M4 系列推荐）
- Xcode Command Line Tools（`xcode-select --install`）
- 可选：`create-dmg` (`brew install create-dmg`)，若未安装则 fallback 到 `hdiutil`

## 专业 Skill 编排

mac-app-forge 专注流水线编排 + macOS 应用特有知识，编码质量委托给专业 skills：

| Skill | 阶段 | 职责 | 未安装时 Fallback |
|-------|------|------|-------------------|
| /swiftui-pro | Phase 4, 5 | SwiftUI 审查 | references/macos-patterns.md |
| /swift-concurrency-pro | Phase 4, 5 | 并发正确性 | macos-patterns.md fallback 段 |
| /swift-testing-pro | Phase 5 | 关键模块测试 | 跳过（烟雾测试仍执行） |
| /swift-api-design-guidelines-skill | Phase 4 | API 命名 | 跳过 |
| /swiftdata-pro | Phase 4 | SwiftData 审查 | 跳过 |
| /review | Phase 5 | 结构性审查 | 内置陷阱扫描 |

**检测方式**：流水线开始时检查可用 skills 列表，记录哪些已安装。未安装的 skill 自动 fallback 到上表右列。

## 流水线总览

```
用户输入（一句话需求）
    ↓
[Phase 1] 创意细化 → _task_state.md + phase1_concept.md
    ↓
[Phase 2] 技术方案 → ARCHITECTURE.md
    ↓
[Phase 3] 脚手架生成 → 项目骨架 + CLAUDE.md + git init
    ↓
[Phase 4] 编码实现 → 逐模块实现（每模块 compile + commit）
    ↓
[Phase 5] 构建与自动验证 ← 内置修复循环（编译→烟雾测试→代码审查→自动修复，最多3轮）
    ↓
[Phase 6] 打包发布 → .dmg + README.md
    ↓
[Phase 7] 交付与用户验证 ← 用户反馈循环（报告问题→分类→回退修复→重新打包，最多3轮）
    ↓
交付确认：用户满意 ✅
```

**核心理念：编译通过不等于能用。测试通过 = 用户说 OK。**

---

## 长任务韧性机制

这条流水线可能几百次工具调用，以下机制防止偏离：

### _task_state.md — 任务北极星

Phase 1 结束后创建，是整个流水线的唯一真相来源：
- **目标区**（不可修改）：App 名称、核心功能、技术栈、项目路径
- **进度区**（每个 Phase 结束时更新）：完成状态和当前阶段
- **模块清单**（Phase 2 填写）：Phase 4 的检查点
- **验证轮次**（Phase 7 使用）：用户反馈和修复记录

### 文件接力

每个 Phase 从文件读取输入、把产出写入文件。不依赖对话记忆。

### Phase 转场协议

**进入新 Phase 时（强制）：** 重读 `_task_state.md` + 上一阶段输出文件
**完成当前 Phase 时（强制）：** 写入产出文件 + 更新 `_task_state.md` + 一句话汇报

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

4. 用户确认后，写入 `phase1_concept.md`，创建 `_task_state.md`：

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
- [ ] Phase 5: 构建与自动验证 → phase5_build_report.md
- [ ] Phase 6: 打包发布 → dist/[AppName].dmg + README.md
- [ ] Phase 7: 交付与用户验证

## 当前阶段
Phase 2

## Phase 4 模块清单（Phase 2 完成后填写）
[待填写]

## 验证记录（Phase 7 使用）
[待填写]
```

### 关键原则
- 小而精，功能 3-5 个，不膨胀
- 未指定则默认 Menu Bar App

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

### 转场写入
更新 `_task_state.md`：填入技术栈、勾选 Phase 2、填写 Phase 4 模块清单。直接进入 Phase 3。

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
`.gitignore` → git init → "Initial scaffold" commit

### 转场写入
更新 `_task_state.md` 勾选 Phase 3。

---

## Phase 4: 编码实现

最长阶段，60-70% 的工具调用。

### 转场读取
- 重读 `_task_state.md`（完整，含模块清单）
- 读取 `ARCHITECTURE.md` + 项目 `CLAUDE.md`

### 每个模块的工作循环
1. **重读 `_task_state.md` 目标区和模块清单** — 每个模块开始前都做
2. 读取 `ARCHITECTURE.md` 中该模块设计
3. 写代码
4. 编译验证，输出只看 error/warning
5. 修复编译错误（最多 5 轮）
6. 5 轮后仍有问题 → 简化实现
7. git commit（含模块名）
8. 更新 `_task_state.md` 勾选该模块

### 质量关协议

**Swift 路线** — 每个模块编码+编译通过后，执行质量关：
1. 调用 /swiftui-pro 审查该模块的 SwiftUI 代码
2. 如模块含并发代码，调用 /swift-concurrency-pro 审查
3. 如模块使用 SwiftData，调用 /swiftdata-pro 审查
4. 修复审查发现的问题 → 重新编译 → commit
5. macOS 特有规则始终读取 `references/macos-patterns.md`

> 未安装专业 skill 时：读取 `references/macos-patterns.md` 中的 fallback 段作为基本规则

**Electron 路线** — 读取 `references/electron-coding-rules.md`（无对应专业 skill，规则不变）

**通用** — 少依赖、错误处理、数据存 `~/Library/Application Support/`

### 所有模块完成后
全量编译确认 → 更新 `_task_state.md` 勾选 Phase 4

---

## Phase 5: 构建与自动验证

**编译通过 ≠ 能正常运行。** 这个阶段通过多层自动检查尽可能在交付前发现问题，内置自动修复循环。

### 转场读取
- 重读 `_task_state.md` 目标区和核心功能列表
- 读取 `ARCHITECTURE.md`

### 验证循环（最多 3 轮）

```
round = 1
while round <= 3:
    Step 1: 编译 → 失败则修复 → 重新编译
    Step 2: 烟雾测试 → 崩溃则分析修复 → 回到 Step 1
    Step 3: 代码审查 → 发现陷阱则修复 → 回到 Step 1
    全部通过 → break
    round += 1
3轮后仍有问题 → 写入报告，进入 Phase 6 时标注风险
```

### Step 1: 编译构建
```bash
# Swift
swift build -c release 2>&1 | tail -30
# Electron
npm run build 2>&1 | tail -30
```
编译失败 → 读取错误 → 自动修复 → 重新编译（最多 5 轮内循环）

### Step 2: 启动烟雾测试

```bash
.build/release/[AppName] &
APP_PID=$!
sleep 3
if kill -0 $APP_PID 2>/dev/null; then
    echo "✅ 烟雾测试通过"
    kill $APP_PID
else
    echo "❌ 启动崩溃"
    # 读取 crash 日志分析原因
fi
```

崩溃常见原因：缺少资源文件、Info.plist 错误、强制解包 nil、Environment 未注入

### Step 2.5: 关键模块测试（Swift 路线）

调用 /swift-testing-pro 为关键 Service 模块编写测试，然后运行 `swift test`。
> 未安装 /swift-testing-pro 时跳过此步骤，烟雾测试仍提供基本保障。

### Step 3: 代码审查（分层）

**3a: 专业 Skill 全量审查**
- 调用 /swiftui-pro 审查所有 SwiftUI 代码
- 调用 /swift-concurrency-pro 审查所有并发代码
- 修复发现的问题 → 重新编译

**3b: macOS 运行时陷阱扫描（mac-app-forge 独有知识，不可委托）**

重新阅读所有源代码文件，逐项检查 `references/macos-patterns.md` 中的 5 个运行时陷阱。

**Swift/SwiftUI 陷阱**：AppDelegate 双实例、@Observable 环境断裂、Timer/Monitor 引用丢失、NSPanel 创建时机、全局快捷键权限

**Electron 陷阱**：
1. IPC 通道名称主/渲染进程不匹配
2. `contextIsolation` 开启后渲染进程无法直接用 Node API
3. 窗口 `show: false` 忘记 `ready-to-show` 事件

**3c: 结构性审查（可选）**
- 调用 /review 对完整 diff 做结构性审查
> 未安装时跳过，3b 的陷阱扫描仍提供基本保障。

发现问题 → 修复 → 重新编译 → 回到 Step 1

### Step 4: 生成验证清单

根据 `_task_state.md` 核心功能列表，自动生成手动验证清单。每个功能对应一个检查项。

### 转场写入

写入 `phase5_build_report.md`：
```markdown
## 构建报告
- 编译: 成功/失败
- 警告数: N
- 二进制: [path] ([size])
- 烟雾测试: 通过/失败
- 代码审查: N 个问题（已修复）
- 自动验证轮次: M/3

## 手动验证清单
请安装后逐项确认：
- [ ] [功能1的检查项]
- [ ] [功能2的检查项]
- [ ] ...
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

**这是与用户一起完成的最终质量关。** 编译通过、烟雾测试通过都只是基础，真正的"通过"是用户安装后确认功能正常。

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

📋 请按以下清单逐项验证：
[粘贴 phase5_build_report.md 中的手动验证清单]

验证完成后告诉我结果，有问题我会修复并重新打包。
```

### 用户反馈修复循环（最多 3 轮）

用户报告问题后，执行以下流程：

**Step 1: 问题分类**

重读 `_task_state.md` 目标区，然后分析用户报告的每个问题属于哪一类：

| 问题类型 | 示例 | 回退到 |
|---------|------|--------|
| 代码 Bug | "点击没反应""崩溃""数据没保存" | Phase 4（修复对应模块） |
| UI/交互问题 | "按钮太小""布局不对""颜色难看" | Phase 4（修改 View 模块） |
| 架构缺陷 | "整个功能路径不通""数据流断裂" | Phase 2（修订 ARCHITECTURE.md）→ Phase 3-4 |
| 功能缺失 | "少了 XX 功能""能不能加 XX" | Phase 1（确认需求变更）→ Phase 2-4 |
| 环境问题 | "权限不够""系统版本不支持" | 不回退，更新 README 说明 |

**Step 2: 修复**

1. 根据分类，回退到对应 Phase
2. 重读 `_task_state.md` — 确认目标未变
3. 执行修复（代码修改 / 架构调整 / 功能补充）
4. 重新走完下游 Phase（Phase 5 自动验证 → Phase 6 重新打包）
5. 在 `_task_state.md` 验证记录区追加本轮修复内容

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

- 用户说 OK / 验证清单全部通过 → **交付完成** ✅
- 还有问题 → 回到 Step 1（下一轮）
- 3 轮后仍未解决 → 向用户说明剩余问题和限制，讨论是否简化功能或接受当前状态

### 验证记录模板

每轮修复后更新 `_task_state.md` 验证记录区：
```markdown
## 验证记录

### 第 1 轮
- 用户反馈: 主面板打不开，剪贴板内容没捕获
- 问题分类: 代码 Bug（AppDelegate 双实例）
- 修复: 移除 static shared，改用 NSApp.delegate
- 回退到: Phase 4 → Phase 5 → Phase 6
- 结果: 已重新打包

### 第 2 轮
- 用户反馈: ...
```

---

## 重要原则

1. **自主决策，少问多做** — 除 Phase 1 确认和 Phase 7 等待反馈外，自主推进
2. **小而美** — 功能少但精，不做半成品
3. **快速失败，优雅降级** — 实现不了就简化，不卡住流水线
4. **编译驱动** — 写完就编译，编译就修
5. **读文件不读记忆** — 跨阶段信息通过文件传递，重读成本低，偏离成本高
6. **测试通过 = 用户说 OK** — 编译通过只是起点，用户确认才是终点
7. **每阶段 git commit** — 方便回滚。修复轮次中，每次修复单独 commit 并标注轮次
