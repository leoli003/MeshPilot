---
name: comet-design
description: "Comet 阶段 2: 深度设计。使用 /comet-design 调用。通过头脑风暴产出设计文档和 delta spec。"
---

# Comet 阶段 2: 深度设计

## Auto 模式检测

**在开始时检查 `--auto` 标志：**

```
如果 {{PROMPT}} 包含 "--auto"：
  1. 从工作提示中移除 "--auto"
  2. 为此阶段设置 AUTO_MODE=true
  3. 跳过所有 AskUserQuestion 阻塞点
  4. 在步骤 1c 自动确认
```

当 `AUTO_MODE=true` 时，此阶段完全自主运行，无需用户确认。

---

## 前置条件

- 存在活跃变更（proposal.md、design.md、tasks.md）
- 无设计文档（`docs/superpowers/specs/` 下无对应文件）

## 步骤

### 0. 入口状态验证

执行入口验证：

```bash
COMET_ENV="${COMET_ENV:-$(find . "$HOME"/.*/skills "$HOME/.config" "$HOME/.gemini" -path '*/comet/scripts/comet-env.sh' -type f -print -quit 2>/dev/null)}"
if [ -z "$COMET_ENV" ]; then
  echo "ERROR: comet-env.sh not found. Ensure the comet skill is installed." >&2
  return 1
fi
. "$COMET_ENV"
"$COMET_BASH" "$COMET_STATE" check <name> design
```

验证通过后进入步骤 1。验证失败时脚本输出具体失败原因。

**幂等性**：所有 design 阶段操作可以安全重新执行。如果 `handoff_context` 和 `handoff_hash` 已存在，确认它们与当前产物匹配后再决定是否重新生成。

### 1a. 生成 OpenSpec → Superpowers 交接包

**必须由脚本生成。禁止代理即时撰写摘要。**

```bash
"$COMET_BASH" "$COMET_HANDOFF" <change-name> design --write
```

脚本生成并记录：

```
openspec/changes/<name>/.comet/handoff/design-context.json
openspec/changes/<name>/.comet/handoff/design-context.md
```

并写入 `.comet.yaml`：

```yaml
handoff_context: openspec/changes/<name>/.comet/handoff/design-context.json
handoff_hash: <sha256>
```

默认交接包是**紧凑可追溯摘录**，而非代理摘要：
- `design-context.json`：机器索引，包含 change、phase、canonical spec、source paths、hash
- `design-context.md`：Superpowers 读取的上下文，包含脚本标记、source path、line range、sha256、确定性摘录
- 超出摘录预算时标记 `[TRUNCATED]` 并保留 Full source path

如果确实需要完整上下文，显式运行：

```bash
"$COMET_BASH" "$COMET_HANDOFF" <change-name> design --write --full
```

交接包来源为 OpenSpec open 阶段产物：
- `proposal.md`：目标、动机、范围、非目标
- `design.md`：高层架构决策、方案约束
- `tasks.md`：初始任务边界
- `specs/*/spec.md`：delta 能力规格

### 1b. 执行头脑风暴（带上下文）

**首先读取序号和中文标题：**

```bash
SEQUENCE=$("$COMET_BASH" "$COMET_STATE" get <change-name> sequence)
CHINESE_TITLE=$("$COMET_BASH" "$COMET_STATE" get <change-name> chinese_title)
```

**立即执行：** 使用 Skill 工具加载 Superpowers `brainstorming` 技能，ARGUMENTS 包含：

```
Change: <change-name>
Sequence: <sequence>
Chinese Title: <chinese_title>
OpenSpec Context Pack: openspec/changes/<name>/.comet/handoff/design-context.md
Machine handoff: openspec/changes/<name>/.comet/handoff/design-context.json

OpenSpec 产物是上游真实来源。不要重新定义需求，不要重写 proposal/spec。
你的任务是基于交接包进行深度技术设计：实现方案、技术风险、测试策略、边界条件。
如果发现 OpenSpec delta spec 缺少验收场景，只能提出 Spec Patches 并写回 OpenSpec delta spec；不要在设计文档中创建第二个需求规格。

**文件命名要求**：
- 设计文档保存到: docs/superpowers/specs/<sequence>-<chinese_title>-设计.md
- 示例: docs/superpowers/specs/0004-挡板碰撞粒子效果-设计.md

设计文档 frontmatter 必须极简，只包含：
---
comet_change: <change-name>
role: technical-design
canonical_spec: openspec
---

跳过冗余上下文探索，直接进入设计问题。
```

