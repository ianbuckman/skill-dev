---
name: audit-floattodo-build
description: FloatTodo 构建过程审计报告（2026-03-22）— CIV 核心合规但辅助韧性机制后半段衰减
type: project
---

## FloatTodo 构建审计结果（2026-03-22）

4 模块单批交付，CIV 架构严格执行，最终交付 .dmg。

### 合规（做到了的）
- 7 Phase + 5 Gate 全部按序执行，无跳步
- CIV 分工严格：Coordinator 未写任何模块代码，4 个模块全部由 Implementor sub-agent 实现
- Verifier 发现 1 Critical（click-through 不可恢复）后委托 Implementor 修复 + 启动二次 Verifier 确认
- 每个 sub-agent 返回后 Coordinator 亲自编译验证
- 批次控制正确：≤5 模块单批交付，无需用户检查点

### 偏离（没做到的）
1. **目标偏离（中）**: 鼠标穿透功能被直接移除而未与用户沟通。phase1_concept.md 标注为"不可修改"，应降级实现或先征求用户意见
2. **审计日志衰减（明显）**: _forge_log.md 前半段记录完整（Phase 1 ~ Gate 4），后半段缺少 Phase 2/5/6 Complete 和 Gate 6 记录。典型的长任务后半段规则衰减
3. **文档未同步**: ARCHITECTURE.md 仍描述已移除的 isClickThrough；CLAUDE.md 写 WindowGroup 但代码已改为 Window
4. **Task 粒度不足**: Phase 4 内部缺少 Batch Verifier Task，只有模块级 Tasks
5. **专业 skill 未检测/调用**: 未在流水线开始时检查可用 skills 列表（swiftui-pro、swift-concurrency-pro 等均可用但未调用）
6. **Memory 恢复时未核对**: 对话中断恢复后 memory 停留在 Phase 3，Coordinator 未立即与 Tasks 对照校正

### 关键洞察
CIV 核心机制（代码隔离、独立审查、Coordinator 不写代码）被严格遵守。偏离集中在辅助韧性层（审计日志、文档同步、task 粒度）。**印证了 LLM 在长任务后半段会跳过非关键步骤的假设。**

**Why:** 这是 mac-app-forge CIV 架构的第二次实战（第一次 ClipVault），审计数据用于迭代改进 skill 设计。
**How to apply:** 下次迭代 skill 时重点加强后半段审计日志的强制性（考虑在 Gate Task 完成条件中硬编码 _forge_log.md 追加检查），以及在功能移除决策时强制 AskUserQuestion。
