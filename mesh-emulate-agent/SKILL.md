---
name: mesh-emulate-agent
description: |
  借用指定 agent 的思考模式，在主对话中执行任务。
  当用户说"用 planner 的思维"、"以 critic 的视角"、"采用 architect 的方法论"等时触发。
  必须指定有效的 agent 名称（如 planner、architect、critic、security-reviewer 等）。
  如果指定的 agent 不存在，则报错提示。
---

# Mesh Emulate Agent

在主对话中借用指定 agent 的思考模式，保持交互澄清能力。

## 用法

```markdown
/mesh-emulate-agent <agent名> <任务描述>

# 或者自然语言：
用 planner 的思维方式，创建贪吃蛇计划
以 critic 的视角，审查这个方案
采用 architect 的方法论，设计系统架构
```

## 参数

| 参数 | 必需 | 说明 |
|------|------|------|
| `agent` | 是 | 要借用其思考模式的 agent 名称 |
| `task` | 是 | 要执行的任务描述 |

## 工作流程

### 1. 验证 Agent 存在

首先检查指定的 agent 是否存在：

```
可用 agent 列表（部分）：
- planner: 实施规划专家
- architect: 系统架构设计
- critic: 方案审查专家
- security-reviewer: 安全分析
- code-reviewer: 代码审查
- debugger: 调试分析
- tdd-guide: 测试驱动开发
- performance-optimizer: 性能优化
- refactor-cleaner: 重构清理
...（更多见 ~/.claude/agents/）
```

如果 agent 不存在：
```
❌ 错误：agent "{name}" 不存在

可用的 agent 包括：
- planner: 实施规划专家
- architect: 系统架构设计
- critic: 方案审查专家
...

请使用有效的 agent 名称后重试。
```

### 2. 加载 Agent 思考模式

读取指定 agent 的系统提示词，提取其：
- 核心方法论
- 工作流程
- 输出格式要求
- 最佳实践
- 审查清单

### 3. 在主对话中执行

采用该 agent 的思考模式，在主对话中：
- 按其方法论逐步分析
- 输出符合其格式要求的结果
- **保持交互能力**：需求不明确时主动提问

### 4. 标注身份

输出时明确说明：
```
📐 采用 planner 的思考模式进行分析...
```

## 示例

### 示例 1：借用 planner 思考模式

```markdown
用户：
/mesh-emulate-agent planner 创建贪吃蛇游戏的实施计划

Claude：
📐 采用 planner 的思考模式进行分析...

# 实施计划：贪吃蛇游戏

## 概述
[按 planner 格式输出的计划]

## 需求分析
- [需求列表]

## 架构变更
- [变更列表]

## 实施步骤
### 阶段 1：...
...

（如果需求不明确）
⚠️ 需要澄清：
1. 网页版还是终端版？
2. 单人还是多人模式？
```

### 示例 2：借用 critic 视角

```markdown
用户：
以 critic 的视角审查这个方案

Claude：
📐 采用 critic 的视角进行审查...

**VERDICT: REVISE**

**整体评估**: 方案方向正确，但存在若干关键问题...

**关键发现**:
1. [发现详情]

**缺失项**:
- [缺失内容]

（可以交互讨论发现项）
```

### 示例 3：借用 architect 方法论

```markdown
用户：
采用 architect 的方法论设计用户认证系统

Claude：
📐 采用 architect 的方法论进行设计...

# 架构设计：用户认证系统

## 当前状态分析
...

## 架构决策记录 (ADR)
### ADR-001: 使用 JWT 进行认证
...

（可以交互澄清需求）
```

## 支持的 Agent 列表

以下是常用的 agent 及其适用场景：

| Agent | 适用场景 | 核心能力 |
|-------|---------|---------|
| `planner` | 功能规划、实施计划 | 需求分析、步骤分解、风险评估 |
| `architect` | 系统设计、架构决策 | 架构图、ADR、技术选型 |
| `critic` | 方案审查、质量把关 | 多视角分析、缺口发现、严重性评级 |
| `security-reviewer` | 安全分析 | 漏洞检测、OWASP、安全最佳实践 |
| `code-reviewer` | 代码审查 | 代码质量、模式、最佳实践 |
| `debugger` | 问题调试 | 根因分析、堆栈追踪、回归隔离 |
| `tdd-guide` | 测试驱动 | RED-GREEN-REFACTOR、覆盖率 |
| `performance-optimizer` | 性能优化 | 瓶颈分析、优化策略 |
| `refactor-cleaner` | 重构清理 | 死代码检测、重复消除 |

完整列表见 `~/.claude/agents/` 目录。

## 与直接调用子 Agent 的区别

| 维度 | 借用思考模式 | 直接调用子 Agent |
|------|-------------|-----------------|
| 执行位置 | 主对话 | 隔离子上下文 |
| 交互能力 | ✅ 可随时交互 | ❌ 无法交互 |
| 上下文可见性 | 完整历史 | 仅传入的任务 |
| Token 成本 | 共享主上下文 | 额外子上下文 |
| 适用场景 | 需求模糊、需要讨论 | 需求明确、独立执行 |

## 注意事项

1. **不是启动子 agent**：这是在主对话中采用某 agent 的思考模式，不是启动子 agent
2. **保持交互性**：需求不明确时，主动提问澄清
3. **输出格式**：尽量遵循该 agent 的输出格式要求
4. **标注来源**：输出时明确说明采用了哪个 agent 的思考模式

## 触发词

以下表述会触发此技能：

- "用 planner 的思维/方法/视角..."
- "以 critic 的视角..."
- "采用 architect 的方法论..."
- "按照 security-reviewer 的思维..."
- "借用 code-reviewer 的思考模式..."
- "/mesh-emulate-agent ..."
