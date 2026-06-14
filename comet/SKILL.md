---
name: comet
description: "Comet — OpenSpec + Superpowers 双星开发工作流。使用 /comet 启动，自动检测阶段并分发到子命令。五个阶段：open → design → build → verify → archive。"
argument-hint: "[--ralph] [--auto] [--no-deslop] [--critic=architect|critic|codex] <任务描述>"
---

# Comet — OpenSpec + Superpowers 双星开发工作流

OpenSpec 和 Superpowers 围绕同一个目标运行，如同双星系统。

```
OpenSpec 处理 WHAT — 大纲、提案、规格生命周期、归档
Superpowers 处理 HOW — 技术设计、计划、执行、收尾
```

**核心原则：头脑风暴不可跳过。每个变更都必须经过深度设计（hotfix 和 tweak 预设除外）。**

---

## Ralph 模式

当传入 `--ralph` 标志（例如 `/comet --ralph <任务描述>`）时，Comet 将其工作流包裹在 Ralph 的 PRD 驱动持久循环中：

**检测方式：** 检查 `{{PROMPT}}` 是否包含 `--ralph`。如果存在：
1. 从工作提示中移除 `--ralph`
2. 创建 PRD，包含以下源自 Comet 各阶段的用户故事：
   - US-001: Open 阶段完成（proposal.md、design.md、tasks.md 创建并确认）
   - US-002: Design 阶段完成（设计文档创建并确认）
   - US-003: Build 阶段完成（实现完成，tasks.md 全部勾选）
   - US-004: Verify 阶段完成（验证通过，分支处理完成）
   - US-005: **用户需求验证**（提供实际测试/证据证明原始用户需求已满足）
   - US-006: Archive 阶段完成（变更归档）
3. 执行标准 Ralph 迭代循环（Ralph SKILL.md 的步骤 2-9）
4. 每个故事的验收标准包含对应 Comet 阶段的退出条件
5. **US-005 验收标准必须包含证明用户原始需求已满足的具体证据**（例如：修复 bug 时需有实际测试显示 bug 已修复；新增功能时需演示功能按预期工作）
6. 在第 7 步审批后运行强制 deslop 清理（除非指定 `--no-deslop`）
7. 如提供 `--critic` 则使用其选择（默认：architect）

**Ralph 模式流程：**
```
/comet --ralph <任务>
  ↓ 移除 --ralph，创建 PRD
  ↓ Ralph 迭代循环
  ├── US-001: Open 阶段 → 验证 → passes: true
  ├── US-002: Design 阶段 → 验证 → passes: true
  ├── US-003: Build 阶段 → 验证 → passes: true
  ├── US-004: Verify 阶段 → 验证 → passes: true
  ├── US-005: 用户需求验证 → 实际测试/证据 → passes: true
  └── US-006: Archive 阶段 → 验证 → passes: true
  ↓ 所有故事通过 → architect/critic 验证
  ↓ Deslop 清理
  ↓ /oh-my-claudecode:cancel
```

**Ralph 模式优势：**
- 阶段失败时自动重试
- PRD 驱动的进度跟踪
- 完成前强制验证
- **强制用户需求验证（US-005）— 不仅是流程完成**
- 跨迭代持久状态
- 通过 deslop 清理干净完成

---

## Auto 模式

当传入 `--auto` 标志（例如 `/comet --auto <任务描述>`）时，Comet 跳过所有用户确认提示，在每个决策点自动选择推荐/合理的默认选项。

**检测方式：** 检查 `{{PROMPT}}` 是否包含 `--auto`。如果存在：
1. 从工作提示中移除 `--auto`
2. 继续执行所有阶段，无需请求用户确认
3. 在每个 AskUserQuestion 阻塞点，自动选择推荐选项

**Auto 模式决策默认值：**

| 阻塞点 | 自动选择 | 原因 |
|--------|----------|------|
| Open 阶段评审 | "确认，进入下一阶段" | 接受生成的产物 |
| Design 阶段确认 | 用户选择的选项或第一个推荐项 | 接受设计提案 |
| Build: 隔离选择 | "创建分支" (branch) | 简单、快速，推荐用于 ≤3 文件 |
| Build: 执行方法 | "subagent-driven-development" | 推荐用于 ≥3 任务 |
| Verify: 分支处理 | "合并到主分支" (merge to main) | 标准完成流程 |
| Verify 失败: 修复或接受 | "全部修复" | 继续修复问题 |

