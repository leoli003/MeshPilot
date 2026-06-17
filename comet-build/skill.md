---
name: comet-build
description: "Comet 阶段 3: 计划与构建。使用 /comet-build 调用。创建计划并选择执行方法（subagent 或 direct）进行实现。支持 --subagent_limit=N 参数控制子 agent 阈值。"
---

# Comet 阶段 3: 计划与构建

## Subagent Limit

控制步骤 3 中"任务数 ≥ N 时使用 subagent"的阈值 N。

**检测方式：** 检查 `{{PROMPT}}` 是否包含 `--subagent_limit=N`。
如果存在：存储为 SUBAGENT_LIMIT，默认值为 1。

**影响范围：** 仅影响步骤 3 的执行方法推荐/自动选择。

---

## Auto 模式检测

**在开始时检查 `--auto` 标志：**

```
如果 {{PROMPT}} 包含 "--auto"：
  1. 从工作提示中移除 "--auto"
  2. 为此阶段设置 AUTO_MODE=true
  3. 跳过所有 AskUserQuestion 阻塞点
  4. 在每个决策点自动选择推荐选项：
     - 步骤 2：继续执行（选项 A）
     - 步骤 3：创建分支（选项 A）+ 如任务 ≥ SUBAGENT_LIMIT 选 subagent-driven-development，否则选 executing-plans
```

当 `AUTO_MODE=true` 时，此阶段完全自主运行，无需用户确认。

---

## 前置条件

- 设计文档已创建（阶段 2 完成）
- 存在活跃变更

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
"$COMET_BASH" "$COMET_STATE" check <name> build
```

验证通过后进入步骤 1。验证失败时脚本输出具体失败原因。

**幂等性**：所有 build 阶段操作可以安全重新执行。读取 `.comet.yaml` 的 `phase` 字段确认仍处于 build，读取计划文件头的 `base-ref`，然后读取 tasks.md 找到第一个未勾选任务。已提交的任务不得重新提交。

### 1. 创建计划

**首先读取序号和中文标题：**

```bash
SEQUENCE=$("$COMET_BASH" "$COMET_STATE" get <name> sequence)
CHINESE_TITLE=$("$COMET_BASH" "$COMET_STATE" get <name> chinese_title)
```

**立即执行：** 使用 Skill 工具加载 Superpowers `writing-plans` 技能。禁止跳过此步骤。

技能加载后，按照其指导创建计划。计划要求：
- 保存到 `docs/superpowers/plans/<sequence>-<chinese_title>-计划.md`
- 示例: `docs/superpowers/plans/0004-挡板碰撞粒子效果-计划.md`
- 参考设计文档，分解为可执行任务
- **计划文件头必须包含关联元数据**：

```yaml
---
change: <openspec-change-name>
design-doc: docs/superpowers/specs/<sequence>-<chinese_title>-设计.md
base-ref: <实现前的 git rev-parse HEAD>
---
```

`base-ref` 用于验证时测量整个实现范围的已提交变更。创建计划时记录当前提交：

```bash
git rev-parse HEAD
```

### 2. 更新计划状态并提供 Plan-Ready 暂停点

记录计划路径：

```bash
# 读取序号和中文标题
SEQUENCE=$("$COMET_BASH" "$COMET_STATE" get <name> sequence)
CHINESE_TITLE=$("$COMET_BASH" "$COMET_STATE" get <name> chinese_title)

# 构建计划路径
PLAN_PATH="docs/superpowers/plans/${SEQUENCE}-${CHINESE_TITLE}-计划.md"

