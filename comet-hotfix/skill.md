---
name: comet-hotfix
description: "Comet 预设路径: Bug 修复 / Hotfix。跳过头脑风暴，直接 open → build → verify → archive。适用于行为修复、不涉及新能力设计的场景。支持 --subagent_limit=N 参数控制子 agent 阈值。"
---

# Comet 预设路径: Hotfix

## 中文化要求

**重要**：此技能生成的所有内容应尽可能使用中文：

1. **proposal.md 标题**：使用中文标题（如 `# 修复登录失败问题` 而非 `# Fix Login Failure`）
   - 归档目录名从 proposal.md 第一行提取，中文标题确保归档目录为中文名（如 `0008-修复登录失败问题`）

2. **文件内容**：所有生成的文件内容尽可能使用中文
   - proposal.md：问题描述、根因分析、修复目标使用中文描述
   - design.md：修复方案使用中文描述
   - tasks.md：任务描述使用中文
   - spec.md：需求描述、场景描述使用中文（如有 delta spec）

3. **验证报告**：验证报告内容使用中文

## Auto 模式检测

**在开始时检查 `--auto` 参数：**

```
如果 {{PROMPT}} 包含 "--auto"：
  1. 从工作提示中移除 "--auto"
  2. 为此工作流设置 AUTO_MODE=true
  3. 跳过所有 AskUserQuestion 阻塞点
  4. 在每个决策点自动选择：
     - 升级确认：自动确认升级到完整工作流
     - comet-verify 决策：遵循 comet-verify auto 模式默认值
```

当 `AUTO_MODE=true` 时，此工作流完全自主运行，无需用户确认。

---

---

快速 bug 修复工作流：open → build → verify → archive。跳过头脑风暴和完整计划，适用于不涉及新能力设计的行为修复。

**适用条件**（必须全部满足）：
1. 修复现有功能的 bug，无新能力
2. 无接口变更或架构调整
3. 变更范围可预测（通常 ≤ 2 文件）

**不适用**：如果修复过程发现需要架构调整，应升级到完整 `/comet` 工作流。

---

## 流程（预设工作流，5 步）

执行链：open → build → 根因检查 → verify → archive。Hotfix 为每个阶段提供默认决策：精简 open、直接 build、根因确认、基于规模的验证、验证通过后归档。

开始前定位 Comet 脚本：

```bash
COMET_ENV="${COMET_ENV:-$(find . "$HOME"/.*/skills "$HOME/.config" "$HOME/.gemini" -path '*/comet/scripts/comet-env.sh' -type f -print -quit 2>/dev/null)}"
if [ -z "$COMET_ENV" ]; then
  echo "ERROR: comet-env.sh not found. Ensure the comet skill is installed." >&2
  return 1
fi
. "$COMET_ENV"
```

### 1. 快速 Open（预设 open）

复用 Comet open 能力创建变更，但使用 hotfix 默认值：不执行 `openspec-explore` 长探索，直接进入精简变更创建。

**立即执行：** 使用 Skill 工具加载 `openspec-new-change` 技能。禁止跳过此步骤。

技能加载后，按照其指导创建精简产物：
  - `proposal.md` — 问题描述 + 根因分析 + 修复目标（无需方案对比）
  - `design.md` — 修复方案（一个即可，无需多方案对比）
  - `tasks.md` — 修复任务列表
- **无需 delta spec**（除非修复改变现有规格验收场景）

初始化 Comet 状态文件：

```bash
"$COMET_BASH" "$COMET_STATE" init <name> hotfix
```

验证初始化状态：

```bash
"$COMET_BASH" "$COMET_STATE" check <name> open
```

运行阶段 guard 转换 open → build：

```bash
"$COMET_BASH" "$COMET_GUARD" <change-name> open --apply
```

### 2. 直接 Build（预设 build）

使用 hotfix 默认值：`build_mode: direct`。跳过 Superpowers `brainstorming` 和 `writing-plans`（除非任务 > 3；如超过 3 任务，转交 `/comet-build` 的计划和执行方法选择）。

继续或开始变更前，通过 `comet/reference/dirty-worktree.md` 处理未提交更改。如果归属显示修复范围超出 hotfix，按本文件"升级条件"处理。

**立即执行：** 按 tasks.md 逐个执行任务：

1. 读取 `openspec/changes/<name>/tasks.md`，获取未完成任务列表
2. 对每个未完成任务：
   - 按任务描述修改代码
   - 运行项目格式化工具（如 `mvn spotless:apply`、`npm run format`）
   - 运行相关测试确认通过
   - 在 tasks.md 中勾选对应的 `- [ ]` 为 `- [x]`
   - 提交代码，commit message 格式：`fix: <简要修复描述>`
3. 所有任务完成后，显式运行相关项目测试和构建命令