**Auto 模式 + Ralph 模式：**
当同时使用 `--auto` 和 `--ralph`（例如 `/comet --ralph --auto <任务>`）时：
- Ralph 包裹 Comet 工作流
- Auto 模式应用于每个 Comet 阶段内部
- 任何阻塞点都无需用户确认
- 从开始到归档完全自主执行

**Auto 模式流程：**
```
/comet --auto <任务>
  ↓ 移除 --auto
  ↓ Open 阶段 → 自动确认 → 继续
  ↓ Design 阶段 → 自动确认 → 继续
  ↓ Build 阶段 → 自动选择分支 + subagent → 执行
  ↓ Verify 阶段 → 自动合并到主分支 → 继续
  ↓ Archive 阶段 → 完成
```

**Auto 模式优势：**
- 完全自主执行
- 无需手动干预
- 更快完成简单变更
- 适合 CI/CD 集成或批量处理

**Auto 模式注意事项：**
- 无法在执行中途回滚决策
- 可能选择不符合用户偏好的选项
- 仅在默认值可接受时使用

---

## 决策核心

代理只需阅读本节即可进行决策。需要时参考参考附录。

### 自动阶段检测

**步骤 0：活跃变更发现与意图检测**

1. 首先检测预设；如果 hotfix/tweak 匹配，直接调用对应的预设技能，不进入正常 open 分支
2. 当没有预设匹配时，运行 `openspec list --json` 获取所有活跃变更

**预设检测具有最高优先级**：
- 用户明确描述 bug 修复 / hotfix + 满足 hotfix 条件 → 直接调用 `/comet-hotfix`
- 用户明确描述文案/配置/文档/prompt 小调整 + 满足 tweak 条件 → 直接调用 `/comet-tweak`
- 无预设匹配 → 按下表处理

| 活跃变更数 | 用户输入 | 行为 |
|------------|----------|------|
| 无 | 非预设输入 | → 调用 `/comet-open` |
| 正好 1 个 | `/comet <描述>` | → **询问**：继续此变更还是创建新变更 |
| 多个 | `/comet <描述>` | → **询问**：继续现有还是创建新；如继续，列出变更供选择 |
| 正好 1 个 | `/comet` 无描述 | → 自动选择，进入步骤 1 |
| 多个 | `/comet` 无描述 | → 列出变更供用户选择 |

<IMPORTANT>
当用户选择"创建新变更"时，**必须调用 `/comet-open`**。不要直接调用 `/opsx:new`。
`/comet-open` 执行双重初始化：OpenSpec 产物（由内部 `/opsx:new` 创建）加上 `.comet.yaml` 状态文件。
直接调用 `/opsx:new` 会导致 `.comet.yaml` 缺失，破坏后续阶段检测。
</IMPORTANT>

**步骤 1：读取 `.comet.yaml` 状态元数据**

优先读取 `openspec/changes/<name>/.comet.yaml`。如果不可用，回退到 `openspec status --change "<name>" --json`、`tasks.md` 和 `docs/superpowers/` 文件检查。

**恢复规则**：
- 每次上下文恢复时，重新运行步骤 0 和步骤 1；不要信任对话历史进行阶段检测
- 如果有活跃变更且工作区有未提交更改，通过 `comet/reference/dirty-worktree.md` 处理。该协议定义了检查、归属和禁止事项；本文件不重复
- 如果 `phase: build`，首先检查 `build_pause`、`plan`、`build_mode` 和 `isolation`：
  - 如果 `build_pause: plan-ready` 且计划文件存在，返回 `/comet-build` 的 plan-ready 恢复点，提示用户继续选择隔离和执行方法，不要重新生成计划
  - 如果 `build_pause: plan-ready` 但计划文件缺失，返回 `/comet-build` 处理损坏状态或重新生成计划
  - 如果 `build_mode` 或 `isolation` 未设置，返回对应的 `/comet-build` 步骤补充后再执行
  - 如果都已设置，从 tasks.md 读取下一个未勾选任务并继续
- 如果 `phase: verify` 且 `verify_result: fail`，进入验证失败决策阻塞点：暂停并询问用户是修复还是接受偏差；只有在用户选择修复后，运行 `"$COMET_BASH" "$COMET_STATE" transition <name> verify-fail` 并调用 `/comet-build`
- 如果 `phase: open` 但 proposal/design/tasks 已完成，首先运行 `"$COMET_BASH" "$COMET_GUARD" <change-name> open --apply` 修复状态，然后继续检测
- 如果 `phase: archive`，仅调用 `/comet-archive`；归档成功后，变更移动到归档目录，所以不要对旧的活跃目录运行 guard