禁止跳过此步骤。禁止不加载此技能就继续。

如果 Superpowers `brainstorming` 技能不可用，停止流程并提示安装或启用 Superpowers 技能。不要用普通对话替代此步骤。

技能加载后，按照其指导产出设计提案（以对话形式呈现）：
- 技术方案：架构、数据流、关键技术选择和风险
- 测试策略
- 如果需要补充验收场景，指出要写回的 delta spec 变更

头脑风暴阶段不写入设计文档文件；只产出设计提案供步骤 1c 用户确认。确认后才创建 `docs/superpowers/specs/序号-中文标题-设计.md` 并写回 delta spec。

### 1c. 用户确认设计提案（阻塞点）

头脑风暴产出设计提案后：

**如果 AUTO_MODE=true：**
- 跳过 AskUserQuestion
- 自动确认设计提案
- 记录日志："[Auto Mode] 自动确认设计提案"
- 直接进入步骤 2

**如果 AUTO_MODE=false（默认）：**
- 必须使用 AskUserQuestion 工具暂停并等待用户明确确认设计提案
- 在用户确认前不得创建最终设计文档、写入 `design_doc`、运行 design guard 或进入 `/comet-build`
- 不得仅输出文本提示后继续执行

暂停时只呈现核心摘要：
- 采用的技术方案
- 关键权衡和风险
- 测试策略
- 如有 Spec Patches，列出要写回的 delta spec 变更

只有用户明确确认后，才进入步骤 2。如用户要求调整，继续头脑风暴迭代直到用户确认。

### 2. 更新 Comet 状态

首先记录 design_doc 路径。如果步骤 1c 写回了 delta spec（新增或修改 `specs/*/spec.md`），必须重新生成 handoff 更新 hash：

```bash
# 读取序号和中文标题
SEQUENCE=$("$COMET_BASH" "$COMET_STATE" get <name> sequence)
CHINESE_TITLE=$("$COMET_BASH" "$COMET_STATE" get <name> chinese_title)

# 构建设计文档路径
DESIGN_DOC="docs/superpowers/specs/${SEQUENCE}-${CHINESE_TITLE}-设计.md"

# 记录 design_doc 路径
"$COMET_BASH" "$COMET_STATE" set <name> design_doc "$DESIGN_DOC"

# 如有 delta spec 变更，重新生成 handoff（更新 hash）
"$COMET_BASH" "$COMET_HANDOFF" <change-name> design --write

# 自动转换到下一阶段
"$COMET_BASH" "$COMET_GUARD" <change-name> design --apply
```

如无 delta spec 变更，跳过交接包重新生成步骤。状态文件自动更新；无需手动编辑其他字段。

## 退出条件

- 设计文档已创建并保存
- 设计文档 frontmatter 包含 `comet_change`、`role: technical-design`、`canonical_spec: openspec`
- `handoff_context` 和 `handoff_hash` 已写入 `.comet.yaml`（由 guard 强制）
- `handoff_hash` 匹配当前 OpenSpec open 阶段产物（由 guard 强制）
- `design-context.md` 必须由脚本生成并包含 source path、mode、sha256 可追溯标记（由 guard 强制）
- 如有新能力或补充验收场景，OpenSpec delta spec 已创建/更新
- `design_doc` 已写入 `.comet.yaml`
- **阶段 guard**：运行 `"$COMET_BASH" "$COMET_GUARD" <change-name> design --apply`；全部通过后自动转换到 `phase: build`

退出前必须使用 `--apply`：

```bash
"$COMET_BASH" "$COMET_GUARD" <change-name> design --apply
```

## 上下文压缩恢复

design 阶段可能在头脑风暴期间触发上下文压缩。恢复时首先运行：

```bash
"$COMET_BASH" "$COMET_STATE" check <change-name> design --recover
```

脚本输出结构化恢复上下文（阶段、已完成字段、待完成字段、恢复操作）。按 Recovery action 确定下一步。

## 自动转换

退出条件满足后（包括用户确认设计提案），自动转换到下一阶段：

> **必需的下一技能：** 调用 `comet-build` 技能进入计划和构建阶段。
