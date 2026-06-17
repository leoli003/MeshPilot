---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# 完成开发分支

## 概述

通过呈现清晰的选项和处理选定的工作流，指导开发工作的完成。

**核心原则：** 验证测试 → 检测环境 → 呈现选项 → 执行选择 → 清理。

**语言要求：所有输出使用中文编写（标题、描述、说明等），技术术语可保留英文，代码、命令保持英文不变。**

**开始时声明：**"我正在使用 finishing-a-development-branch 技能完成此工作。"

## 验证报告命名规范

**验证报告命名格式**：`序号-中文标题-验证.md`

示例：
- `0004-挡板碰撞粒子效果-验证.md`
- `0005-顶部墙壁碰撞粒子效果-验证.md`

**保存位置**：`docs/superpowers/reports/序号-中文标题-验证.md`

**序号和中文标题来源**：
- 从 `.comet.yaml` 的 `sequence` 和 `chinese_title` 字段读取

## 流程

### 步骤 1: 验证测试

**在呈现选项之前，验证测试通过：**

```bash
# 运行项目测试套件
npm test / cargo test / pytest / go test ./...
```

**如果测试失败：**
```
测试失败（<N> 个失败）。必须在完成前修复：

[显示失败]

测试通过前无法进行合并/PR。
```

停止。不要进入步骤 2。

**如果测试通过：** 继续步骤 2。

### 步骤 2: 检测环境

**在呈现选项之前确定工作区状态：**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

这决定显示哪个菜单以及清理如何工作：

| 状态 | 菜单 | 清理 |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON`（普通仓库） | 标准 4 选项 | 无 worktree 需清理 |
| `GIT_DIR != GIT_COMMON`，命名分支 | 标准 4 选项 | 基于来源（见步骤 6） |
| `GIT_DIR != GIT_COMMON`，分离 HEAD | 简化 3 选项（无合并） | 无清理（外部管理） |

### 步骤 3: 确定基础分支

```bash
# 尝试常见基础分支
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

或询问："此分支从 main 分支 — 正确吗？"

### 步骤 4: 呈现选项

**普通仓库和命名分支 worktree — 呈现这 4 个选项：**

```
实现完成。您想做什么？

1. 本地合并回 <base-branch>
2. 推送并创建 Pull Request
3. 保持分支原样（稍后处理）
4. 放弃此工作

选择哪个选项？
```

**分离 HEAD — 呈现这 3 个选项：**

```
实现完成。您处于分离 HEAD（外部管理工作区）。

1. 推送为新分支并创建 Pull Request
2. 保持原样（稍后处理）
3. 放弃此工作

选择哪个选项？
```

**不要添加解释** - 保持选项简洁。

### 步骤 5: 执行选择

#### 选项 1: 本地合并

```bash
# 获取主仓库根目录以保证 CWD 安全
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"

# 先合并 — 在删除任何内容前验证成功
git checkout <base-branch>
git pull
git merge <feature-branch>

# 在合并结果上验证测试
<测试命令>

# 仅在合并成功后：清理 worktree（步骤 6），然后删除分支
```

然后：清理 worktree（步骤 6），然后删除分支：

```bash
git branch -d <feature-branch>
```

#### 选项 2: 推送并创建 PR

```bash
# 推送分支
git push -u origin <feature-branch>

# 创建 PR
gh pr create --title "<标题>" --body "$(cat <<'EOF'
## 摘要
<2-3 点变更内容>

## 测试计划
- [ ] <验证步骤>
EOF
)"
```

**不要清理 worktree** — 用户需要它来迭代 PR 反馈。

#### 选项 3: 保持原样

报告："保持分支 <名称>。Worktree 保留在 <路径>。"

**不要清理 worktree。**

#### 选项 4: 放弃

**先确认：**
```
这将永久删除：
- 分支 <名称>
- 所有提交: <提交列表>
- Worktree 在 <路径>

输入 'discard' 确认。
```

等待精确确认。

如果确认：
```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

然后：清理 worktree（步骤 6），然后强制删除分支：
```bash
git branch -D <feature-branch>
```

### 步骤 6: 清理工作区

**仅对选项 1 和 4 运行。** 选项 2 和 3 始终保留 worktree。

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

**如果 `GIT_DIR == GIT_COMMON`：** 普通仓库，无 worktree 需清理。完成。

**如果 worktree 路径在 `.worktrees/`、`worktrees/` 或 `~/.config/superpowers/worktrees/` 下：** Superpowers 创建了此 worktree — 我们负责清理。

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git worktree remove "$WORKTREE_PATH"
git worktree prune  # 自愈：清理任何过时注册
```

**否则：** 宿主环境（harness）拥有此工作区。不要删除它。如果您的平台提供工作区退出工具，使用它。否则，保持工作区原样。

## 快速参考

| 选项 | 合并 | 推送 | 保留 Worktree | 清理分支 |
|--------|-------|------|---------------|----------------|
| 1. 本地合并 | 是 | - | - | 是 |
| 2. 创建 PR | - | 是 | 是 | - |
| 3. 保持原样 | - | - | 是 | - |
| 4. 放弃 | - | - | - | 是（强制） |

## 常见错误

**跳过测试验证**
- **问题：** 合并损坏的代码，创建失败的 PR
- **修复：** 提供选项前始终验证测试

**开放式问题**
- **问题：** "接下来应该做什么？" 含义模糊
- **修复：** 精确呈现 4 个结构化选项（或分离 HEAD 的 3 个）

**为选项 2 清理 worktree**
- **问题：** 删除用户迭代 PR 所需的 worktree
- **修复：** 仅对选项 1 和 4 清理

**删除分支前移除 worktree**
- **问题：** `git branch -d` 失败，因为 worktree 仍引用分支
- **修复：** 先合并，移除 worktree，然后删除分支

**从 worktree 内部运行 git worktree remove**
- **问题：** 当 CWD 在被移除的 worktree 内时命令静默失败
- **修复：** 移除 worktree 前始终 `cd` 到主仓库根目录

**清理 harness 拥有的 worktree**
- **问题：** 移除 harness 创建的 worktree 导致幻影状态
- **修复：** 仅清理 `.worktrees/`、`worktrees/` 或 `~/.config/superpowers/worktrees/` 下的 worktree

**放弃时无确认**
- **问题：** 意外删除工作
- **修复：** 要求输入 "discard" 确认

## 红旗

**永远不要：**
- 测试失败时继续
- 合并前不验证结果测试
- 无确认删除工作
- 无明确请求强制推送
- 确认合并成功前移除 worktree
- 清理非您创建的 worktree（来源检查）
- 从 worktree 内部运行 `git worktree remove`

**始终：**
- 提供选项前验证测试
- 呈现菜单前检测环境
- 精确呈现 4 个选项（或分离 HEAD 的 3 个）
- 选项 4 获取输入确认
- 仅对选项 1 和 4 清理 worktree
- worktree 移除前 `cd` 到主仓库根目录
- 移除后运行 `git worktree prune`