**步骤 2：阶段判定**（按顺序检查，首次匹配生效）

1. `archived: true` 或变更已移动到归档 → 工作流完成
2. `verify_result: pass` 且 `archived` 不是 `true` → 调用 `/comet-archive`
3. `verify_result: fail` → 进入验证失败决策阻塞点（暂停并询问修复或接受偏差；只有用户选择修复后，运行 `verify-fail` 然后 `/comet-build`）
4. `phase: verify` 或 tasks.md 全部勾选 → 调用 `/comet-verify`
5. `phase: build` 或有设计文档但计划/执行未完成 → 按工作流路由：`hotfix` → `/comet-hotfix`，`tweak` → `/comet-tweak`，`full` → `/comet-build`
6. `phase: design` 或有变更但无设计文档 → 调用 `/comet-design`
7. `phase: open` 或存在活跃变更但 `.comet.yaml` 缺失 → 调用 `/comet-open`
8. 无活跃变更 → 调用 `/comet-open`

如果元数据与文件状态冲突，以可验证的文件状态为真实来源，并在继续前修正 `.comet.yaml`。

### 预设升级条件

**hotfix → full**（满足任一条件即升级）：
- 变更涉及 **3+ 文件**
- 架构变更（新模块、新接口、新依赖）
- 数据库 schema 变更
- 修复引入新的公共 API
- 修复范围超出单个函数/模块

**tweak → full**（满足任一条件即升级）：
- 变更涉及 **5+ 文件**
- 需要跨模块协调
- 需要 **5+** 新测试用例
- 配置项新增或删除（非值修改）

### 错误处理快速参考

| 场景 | 处理方式 |
|------|----------|
| `openspec list --json` 失败 | 检查 openspec 是否安装，提示用户运行 `openspec init` |
| 子技能不可用 | 停止工作流，提示安装或启用对应技能 |
| `.comet.yaml` 格式错误或缺失 | 以文件状态为真实来源，用 `"$COMET_BASH" "$COMET_STATE" set` 修正后继续 |
| 构建/测试失败 | 返回 build 阶段修复，不进入 verify |
| 变更目录结构不完整 | 按 `comet-open` 产物要求填充缺失文件 |

### 阶段转换

<IMPORTANT>
单次 `/comet` 调用从检测到的阶段开始，当退出条件满足时自动推进到下一阶段。

流转链：open → design → build → verify → archive

**持续执行要求**：从检测到的阶段开始，代理自动继续所有后续阶段。但**自动推进仅适用于无用户决策的转换点**。遇到用户决策点时，**必须使用 AskUserQuestion 工具暂停并等待用户明确响应**。不得使用推荐规则、默认值或历史偏好替代用户确认，也不得仅输出文本提示后继续执行。

**决策点是阻塞点**（除非设置 `--auto`）：每当到达以下任一节点，当前 `/comet` 调用必须停止，**使用 AskUserQuestion 工具等待用户选择**。只有用户明确选择后，才能写入对应状态字段并执行操作，然后恢复自动推进。

**当设置 `--auto` 时**：所有决策点使用上文 Auto 模式定义的默认值自动解决。各子技能检测 `--auto` 并跳过 AskUserQuestion 调用，改为记录自动选择。

需要用户参与的节点（仅在这些节点暂停）：
1. Open 阶段 proposal/design/tasks 审查和确认
2. 头脑风暴期间确认设计方案
3. Build 阶段 plan-ready 暂停选择，随后是工作流配置选择（隔离 + 执行方法）
4. verify 失败时决定修复还是接受偏差（包括 Spec 偏差处理）
5. finishing-branch 时选择分支处理方法
6. 遇到升级条件（hotfix/tweak → full 工作流）
7. Build 阶段范围扩大需要重新设计或拆分新变更

代理不应跳过这些决策点；其他明确的阶段转换必须自动进行，不得中途退出。在决策点，**文本输出不得替代基于工具的等待 — 必须通过 AskUserQuestion 明确获取用户选择后才能继续**。

**红旗警示** — 当出现以下想法时，停止并检查：

| 代理想法 | 实际风险 |
|----------|----------|
| "用户可能会同意这个方案" | 不能替用户决定 — 使用 AskUserQuestion |
| "这是小改动，不需要确认" | 决策点没有大小例外 — 阻塞点必须等待 |
| "用户上次选了 A，所以这次也选 A" | 历史偏好不能替代当前确认 |
| "我解释了计划，用户没有反对" | 没有反对 ≠ 同意 — 必须使用工具获取明确选择 |
| "流程已经到这里了，应该没问题" | 验证未通过 ≠ 通过 — 检查 verify_result |
</IMPORTANT>

