# Claude Code 上下文暴涨排查与修复手册

## 症状
简单对话（"你好", "2+3"）就占 200K 上下文的 55%+，一个 "你好" 就消耗 ~115K tokens。

## 排查方法论: 二分法

每次只改一个变量，观察上下文占比变化：

| 步骤 | 操作 | 结果 | 结论 |
|------|------|------|------|
| 1 | 禁用 MemPalace hooks | 无变化 | 排除 |
| 2 | 禁用 ECC 插件 | 53% → 46% | 主犯 |
| 3 | 禁用 claude-mem 插件 | 46% → 25% | 次犯 |
| 4 | 禁用 understand-anything | 无变化 | 排除 |

## 根因

### 主犯: ECC 插件 (31 hooks + memory MCP)

- **`plugin:ecc:memory` MCP server**: Claude 会自动调用它读取知识图谱，注入大量上下文
- **`session-start-bootstrap.js`**: 每次会话注入历史 session 摘要
- **31 个 hooks 覆盖所有事件**: PreToolUse(12) + PostToolUse(11) + Stop(7) + SessionStart(1) + PostToolUseFailure(1)
- **每个工具调用前后各触发多个 hook**，输出注入上下文

### 次犯: claude-mem 插件 (7 hooks)

- **`PostToolUse observation`**: 每个工具调用后都触发观察记录，累计最多
- **SessionStart 3 个 hooks**: smart-install + worker start + context 注入
- **UserPromptSubmit**: 每次提问触发 session-init

### 基础开销 (~25%)

以下无法避免，是你的"正常胖":
- CLAUDE.md 8.8KB (OMC 指令 + CodeGraph 配置 + Karpathy 准则等)
- 100+ skills 列表 (每个 skill 的 name + description + location)
- OMC 15 个自定义 hooks
- 剩余 9 个启用的插件注册的 agents/skills 定义

## 修复方案

### 方案 A: 简单粗暴（推荐，当前已生效）

只改 `~/.claude/settings.json`:

```json
"enabledPlugins": {
    "ecc@ecc": false,              // 禁用 ECC
    "claude-mem@thedotmack": false  // 禁用 claude-mem
}
```

效果: 53% → 25%，其余插件全部保持原样。

### 方案 B: 精细恢复（保留部分功能）

1. **重新启用 ECC 但移除 memory MCP**:
   编辑 `~/.claude/plugins/marketplaces/ecc/.mcp.json`，删除 `memory`、`context7`、`exa` 条目。
   同步编辑 `~/.claude/plugins/cache/ecc/ecc/1.10.0/.mcp.json`。

2. **重新启用 claude-mem 但禁用 observation hook**:
   编辑 `~/.claude/plugins/marketplaces/thedotmack/plugin/hooks/hooks.json`，
   将 `PostToolUse` 改为空数组:
   ```json
   "PostToolUse": []
   ```

### 方案 C: 极致精简

1. 执行方案 B 的所有操作
2. 在 ECC hooks.json 中只保留必要的 hooks，移除:
   - `continuous-learning observation` (PreToolUse + PostToolUse)
   - `quality-gate` (PostToolUse)
   - `design-quality-check` (PostToolUse)
   - `build-complete` (PostToolUse)
   - `console-warn` (PostToolUse)
3. 禁用 security-guidance 插件（6 hooks，如不需要安全提醒）
4. 禁用 understand-anything 插件（822MB 磁盘，2 hooks）

## 快速诊断命令

### 查看 hook 总数
```powershell
# 自定义 hooks
$settings = Get-Content "$env:USERPROFILE\.claude\settings.json" -Raw | ConvertFrom-Json
$count = 0; foreach ($p in $settings.hooks.PSObject.Properties) { foreach ($g in $p.Value) { $count += $g.hooks.Count } }; Write-Output "Custom: $count"

# 插件 hooks
Get-ChildItem "$env:USERPROFILE\.claude\plugins" -Recurse -Filter "hooks.json" | Where-Object { $_.DirectoryName -notmatch "tests|fixtures|cursor-hooks" } | ForEach-Object { $c = (Get-Content $_.FullName -Raw | ConvertFrom-Json).hooks; if ($c) { foreach ($p in $c.PSObject.Properties) { foreach ($g in $p.Value) { $script:total += $g.hooks.Count } } } }; Write-Output "Plugin: $total"
```

### 查看上下文占比
在 Claude Code HUD 中看 `ctx:XX%` 或状态栏。

### 查看 CLAUDE.md 大小
```powershell
(Get-Content "$env:USERPROFILE\.claude\CLAUDE.md" -Raw).Length
```

## 注意事项

1. **ECC 插件更新后 .mcp.json 可能被覆盖**，需要重新编辑
2. **claude-mem 插件更新后 hooks.json 可能被覆盖**，需要重新编辑
3. **禁用 ECC 会失去其 38 个 agents 和大量 skills**，如需使用可临时启用
4. **MemPalace hooks 实测对上下文无影响**，可保留
5. **understand-anything 影响极小**，可保留

## 排查耗时
约 30 分钟，通过 4 轮二分法定位。