---
name: comet-open
description: "Comet 阶段 1: Open。使用 /comet-open 调用。通过 OpenSpec 探索想法，创建变更结构（proposal + design + tasks）。"
---

# Comet 阶段 1: Open

## Auto 模式检测

**在开始时检查 `--auto` 标志：**

```
如果 {{PROMPT}} 包含 "--auto"：
  1. 从工作提示中移除 "--auto"
  2. 为此阶段设置 AUTO_MODE=true
  3. 跳过所有 AskUserQuestion 阻塞点
  4. 在步骤 5 自动选择"确认，进入下一阶段"
```

当 `AUTO_MODE=true` 时，此阶段完全自主运行，无需用户确认。

---

## 前置条件

- 无活跃变更，或用户希望创建新变更

## 步骤

### 1. 探索想法

**立即执行：** 使用 Skill 工具加载 `openspec-explore` 技能。禁止跳过此步骤。

技能加载后，按照其指导自由探索问题空间。

### 2. 创建变更结构 + 初始化状态

**立即执行：** 使用 Skill 工具加载 `openspec-new-change` 技能。如果用户意图不明确需要先形成提案，改为加载 `openspec-propose`。禁止跳过此步骤。

**命名和范围守卫**：变更名称必须使用用户指定或通过 AskUserQuestion 确认的名称 — 不得自动生成或推断。变更范围必须匹配用户描述 — 不得独立扩大或缩小。

确认以下产物已创建：

```
openspec/changes/<name>/
├── .openspec.yaml
├── .comet.yaml
├── proposal.md       # Why + What: 问题、目标、范围
├── design.md         # How（高层）: 架构决策、方案选择
└── tasks.md          # 任务清单（复选框）
```

创建 `.comet.yaml` 状态文件：

```bash
COMET_ENV="${COMET_ENV:-$(find . "$HOME"/.*/skills "$HOME/.config" "$HOME/.gemini" -path '*/comet/scripts/comet-env.sh' -type f -print -quit 2>/dev/null)}"
if [ -z "$COMET_ENV" ]; then
  echo "ERROR: comet-env.sh not found. Ensure the comet skill is installed." >&2
  return 1
fi
. "$COMET_ENV"

if [ -z "$COMET_STATE" ] || [ -z "$COMET_GUARD" ]; then
  echo "ERROR: Comet scripts not found. Ensure the comet skill is installed." >&2
  return 1
fi

"$COMET_BASH" "$COMET_STATE" init <name> full
```

### 3. 入口状态验证

验证状态机已正确初始化：

```bash
"$COMET_BASH" "$COMET_STATE" check <name> open
```

验证通过后进入步骤 4。验证失败时脚本输出具体失败原因。

**幂等性**：所有 open 阶段操作可以安全重新执行。如果 `.comet.yaml` 已处于 `phase: open` 且三个产物文件都存在，跳过已完成步骤，从第一个缺失步骤继续。

### 4. 内容完整性检查

确认三个文档内容完整：
- **proposal.md**：问题背景、目标、范围、非目标
- **design.md**：高层架构决策、方案选择、数据流
- **tasks.md**：任务列表，每个任务有清晰描述

**文件存在验证**：确认三个文件路径都存在且非空。如果任何文件缺失或为空，不得进入步骤 5 或执行阶段 guard — 返回创建步骤填补空缺。

### 5. 用户审查和确认（阻塞点）

三个文档创建完成且内容完整性检查通过后：

**如果 AUTO_MODE=true：**
- 跳过 AskUserQuestion
- 自动选择"确认，进入下一阶段"
- 记录日志："[Auto Mode] 自动确认 proposal, design, tasks"
- 直接进入退出条件

**如果 AUTO_MODE=false（默认）：**
- 必须使用 AskUserQuestion 工具暂停并等待用户确认
- 在用户确认前不得执行阶段 guard 或自动转换

AskUserQuestion 必须作为单选题呈现，包含以下摘要和选项：

**摘要内容**：
- **proposal.md**：问题背景、目标、范围
- **design.md**：高层架构决策、方案选择
- **tasks.md**：任务数量和关键任务描述

**选项**：
- "确认，进入下一阶段" — 产物符合预期，执行阶段 guard 转换
- "需要调整" — 包含调整说明，修改后重新请求确认

用户选择"确认"后，进入退出条件。用户选择"需要调整"时，按其说明修改对应文件，然后再次使用 AskUserQuestion 请求确认。

## 退出条件

- proposal.md、design.md、tasks.md 都已创建且内容完整
- **用户已确认** proposal、design、tasks 内容符合预期
- **阶段 guard**：运行 `"$COMET_BASH" "$COMET_GUARD" <change-name> open --apply`；全部通过后自动转换到下一阶段

退出前必须使用 `--apply`，否则 `.comet.yaml` 保持在 `phase: open`，下一阶段入口检查会失败。

```bash
"$COMET_BASH" "$COMET_GUARD" <change-name> open --apply
```

完整工作流自动转换到 `phase: design`；hotfix/tweak 预设自动转换到 `phase: build`。

## 自动转换

用户确认且退出条件满足后，自动转换到下一阶段：

> **必需的下一技能（完整工作流）：** 调用 `comet-design` 技能进入深度设计阶段。
>
> Hotfix/tweak 预设由对应的预设技能控制后续转换（阶段直接进入 build），不经过此部分。
