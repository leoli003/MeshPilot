# EchoBird + Codex CLI 重复回答问题修复指南

## 问题现象

Codex CLI v0.130.0 通过 EchoBird 代理使用第三方模型（如 glm-5）时，每条指令会触发模型多次回答（约5次），并报错：

```
stream disconnected before completion: failed to parse ResponseCompleted: missing field `input_tokens`
```

## 根因分析

1. **Codex v0.130.0 只支持 `wire_api = "responses"`**，不再支持 `chat` 模式
2. EchoBird 代理将 Codex 的 Responses API 请求转换为 Chat Completions API 发给上游，再将上游响应转回 Responses SSE 格式
3. 上游返回的 `usage` 对象使用 Chat Completions 格式（`prompt_tokens` / `completion_tokens`），缺少 Codex 要求的 `input_tokens` / `output_tokens` 字段
4. Codex 解析 `response.completed` 事件时因缺少 `input_tokens` 字段而失败，触发重试，导致重复回答

## 修复方法

修改 EchoBird 的 `stream-handler.cjs`，在返回给 Codex 的 `usage` 对象中补全 `input_tokens` 和 `output_tokens` 字段。

### 文件路径

```
%LOCALAPPDATA%\EchoBird\_up_\tools\codex\lib\stream-handler.cjs
```

### 修改点一：流式响应（约第144行）

**修改前：**

```javascript
if (usage) completedResponse.usage = usage;
```

**修改后：**

```javascript
if (usage) {
    completedResponse.usage = usage;
    if (usage.prompt_tokens !== undefined && usage.input_tokens === undefined) {
        usage.input_tokens = usage.prompt_tokens;
        usage.output_tokens = usage.completion_tokens;
    }
}
```

### 修改点二：非流式响应（约第340行）

**修改前：**

```javascript
if (chatResponse.usage) response.usage = chatResponse.usage;
```

**修改后：**

```javascript
if (chatResponse.usage) {
    response.usage = chatResponse.usage;
    if (chatResponse.usage.prompt_tokens !== undefined && chatResponse.usage.input_tokens === undefined) {
        response.usage.input_tokens = chatResponse.usage.prompt_tokens;
        response.usage.output_tokens = chatResponse.usage.completion_tokens;
    }
}
```

### 修改后重启

修改文件后必须重启 EchoBird 代理进程（关闭并重新打开 EchoBird / Codex 桌面版）。

## 经验与教训

1. **`input_tokens` 必须在 `usage` 对象内部**，不能放在 response 顶层。Codex 解析的是 `response.usage.input_tokens`，不是 `response.input_tokens`

2. **`wire_api = "chat"` 已被 Codex v0.130.0 废弃**，强行修改会报错无法启动，只能走 `responses` 路径修复

3. **EchoBird 代理每次启动会重写 `config.toml`**（端口随机分配），手动修改 `base_url` 或 `wire_api` 会在重启后被覆盖

4. **修改后必须杀掉代理进程并重启**，Node.js 使用 `require()` 缓存模块，不重启不会加载新代码

5. **定位问题的关键是直接测试代理端点**，用 `Invoke-RestMethod` 发请求查看实际返回的 JSON 结构，确认缺失字段

6. **错误信息 `missing field input_tokens` 就是字面意思**——Responses API 的 usage 对象缺少该字段，不要想复杂了

## 快速修复脚本（PowerShell 管理员）

```powershell
$file = "$env:LOCALAPPDATA\EchoBird\_up_\tools\codex\lib\stream-handler.cjs"
$content = [System.IO.File]::ReadAllText($file)

# 修复流式响应
$content = $content.Replace(
    'if (usage) completedResponse.usage = usage;',
    'if (usage) { completedResponse.usage = usage; if (usage.prompt_tokens !== undefined && usage.input_tokens === undefined) { usage.input_tokens = usage.prompt_tokens; usage.output_tokens = usage.completion_tokens; } }'
)

# 修复非流式响应
$content = $content.Replace(
    'if (chatResponse.usage) response.usage = chatResponse.usage;',
    'if (chatResponse.usage) { response.usage = chatResponse.usage; if (chatResponse.usage.prompt_tokens !== undefined && chatResponse.usage.input_tokens === undefined) { response.usage.input_tokens = chatResponse.usage.prompt_tokens; response.usage.output_tokens = chatResponse.usage.completion_tokens; } }'
)

[System.IO.File]::WriteAllText($file, $content)
Write-Output "Done. Restart EchoBird/Codex Desktop to apply."
```

## 注意事项

- EchoBird 更新后可能覆盖此修改，需重新执行
- 如果上游 API 本身不返回 `usage`，此修复无法生效，需确认上游 API 支持 usage 统计