**如果修复影响现有规格验收场景**：
- 在 `openspec/changes/<name>/specs/<capability>/spec.md` 创建 delta spec
- 只包含 `## MODIFIED Requirements` 章节

### 3. 根因消除检查

**在运行 build guard 之前执行**，确保修复真正消除了根因：

1. 读取 proposal.md 中的 bug 描述和根因
2. 搜索并验证问题代码不再存在
3. 如果根因未消除，返回步骤 2 继续修复（仍在 build 阶段，无需状态转换）

**升级条件**：
- 根因检查发现深层架构问题 → 停止 hotfix，按"升级条件"章节处理
- 修复需要额外接口变更 → 停止 hotfix，按"升级条件"章节处理

根因确认消除后，运行阶段 guard 转换 build → verify：

```bash
"$COMET_BASH" "$COMET_GUARD" <change-name> build --apply
```

状态自动更新为 `phase: verify`、`verify_result: pending`，然后进入验证。

### 4. 验证（预设 verify）

复用 `/comet-verify`，由 comet-verify 的规模评估决定轻量或完整验证。

**立即执行：** 使用 Skill 工具加载 `comet-verify` 技能。禁止跳过此步骤。

无 delta spec 的小规模 hotfix 通常满足轻量验证条件（≤ 3 任务、≤ 2 文件），comet-verify 的规模评估会选择轻量验证路径（5 项快速检查）。如 hotfix 创建了 delta spec，根据 comet-verify 的规模评估规则进入完整验证路径。

验证通过后，按 `/comet-verify` 规则记录 `.comet.yaml` 的 `verify_result` 为 `pass`，归档前不得跳过此状态。

### 5. 归档（预设 archive）

复用 `/comet-archive`。归档前 `.comet.yaml` 必须满足 `verify_result: pass`。

**立即执行：** 使用 Skill 工具加载 `comet-archive` 技能进行归档。禁止跳过此步骤。
如有 delta spec，按 comet-archive 规则同步到主 spec，并处理关联设计文档和计划的归档标注。

---

## 持续执行模式

<IMPORTANT>
Hotfix 工作流是**一次性持续执行**。调用 `/comet-hotfix` 后，代理必须自动推进各 hotfix 步骤，不得中途暂停等待用户输入。但以下情况必须暂停等待用户确认：

1. 遇到升级条件（见"升级条件"章节）。**必须使用 AskUserQuestion 工具暂停并等待用户明确确认**升级到完整工作流
2. 任务超过 3 个时的工作区隔离和执行方法选择，转交 `/comet-build`
3. verify 阶段（comet-verify）的验证失败和分支处理决策

执行顺序：快速 open → 直接 build → 根因检查 → 验证 → 归档 → 完成

每个步骤完成后立即进入下一步。在每个阶段内部，仍需按上述要求调用对应的 Comet/OpenSpec/Superpowers 技能；如调用的技能有自身用户决策点，遵循该技能规则。
</IMPORTANT>

---

## 升级条件

满足**任一**以下条件时升级到完整 `/comet`：

| 条件 | 说明 |
|------|------|
| 变更涉及 **3+ 文件** | 超出单点修复范围 |
| 架构变更 | 新模块、新接口、新依赖 |
| 数据库 schema 变更 | 结构调整 |
| 引入新的公共 API | 修复创建了新的外部接口 |
| 修复范围超出单个函数/模块 | 需要协调变更 |

满足升级条件时：

**如果 AUTO_MODE=true：**
- 跳过 AskUserQuestion
- 自动确认升级到完整 `/comet` 工作流
- 记录日志："[Auto Mode] 自动确认升级到完整工作流"
- 继续执行 workflow 字段更新和设计文档补充

**如果 AUTO_MODE=false（默认）：**
- 必须使用 AskUserQuestion 工具暂停并等待用户明确确认升级到完整 `/comet` 工作流
- 不得直接进入 `/comet-design`，也不得自动补充设计文档
- 不得仅输出文本提示后继续执行

用户确认升级后，**必须先更新 workflow 字段**再进入完整流程：

```bash
"$COMET_BASH" "$COMET_STATE" set <name> workflow full
```

然后在当前变更基础上，补充设计文档：**立即使用 Skill 工具加载 `comet-design` 技能**，正常进入完整工作流。如用户未确认升级，停止 hotfix 并报告当前变更已超出 hotfix 范围。

**注意**：升级时传递 --subagent_limit 参数（如有）。

---

## 退出条件

- Bug 已修复，测试通过
- 变更已归档
- 如有规格变更，已同步到主 spec
- **阶段 guard**：build → verify 前运行 `"$COMET_BASH" "$COMET_GUARD" <change-name> build --apply`；verify → archive 前遵循 `/comet-verify` 并运行 `"$COMET_BASH" "$COMET_GUARD" <change-name> verify --apply`
