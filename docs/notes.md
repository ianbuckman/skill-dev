# 长任务 Skill Pattern 优化

## 意图

从 FloatTodo 构建审计中提炼 7 个通用反衰减 pattern，创建可复用的长任务 skill 模板，然后用 mac-app-forge-v2 构建 DeskPet 桌面宠物 app 来验证 pattern 是否生效。

## 已完成

1. **通用模板** `.claude/skills/long-task-template/SKILL.md` (569 行)
   - 78 个 `[FILL]` 占位符，domain-specific 内容待填
   - 7 个反衰减 pattern 硬编码（不是 `[FILL]`）

2. **mac-app-forge-v2** `.claude/skills/mac-app-forge-v2/SKILL.md` (913 行)
   - 模板的 macOS 实例化，所有 `[FILL]` 已填入 Swift/SwiftUI 内容
   - 复用 v1 的 references/ 目录（7 个领域参考文档）

## 7 个反衰减 Pattern

| # | Pattern | v1 问题 | v2 强制机制 |
|---|---------|--------|-----------|
| 1 | Phase-Gate-Log 链 | 三节点链，审计日志后半段缺失 | 五节点链 + Log Task Grep 验证 |
| 2 | CIV Sub-Agent 隔离 | ✅ v1 已合规 | 不变 |
| 3 | 目标不可变门控 | "不可修改"标注无执行力 | Phase 转场 AskUserQuestion + Verifier 核查 |
| 4 | 批次硬阻塞检查点 | ✅ v1 已合规 | Gate 4 强制创建批次 Tasks |
| 5 | Verifier 衰减探测 | 无文档-代码一致性检查 | Verifier Section D 文档核查 |
| 6 | 早期工具检测 | 文本指令被忽略 | Gate 2 硬编码检测 + 注入 prompt |
| 7 | 对话恢复协议 | 简单提示 | 6 步结构化协议 + Gate 嵌入核对 |

## 待做

- [ ] 用 mac-app-forge-v2 构建 DeskPet（桌面宠物：浮动动画 + 互动 + 番茄钟，~6 模块）
- [ ] 构建后审计：对照 7 个 pattern 检查哪些被执行、哪些仍衰减
- [ ] 根据审计结果迭代模板