---

## 子命令快速参考

| 命令 | 阶段 | 负责方 | 产物 |
|------|------|--------|------|
| `/comet-open` | 1. Open | OpenSpec | proposal.md, design.md, tasks.md |
| `/comet-design` | 2. 深度设计 | Superpowers | 设计文档, delta spec |
| `/comet-build` | 3. 计划与构建 | Superpowers | 实现计划, 代码提交 |
| `/comet-verify` | 4. 验证与关闭 | 双方 | 验证报告, 分支处理 |
| `/comet-archive` | 5. 归档 | OpenSpec | delta→main spec 同步, 设计文档标记, 归档 |
| `/comet-hotfix` | 预设路径 | 双方 | 快速修复（跳过头脑风暴） |
| `/comet-tweak` | 预设路径 | 双方 | 小调整（跳过头脑风暴和完整计划） |

```
/comet
  ↓ 自动检测
/comet-open ──→ /comet-design ──→ /comet-build ──→ /comet-verify ──→ /comet-archive
  (OpenSpec)      (Superpowers)     (Superpowers)     (双方)          (OpenSpec)

/comet-hotfix (预设，跳过头脑风暴)
  open ──→ build ──→ verify ──→ archive
    ↑ 如触发升级 → 阻塞确认 → 补充设计文档 → 返回完整工作流

/comet-tweak (预设，跳过头脑风暴和完整计划)
  open ──→ 轻量 build ──→ 轻量 verify ──→ archive
    ↑ 如触发升级 → 阻塞确认 → 补充设计文档 → 返回完整工作流
```

---

## 参考附录

### .comet.yaml 字段参考

```yaml
workflow: full
phase: build
design_doc: docs/superpowers/specs/YYYY-MM-DD-topic-design.md
plan: docs/superpowers/plans/YYYY-MM-DD-feature.md
base_ref: a1b2c3d4e5f6...
build_mode: subagent-driven-development
build_pause: null
isolation: branch
verify_mode: light
verify_result: pending
verification_report: null
branch_status: pending
created_at: 2026-05-26
verified_at: null
archived: false
```

| 字段 | 含义 |
|------|------|
| `workflow` | `full`、`hotfix` 或 `tweak` |
| `phase` | 当前阶段：`open`、`design`、`build`、`verify`、`archive`（init 统一设为 `open`，guard 处理转换） |
| `design_doc` | 关联的 Superpowers 设计文档路径，可为空 |
| `plan` | 关联的 Superpowers 计划路径，可为空 |
| `base_ref` | init 时记录的 Git 提交 SHA，用于规模评估。作为无计划时的回退 |
| `build_mode` | 选择的执行方法，可为空 |
| `build_pause` | Build 阶段内部暂停点。`null` 表示无暂停；`plan-ready` 表示计划已生成且用户选择暂停切换模型 |
| `isolation` | `branch` 或 `worktree`，工作区隔离方式。完整工作流 init 可能暂时为 `null`，但仅限 `/comet-build` 步骤 3 之前；hotfix/tweak 默认为 `branch` |
| `verify_mode` | `light` 或 `full`，可为空 |
| `verify_result` | `pending`、`pass` 或 `fail` |
| `verification_report` | 验证报告文件路径；verify 通过前必须指向现有文件 |
| `branch_status` | `pending` 或 `handled`；分支处理完成后设为 `handled` |
| `created_at` | 变更创建日期（init 时自动设置），格式 `YYYY-MM-DD` |
| `verified_at` | 验证通过时间，可为空 |
| `archived` | 变更是否已归档 |

可选字段：

| 字段 | 含义 |
|------|------|
| `direct_override` | `true`/`false`。完整工作流仅当显式为 `true` 时才可使用 `build_mode: direct` |
| `build_command` | 项目构建命令。Guard 优先运行此命令并打印失败输出 |
| `verify_command` | 项目验证命令。Verify guard 优先运行此命令；如缺失则回退到构建命令 |

状态机硬约束：
- `build → verify` 之前，`isolation` 必须为 `branch` 或 `worktree`
- `build → verify` 之前，`build_mode` 必须已选择
- `build_mode: direct` 默认仅允许 `hotfix` / `tweak`；完整工作流需要 `direct_override: true`
- `build_pause` 不是执行方法，不得写入 `build_mode`
- 这些约束由 `comet-guard.sh build --apply` 和 `comet-state.sh transition <name> build-complete` 共同强制执行

