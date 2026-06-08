# 飞书 MCP 安装配置指南

> 基于 MeshAI 项目真实踩坑经验总结。

## 前置条件

- Node.js 18+
- 飞书开发者后台应用（已发布）
- Claude Code

## 1. 飞书应用配置

### 1.1 创建应用 → 记录 App ID / App Secret

[飞书开发者后台](https://open.feishu.cn/app) → 创建企业自建应用

### 1.2 开通权限（关键！必须同时开通应用+用户身份）

| 权限 | 用途 | 应用身份 | 用户身份 |
|------|------|------|------|
| `docx:document` | 创建编辑文档 | ✅ | ✅ |
| `docx:document:readonly` | 查看文档 | ✅ | ✅ |
| `drive:drive` | 管理云空间 | ✅ | - |
| `drive:file` | 管理文件 | - | ✅ |

> ⚠️ 只开应用身份=只能看应用自建文档；只开用户身份=部分 API 报 99992402。

### 1.3 安全设置 → 添加重定向 URL

```
http://localhost:9999/callback
```

> 端口 3000 常被占用，建议用 9999。

### 1.4 发布应用

「版本管理」→ 创建版本 → 发布。未发布=API 受限。

## 2. OAuth 登录

```bash
npx -y @larksuiteoapi/lark-mcp login \
  -a cli_xxxxxxxxxxxx \
  -s your_app_secret \
  -p 9999
```

浏览器打开授权链接 → 同意 → 看到 `✅ Successfully logged in`

验证：
```bash
npx -y @larksuiteoapi/lark-mcp whoami
# 应显示: AccessToken Expired: false
```

> ⚠️ 端口冲突(EADDRINUSE) → 换 `-p 22222`，并在飞书后台更新重定向 URL。

## 3. MCP 配置

### 项目根目录 `.mcp.json`

```json
{
  "mcpServers": {
    "lark-mcp": {
      "command": "npx",
      "args": [
        "-y", "@larksuiteoapi/lark-mcp", "mcp",
        "-a", "cli_xxxxxxxxxxxx",
        "-s", "your_app_secret",
        "-t", "preset.docx.default",
        "--oauth",
        "--token-mode", "user_access_token"
      ]
    }
  }
}
```

或使用 CLI：
```bash
claude mcp add -s project lark-mcp -- \
  npx -y @larksuiteoapi/lark-mcp mcp \
  -a cli_xxxxxxxxxxxx -s your_secret \
  -t preset.docx.default --oauth --token-mode user_access_token
```

### 验证

```bash
claude mcp list
# lark-mcp: ... ✓ Connected
```

**重启 Claude Code**。

## 4. 诊断

### 4.1 日志位置

```
~/AppData/Local/lark-mcp-nodejs/Log/lark-mcp-*.log
```

正常日志应显示：
```
userAccessToken: true      ← 必须是 true
Initialized with N tools    ← N > 0
```

异常：
```
userAccessToken: false     ← ❌ OAuth token 未加载
Initialized with 0 tools   ← ❌ 缺 --oauth 参数
```

### 4.2 常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| MCP 0 个工具 | 缺 `--oauth` | 加 `--oauth --token-mode user_access_token` |
| `userAccessToken: false` | Token 过期 | 重新 login，重启 Claude Code |
| `.mcp.json` 不加载 | 位置不对 | 放项目根目录，不要放 `~/.mcp.json` |
| 创建文档失败(99992402) | 权限未开通 | 飞书后台开通对应权限 |
| MCP 已连接但没工具 | 非 Anthropic 模型 | 直接 API 调用同样可用 |
| 端口冲突 | 3000 被占用 | 换高位端口 |

### 4.3 Tenant vs User Token

| | Tenant | User |
|------|------|------|
| 配置 | 默认 | `--oauth --token-mode user_access_token` |
| 文档归属 | 应用名下 | 用户名下 |
| 能看到的文档 | 仅应用创建 | 用户全部文档 |
| Block 写入 | ✅ | ✅ |

### 4.4 写入文档 Block 类型速查

| block_type | 类型 | 字段名 |
|------|------|------|
| 2 | 文本 | `text` |
| 3 | 标题1 | `heading1` |
| 4 | 标题2 | `heading2` |
| 7 | 无序列表 | `bullet` |

Minimal block 格式：
```json
{ "block_type": 2, "text": { "elements": [{ "text_run": { "content": "内容" } }], "style": {} } }
```

## 5. Token 存储

- 加密存储：`~/AppData/Local/lark-mcp-nodejs/Data/storage.json`（AES-256-CBC）
- 加密密钥：Windows 凭据管理器 → `lark-mcp/encryption-key`
- 解密需两层 hex 解码：Key hex → 64 字符 hex string → 32 字节 AES key

## 6. 踩坑时间线

| # | 问题 | 根因 |
|---|------|------|
| 1 | settings.json 不支持 `mcpServers` | 需独立 `.mcp.json` |
| 2 | 用户级 `.mcp.json` 不加载 | 放项目根目录 |
| 3 | 端口冲突 | 换 9999 |
| 4 | MCP 已连接但 0 工具 | 缺 `--oauth --token-mode user_access_token` |
| 5 | User token 解密失败 | AES key 需两层 hex 解码 |
| 6 | Tenant 看不到用户文档 | 必须用 User token |