"$COMET_BASH" "$COMET_STATE" set <name> plan "$PLAN_PATH"
```

无需手动更新阶段 — 退出条件满足时 guard 自动转换。

计划记录后，立即提供新的用户决策点：

| 选项 | 行为 | 描述 |
|------|------|------|
| A | 继续执行 | 保持在当前模型，进入步骤 3 选择工作区隔离和执行方法 |
| B | 暂停以切换模型 | 记录 `build_pause: plan-ready`，停止本次 `/comet-build` 调用，允许用户稍后从 `/comet` 或 `/comet-build` 恢复 |

**如果 AUTO_MODE=true：**
- 跳过 AskUserQuestion
- 自动选择"继续执行"（选项 A）
- 记录日志："[Auto Mode] 自动选择继续执行"
- 直接进入步骤 3

**如果 AUTO_MODE=false（默认）：**
- 这是用户决策点。**必须使用 AskUserQuestion 工具暂停并等待用户明确选择**
- 不得自动继续，不得将暂停写入 `build_mode`

用户选择继续时：

```bash
"$COMET_BASH" "$COMET_STATE" set <name> build_pause null
```

用户选择暂停时：

```bash
"$COMET_BASH" "$COMET_STATE" set <name> build_pause plan-ready
```

设置 `build_pause: plan-ready` 后，停止当前调用。不选择 `isolation` 或 `build_mode`，不加载执行技能。

### 3. 选择工作流配置

如果以 `build_pause: plan-ready` 恢复且 `plan` 文件存在，不重新运行 `writing-plans`。首先告知用户工作流停在 plan-ready 暂停点；用户确认继续后，设置：

```bash
"$COMET_BASH" "$COMET_STATE" set <name> build_pause null
```

然后继续本步骤选择工作区隔离和执行方法。

计划已写入当前分支。开始执行前，**在单次交互中询问用户选择工作区隔离和执行方法**：

**工作区隔离**：

| 选项 | 方法 | 描述 |
|------|------|------|
| A | 创建分支 | 在当前仓库创建新分支，简单快速 |
| B | 创建 Worktree | 隔离工作区，完全独立，适合并行开发 |

**推荐规则**：
- 变更涉及 ≤ 3 文件 → 推荐 A
- 需要并行开发，当前分支有未提交工作 → 推荐 B

**执行方法**：

| 选项 | 技能 | 适用场景 |
|------|------|----------|
| A | Superpowers `subagent-driven-development` | 独立任务、高复杂度、需要两阶段审查 |
| B | Superpowers `executing-plans` | 简单任务、无 subagent 环境、轻量快速 |

**执行方法推荐规则**：
- 任务数 ≥ SUBAGENT_LIMIT → 推荐 A
- 任务数 < SUBAGENT_LIMIT 且无跨模块依赖 → 推荐 B
- 来自 hotfix 路径 → 推荐 B

**如果 AUTO_MODE=true：**
- 跳过 AskUserQuestion
- 基于推荐规则自动选择：
  - isolation: branch（选项 A）
  - build_mode: 如任务数 ≥ SUBAGENT_LIMIT 选 subagent-driven-development，否则选 executing-plans
- 记录日志："[Auto Mode] 自动选择 isolation=branch, build_mode=<选中模式>"
- 进入执行隔离和加载执行技能

**如果 AUTO_MODE=false（默认）：**
- 这是用户决策点。**必须使用 AskUserQuestion 工具暂停并等待用户明确选择隔离方法和执行方法**
- 不得基于推荐规则选择 `branch` 或 `worktree`，不得基于推荐规则选择执行方法
- 推荐规则仅供参考，不能替代用户确认
- 不得仅输出文本提示后继续执行

用户选择后，更新 `isolation` 和 `build_mode` 字段：

```bash
"$COMET_BASH" "$COMET_STATE" set <name> isolation <branch|worktree>
"$COMET_BASH" "$COMET_STATE" set <name> build_mode <subagent-driven-development|executing-plans|direct>
```

`isolation` 是脚本强制硬约束。完整工作流 init 可能暂时为 `null`，但仅限本步骤之前。如仍为 `null`，`build → verify` guard 和 `comet-state transition build-complete` 都会失败。

`build_mode` 默认 `direct` 仅适用于 hotfix/tweak 预设。完整工作流不得默认 `direct`。仅当用户明确要求绕过计划执行技能且记录显式覆盖时使用：

```bash
"$COMET_BASH" "$COMET_STATE" set <name> direct_override true
"$COMET_BASH" "$COMET_STATE" set <name> build_mode direct
```

无 `direct_override: true` 时，完整工作流中的 `build_mode=direct` 被 guard 和状态转换同时阻止。

**执行隔离**：

- **branch**：运行 `git checkout -b <change-name>`，后续工作在新分支进行
- **worktree**：必须使用 Skill 工具加载 Superpowers `using-git-worktrees` 技能创建隔离工作区。不要用普通 shell 命令或原生工具绕过此技能；如技能不可用，停止流程并提示安装或启用 Superpowers 技能

创建隔离后，确认计划文件可访问（branch 方式自然可访问；worktree 方式需确认计划已提交）。

**加载执行技能**：使用 Skill 工具加载对应技能。禁止跳过此步骤。

如选中的 Superpowers 技能不可用，停止流程并提示安装或启用对应技能。不要用普通对话替代此步骤。

技能加载后，按照其指导执行：
- 按计划执行任务
- 完成 tasks.md 勾选（`- [ ]` → `- [x]`）
- 每个任务完成后提交代码

### 4. Spec 增量更新

实现过程中发现初始规格不完整时，按规模处理：

| 规模 | 触发条件 | 处理方式 |
|------|----------|----------|
| 小 | 缺少验收场景、边界情况 | 直接编辑 delta spec + design.md，追加 tasks.md 任务 |
| 中 | 接口变更、新组件、数据流变更 | **必须使用 AskUserQuestion 工具暂停并等待用户明确确认**，然后必须使用 Skill 工具加载 Superpowers `brainstorming` 技能更新设计文档 + delta spec |
| 大 | 全新能力需求 | **必须使用 AskUserQuestion 工具暂停并等待用户明确确认拆分**；用户确认后，通过 `/comet-open` 创建独立变更 |

**50% 阈值判定**：以 tasks.md 初始任务数为基准，如新任务超过总数的一半，视为超出原计划范围，**必须使用 AskUserQuestion 工具暂停并等待用户决定是否拆分为新变更**。不得仅输出文本提示后继续执行。

创建独立变更时，必须调用 `/comet-open`，不得直接调用 `/opsx:new`。`/comet-open` 同时创建 OpenSpec 产物和 `.comet.yaml`，防止新变更脱离 Comet 状态机。

**原则**：
- delta spec 是活文档，本阶段可随时修改
- 每次更新应提交，commit message 解释变更原因
- 不要提前同步到 main spec，归档时统一同步
- 小规模增量直接编辑 delta spec 时，在 commit message 中备注，便于归档时进行设计文档漂移评估

### 5. 上下文管理

Build 是最长阶段，可能跨越多个任务。支持上下文压缩后恢复：

- **每个任务后**：立即勾选 tasks.md 并提交代码，使 `.comet.yaml` 和文件状态持久化
- **上下文压缩后**：首先运行 `"$COMET_BASH" "$COMET_STATE" check <change-name> build --recover` — 脚本输出结构化恢复上下文（isolation/build_mode 状态、计划路径、任务进度、恢复操作）。按 Recovery action 确定下一步
- **用户手动变更恢复**：通过 `comet/reference/dirty-worktree.md` 处理未提交更改。该协议定义检查、归属和禁止事项。Build 特定处理：
  1. 归属后，如 diff 暗示计划或规格变更，按步骤 4 "Spec 增量更新" 处理
- **长任务拆分**：如单个任务超过 200 行代码变更，考虑拆分为多个子任务和提交

## 退出条件

### 任务追踪检查

**⛔ 进入 Verify 前，必须确认 tasks.md 全部勾选！**

检查清单：
- [ ] 所有任务已从 `- [ ]` 更新为 `- [x]`
- [ ] 如有未完成任务，返回继续执行或说明原因
- [ ] tasks.md 状态与实际实现一致

<IMPORTANT>
禁止在 tasks.md 未全部勾选时进入 Verify 阶段。
违反此规则将导致进度追踪失效。
</IMPORTANT>

### 其他退出条件

- 代码已提交
- 项目特定的构建/测试已显式运行并通过；不要仅依赖 guard 自动检测
- `isolation` 已写入为 `branch` 或 `worktree`
- `build_mode` 已写入为 `subagent-driven-development`、`executing-plans` 或带显式覆盖的 `direct`
- **阶段 guard**：运行 `"$COMET_BASH" "$COMET_GUARD" <change-name> build --apply`；全部通过后状态推进到 `phase: verify`

Guard 优先读取项目命令配置：

```yaml
build_command: <构建命令>
verify_command: <验证命令>
```

配置可存在于变更的 `.comet.yaml`，或仓库根目录的 `.comet.yaml` / `comet.yaml` / `.comet.yml` / `comet.yml`。

仅当未配置命令时，guard 回退到 `npm run build`、Maven 或 Cargo 自动检测。命令失败时，guard 打印命令输出作为调试证据。

退出前运行 guard 自动转换：

```bash
"$COMET_BASH" "$COMET_GUARD" <change-name> build --apply
```

状态文件自动更新为 `phase: verify`、`verify_result: pending`。

## 自动转换

退出条件满足后（包括用户选择工作流配置），自动转换到下一阶段：

> **必需的下一技能：** 调用 `comet-verify` 技能进入验证和完成阶段。