### 脚本位置

Comet 脚本分布在 `comet/scripts/`。**不要硬编码路径** — 定位一次，缓存到环境变量：

```bash
COMET_ENV="${COMET_ENV:-$(find . "$HOME"/.*/skills "$HOME/.config" "$HOME/.gemini" -path '*/comet/scripts/comet-env.sh' -type f -print -quit 2>/dev/null)}"
if [ -z "$COMET_ENV" ]; then
  echo "ERROR: comet-env.sh not found. Ensure the comet skill is installed." >&2
  return 1
fi
. "$COMET_ENV"

# 脚本定位失败时停止工作流
if [ -z "$COMET_GUARD" ] || [ -z "$COMET_STATE" ] || [ -z "$COMET_HANDOFF" ] || [ -z "$COMET_ARCHIVE" ]; then
  echo "ERROR: Comet scripts not found. Ensure the comet skill is installed." >&2
  echo "Expected path pattern: */comet/scripts/comet-*.sh under project or platform skill directories" >&2
  return 1
fi
```

**自动状态更新**：Guard 支持 `--apply` 标志，检查通过后自动更新 `.comet.yaml` 状态字段：

```bash
"$COMET_BASH" "$COMET_GUARD" <change-name> <phase> --apply
```

`--apply` 委托给 `comet-state transition`。当需要直接表达状态变更时使用这些语义事件：

```bash
"$COMET_BASH" "$COMET_STATE" transition <change-name> open-complete
"$COMET_BASH" "$COMET_STATE" transition <change-name> design-complete
"$COMET_BASH" "$COMET_STATE" transition <change-name> build-complete
"$COMET_BASH" "$COMET_STATE" transition <change-name> verify-pass
"$COMET_BASH" "$COMET_STATE" transition <change-name> verify-fail
"$COMET_BASH" "$COMET_STATE" transition <archive-name> archived
```

**归档脚本**：一条命令完成所有归档步骤：

```bash
"$COMET_BASH" "$COMET_ARCHIVE" <change-name>
```

加载 comet 后，代理应运行一次上述变量赋值，然后在会话中复用 `$COMET_GUARD`、`$COMET_STATE`、`$COMET_HANDOFF`、`$COMET_ARCHIVE`。

### 文件结构

```
openspec/                              # OpenSpec — WHAT
├── config.yaml
├── changes/
│   ├── <name>/                        # 活跃变更
│   │   ├── .openspec.yaml
│   │   ├── .comet.yaml
│   │   ├── proposal.md                # Why + What
│   │   ├── design.md                  # 高层架构决策
│   │   ├── specs/<capability>/spec.md # Delta 能力规格
│   │   ├── .comet/handoff/            # 脚本生成的阶段交接包
│   │   └── tasks.md                   # 任务清单
│   └── archive/0001<name>/            # 已归档（序号前缀）
└── specs/<capability>/spec.md         # 主规格（归档时从 delta 覆盖）

docs/superpowers/                      # Superpowers — HOW
├── specs/YYYY-MM-DD-<topic>-design.md # 设计文档（技术 RFC，归档时标记状态）
└── plans/YYYY-MM-DD-<feature>.md      # 实现计划（文件头包含变更关联元数据）
```

### 最佳实践

1. **头脑风暴不可跳过** — 每个变更都必须经过深度设计（hotfix 和 tweak 除外）
2. **delta spec 是活文档** — 在阶段 3 中可自由修改，归档时同步
3. **交接包由脚本生成** — OpenSpec → Superpowers 上下文必须通过 `comet-handoff.sh` 生成紧凑可追溯摘录（需要时使用 `--full`），并由 guard 验证 source/hash/mode
4. **保持 tasks.md 同步** — 每完成一个任务就勾选
5. **频繁提交** — 每个任务一次提交，提交信息反映设计意图
6. **归档前验证** — 只有 `/comet-verify` 通过后才执行 `/comet-archive`
7. **分类增量更新** — 小编辑、中等头脑风暴、大新变更
8. **计划必须关联变更** — 文件头包含 `change:` 和 `design-doc:` 元数据
9. **归档闭环** — 设计文档和计划必须标记 `archived-with` 状态
10. **修改现有功能** — 直接打开新变更
11. **预设有限制** — 当 hotfix/tweak 满足升级条件时及时切换到完整工作流
