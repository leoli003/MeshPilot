---
name: comet-archive
description: "Comet 阶段 5: 归档。使用 /comet-archive 调用。同步 delta spec 到主 spec，归档变更。"
---

# Comet 阶段 5: 归档

## 前置条件

- 验证已通过（阶段 4 完成）
- 分支已处理
- `openspec/changes/<name>/.comet.yaml` 中 `verify_result: pass`

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
"$COMET_BASH" "$COMET_STATE" check <name> archive
```

验证通过后进入步骤 1。验证失败时脚本输出具体失败原因。

### 1. 执行归档

运行归档脚本自动完成所有步骤：

```bash
"$COMET_BASH" "$COMET_ARCHIVE" "<change-name>"
```

脚本自动执行：
1. 入口状态验证（phase=archive, verify_result=pass, archived=false）
2. Delta spec 同步到主 spec（覆盖）
3. 设计文档 frontmatter 标注（archived-with, status）
4. 计划 frontmatter 标注（archived-with）
5. 移动变更到归档目录
6. 通过 `comet-state transition <archive-name> archived` 更新 `archived: true`

如脚本返回非零退出码，报告错误并停止。
如脚本返回零退出码，归档完成。
摘要 `X/Y steps succeeded` 统计实际执行步骤，不对 delta spec 同步或文档标注重复计数。

当 delta spec 与现有主 spec 不同时，脚本在覆盖前打印 unified diff 预览，帮助确认归档同步内容。

使用 `--dry-run` 标志预览而不执行。

### 2. 归档命名规则

归档目录命名格式：**`0001-中文标题`**（4位递增序号 + 连字符 + 中文标题）

- 序号自动递增：扫描现有归档目录，找到最大序号后 +1
- 中文标题从 `proposal.md` 第一行提取（去掉 `# ` 前缀）
- 例如：`0001-HTML5打砖块游戏`、`0002-主题切换`

**注意**：旧归档使用日期格式（如 `2026-06-10-xxx`），新归档使用序号格式。脚本会自动忽略日期格式的序号（>= 2000 视为年份）。

### 3. 生命周期闭环

规格生命周期在此完成：
```
头脑风暴 → delta spec → 实现 → 验证 → 主 spec 覆盖 → 设计文档标注 → 归档
```

## 退出条件

- 归档脚本执行成功（退出码 0）
- 归档目录 `openspec/changes/archive/0001-中文标题/` 存在
- 归档的 `.comet.yaml` 包含 `archived: true`

归档脚本将 `openspec/changes/<name>/` 移动到 `openspec/changes/archive/0001-中文标题/`。中文标题从 `proposal.md` 第一行提取（去掉 `# ` 前缀）。归档成功后，**不要**对旧的活跃变更名称运行 `"$COMET_BASH" "$COMET_GUARD" <change-name> archive`；活跃目录已不存在。归档完整性由脚本退出码和归档目录状态决定。

## 完成

Comet 工作流完成。要开始新工作，调用 `/comet` 或 `/comet-open`。
