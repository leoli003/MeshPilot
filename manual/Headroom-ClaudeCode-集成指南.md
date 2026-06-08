# Headroom + Claude Code 集成完整指南

## 适用场景

- 使用 Claude Code + 第三方 API Key（如 meshcade、one-api 等）
- 没有官方 Anthropic 订阅
- 需要 context 优化（压缩上下文、节省 token）

## 架构说明

```
Claude Code → headroom代理(127.0.0.1:8787) → 第三方API(如 meshcade)
```

**核心原理：**
- Claude Code 发送请求到 headroom
- headroom 压缩上下文、优化请求
- headroom 转发到第三方 API
- 返回响应给 Claude Code

## 完整安装步骤

### 步骤 1：安装 headroom

```bash
pip install headroom-ai
```

验证安装：
```bash
headroom --version
```

### 步骤 2：配置 Claude Code

编辑 `~/.claude/settings.json`（Windows: `C:\Users\你的用户名\.claude\settings.json`）：

```json
{
  "env": {
    "ANTHROPIC_API_KEY": "",
    "ANTHROPIC_AUTH_TOKEN": "你的第三方API密钥",
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:8787",
    "ANTHROPIC_MODEL": "你的模型名称",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "你的模型名称",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "你的模型名称",
    "ANTHROPIC_SMALL_FAST_MODEL": "你的模型名称"
  }
}
```

**关键配置说明：**
- `ANTHROPIC_API_KEY`：**必须留空**
- `ANTHROPIC_AUTH_TOKEN`：填写第三方 API key
- `ANTHROPIC_BASE_URL`：指向 headroom 代理地址 `http://127.0.0.1:8787`
- 模型名称：根据你的第三方 API 支持的模型填写

### 步骤 3：创建启动脚本

创建 `start-headroom.ps1`（Windows）或 `start-headroom.sh`（Linux/Mac）：

**Windows PowerShell (`C:\Users\你的用户名\start-headroom.ps1`)：**

```powershell
$headroomProcess = Get-Process -Name headroom -ErrorAction SilentlyContinue
if ($headroomProcess) {
    Write-Host "Headroom is already running (PID: $($headroomProcess.Id -join ', '))"
    exit 0
}

Write-Host "Starting headroom proxy..."
Write-Host "Note: Initial startup takes ~30 seconds to load embedding model"
Start-Process -FilePath "headroom" -ArgumentList "proxy", "--memory", "--anthropic-api-url", "https://你的API地址:端口" -WindowStyle Hidden

Write-Host "Waiting for headroom to initialize (up to 60 seconds)..."
$maxWait = 60
$waited = 0
while ($waited -lt $maxWait) {
    Start-Sleep -Seconds 5
    $waited += 5
    $healthCheck = Invoke-RestMethod -Uri "http://127.0.0.1:8787/health" -Method GET -ErrorAction SilentlyContinue
    if ($healthCheck -and $healthCheck.ready) {
        Write-Host "Headroom proxy started successfully on http://127.0.0.1:8787"
        Write-Host "Routing: /v1/messages -> https://你的API地址:端口"
        Write-Host "Config: memory=$($healthCheck.config.memory), anthropic_api_url=$($healthCheck.config.anthropic_api_url)"
        exit 0
    }
    Write-Host "  Waited $waited seconds..."
}

Write-Host "Warning: Headroom may not have started correctly after $maxWait seconds"
```

**Linux/Mac Bash (`~/start-headroom.sh`)：**

```bash
#!/bin/bash

if pgrep -f "headroom proxy" > /dev/null; then
    echo "Headroom is already running"
    exit 0
fi

echo "Starting headroom proxy..."
echo "Note: Initial startup takes ~30 seconds to load embedding model"
nohup headroom proxy --memory --anthropic-api-url https://你的API地址:端口 > ~/.headroom/proxy.out 2>&1 &

echo "Waiting for headroom to initialize (up to 60 seconds)..."
max_wait=60
waited=0
while [ $waited -lt $max_wait ]; do
    sleep 5
    waited=$((waited + 5))
    if curl -s http://127.0.0.1:8787/health | grep -q '"ready": true'; then
        echo "Headroom proxy started successfully on http://127.0.0.1:8787"
        echo "Routing: /v1/messages -> https://你的API地址:端口"
        exit 0
    fi
    echo "  Waited $waited seconds..."
done

echo "Warning: Headroom may not have started correctly after $max_wait seconds"
```

**重要：** 将 `https://你的API地址:端口` 替换为你的第三方 API 实际地址。

创建停止脚本：

**Windows (`stop-headroom.ps1`)：**

```powershell
$headroomProcess = Get-Process -Name headroom -ErrorAction SilentlyContinue
if ($headroomProcess) {
    Stop-Process -Name headroom -Force
    Write-Host "Headroom stopped"
} else {
    Write-Host "Headroom is not running"
}
```

**Linux/Mac (`stop-headroom.sh`)：**

```bash
#!/bin/bash
if pgrep -f "headroom proxy" > /dev/null; then
    pkill -f "headroom proxy"
    echo "Headroom stopped"
else
    echo "Headroom is not running"
fi
```

### 步骤 4：设置开机自启动

**Windows：**

```powershell
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Headroom.lnk")
$Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"C:\Users\你的用户名\start-headroom.ps1`""
$Shortcut.WorkingDirectory = "C:\Users\你的用户名"
$Shortcut.Description = "Headroom Proxy"
$Shortcut.Save()
```

**Linux (systemd)：**

创建 `~/.config/systemd/user/headroom.service`：

```ini
[Unit]
Description=Headroom Proxy
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/headroom proxy --memory --anthropic-api-url https://你的API地址:端口
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

启用：
```bash
chmod +x ~/start-headroom.sh
systemctl --user enable headroom
systemctl --user start headroom
```

**Mac (launchd)：**

创建 `~/Library/LaunchAgents/com.headroom.plist`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.headroom</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/headroom</string>
        <string>proxy</string>
        <string>--memory</string>
        <string>--anthropic-api-url</string>
        <string>https://你的API地址:端口</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

加载：
```bash
chmod +x ~/start-headroom.sh
launchctl load ~/Library/LaunchAgents/com.headroom.plist
```

### 步骤 5：启动并验证

**启动 headroom：**

```bash
# Windows
powershell -File C:\Users\你的用户名\start-headroom.ps1

# Linux/Mac
~/start-headroom.sh
```

**验证运行状态：**

```bash
# 健康检查
curl http://127.0.0.1:8787/health

# 或 PowerShell
Invoke-RestMethod -Uri "http://127.0.0.1:8787/health"
```

**测试 API 连接：**

```powershell
# PowerShell
$body = @{
    model = "你的模型名称"
    max_tokens = 10
    messages = @(@{role="user"; content="hi"})
} | ConvertTo-Json -Depth 3

$headers = @{
    "x-api-key" = "你的API密钥"
    "anthropic-version" = "2023-06-01"
    "Content-Type" = "application/json"
}

$response = Invoke-RestMethod -Uri "http://127.0.0.1:8787/v1/messages" -Method POST -Headers $headers -Body $body
$response | ConvertTo-Json -Depth 5
```

```bash
# Bash
curl -X POST http://127.0.0.1:8787/v1/messages \
  -H "x-api-key: 你的API密钥" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{"model":"你的模型名称","max_tokens":10,"messages":[{"role":"user","content":"hi"}]}'
```

## 踩坑记录与解决方案

### ❌ 问题 1：启动时间不足

**现象：**
- 启动脚本显示 "Headroom may not have started correctly"
- health check 失败
- 端口未监听

**原因：**
headroom 启动时需要加载 ONNX embedding 模型（~86MB），首次启动需要 **30-60 秒**。

**解决：**
启动脚本必须等待足够时间（至少 60 秒），并循环检查 health endpoint：

```powershell
# 错误示例 - 只等待 3 秒
Start-Sleep -Seconds 3

# 正确示例 - 循环等待最多 60 秒
$maxWait = 60
$waited = 0
while ($waited -lt $maxWait) {
    Start-Sleep -Seconds 5
    $waited += 5
    $healthCheck = Invoke-RestMethod -Uri "http://127.0.0.1:8787/health" -Method GET -ErrorAction SilentlyContinue
    if ($healthCheck -and $healthCheck.ready) {
        # 启动成功
        exit 0
    }
}
```

### ❌ 问题 2：转发到错误的 API 地址

**现象：**
- Claude Code 提示 "403 Request not allowed" 或 "Please run /login"
- headroom 日志显示转发到 `https://api.anthropic.com` 而不是你的第三方 API

**原因：**
启动时未指定 `--anthropic-api-url` 参数，或配置文件未被正确读取。

**解决：**
启动命令**必须**显式指定上游 API 地址：

```bash
# 错误示例
headroom proxy --memory

# 正确示例
headroom proxy --memory --anthropic-api-url https://你的API地址:端口
```

**验证方法：**
检查 health endpoint 返回的 `config.anthropic_api_url`：

```powershell
$health = Invoke-RestMethod -Uri "http://127.0.0.1:8787/health"
$health.config.anthropic_api_url  # 应该显示你的API地址
```

### ❌ 问题 3：环境变量配置错误

**现象：**
- 设置系统环境变量后，Claude Code 无法连接任何 API
- 与 cc-switch 或其他配置工具冲突

**原因：**
通过系统环境变量设置会覆盖其他配置，导致冲突。

**解决：**
- ❌ **不要**设置系统环境变量
- ✅ 只在 `~/.claude/settings.json` 中配置
- ✅ `ANTHROPIC_API_KEY` 必须留空
- ✅ 使用 `ANTHROPIC_AUTH_TOKEN` 而不是 `ANTHROPIC_API_KEY`

### ❌ 问题 4：端口被占用

**现象：**
- headroom 无法启动
- 提示端口 8787 被占用

**解决：**

```bash
# Windows - 查找占用端口的进程
netstat -ano | findstr :8787
taskkill /PID <pid> /F

# Linux/Mac
lsof -i :8787
kill -9 <pid>
```

或使用其他端口：

```bash
headroom proxy --port 8080 --anthropic-api-url https://你的API地址:端口
```

并在 `settings.json` 中更新：
```json
"ANTHROPIC_BASE_URL": "http://127.0.0.1:8080"
```

### ❌ 问题 5：多个 headroom 进程

**现象：**
- 有多个 headroom 进程在运行
- 配置不一致

**解决：**
先停止所有 headroom 进程，再重新启动：

```powershell
# Windows
Stop-Process -Name headroom -Force
Start-Sleep -Seconds 2
# 然后启动

# Linux/Mac
pkill -f "headroom proxy"
sleep 2
# 然后启动
```

### ❌ 问题 6：SSL 证书错误

**现象：**
- headroom 无法连接第三方 API
- 提示 SSL/TLS 错误

**解决：**
1. 确认 API 地址正确（http vs https）
2. 测试直接访问 API：
```powershell
Invoke-RestMethod -Uri "https://你的API地址:端口/v1/models" -Method GET -Headers @{"x-api-key"="你的密钥"}
```
3. 联系 API 提供商确认证书状态

### ❌ 问题 7：Memory 功能加载失败

**现象：**
- 启动时提示 ONNX 或 embedding 相关错误
- Memory 功能不可用

**解决：**

```bash
# 安装 memory 依赖
pip install headroom-ai[memory]

# 或禁用 memory（不推荐）
headroom proxy --anthropic-api-url https://你的API地址:端口
```

### ❌ 问题 8：开机自启动失败

**现象：**
- 重启电脑后 headroom 未运行
- Claude Code 提示登录

**原因：**
自启动快捷方式或服务配置不正确。

**解决：**

**Windows：** 确保快捷方式参数正确：
```powershell
$Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"完整路径\start-headroom.ps1`""
```

**Linux：** 确保 systemd 服务文件路径正确：
```bash
systemctl --user status headroom
journalctl --user -u headroom -f
```

**Mac：** 确保 plist 文件正确：
```bash
launchctl list | grep headroom
```

## 验证检查清单

安装完成后，逐项检查：

- [ ] headroom 已安装（`headroom --version`）
- [ ] `~/.claude/settings.json` 已正确配置
- [ ] 启动脚本已创建并可执行
- [ ] headroom 正在运行（`Get-Process headroom` 或 `pgrep headroom`）
- [ ] 端口 8787 正在监听（`netstat -ano | findstr :8787`）
- [ ] health check 成功（访问 `http://127.0.0.1:8787/health`）
- [ ] health check 返回正确的 `anthropic_api_url`
- [ ] API 测试成功（发送测试请求）
- [ ] 开机自启动已设置
- [ ] Claude Code 可以正常使用

## 常用命令速查

```bash
# 启动
headroom proxy --memory --anthropic-api-url https://你的API地址:端口

# 后台启动（Windows）
Start-Process headroom -ArgumentList "proxy","--memory",'--anthropic-api-url',"https://你的API地址:端口" -WindowStyle Hidden

# 后台启动（Linux/Mac）
nohup headroom proxy --memory --anthropic-api-url https://你的API地址:端口 > /dev/null 2>&1 &

# 停止（Windows）
Stop-Process -Name headroom

# 停止（Linux/Mac）
pkill -f "headroom proxy"

# 查看状态
curl http://127.0.0.1:8787/health

# 查看统计
curl http://127.0.0.1:8787/stats

# 查看日志
tail -f ~/.headroom/logs/proxy.log

# 查看帮助
headroom --help
headroom proxy --help
```

## 故障排除流程

遇到问题时，按以下顺序排查：

1. **检查进程：** headroom 是否在运行？
   ```bash
   Get-Process headroom  # Windows
   pgrep headroom        # Linux/Mac
   ```

2. **检查端口：** 8787 是否在监听？
   ```bash
   netstat -ano | findstr :8787  # Windows
   lsof -i :8787                 # Linux/Mac
   ```

3. **检查健康状态：** 访问 health endpoint
   ```bash
   curl http://127.0.0.1:8787/health
   ```

4. **检查配置：** 确认 `anthropic_api_url` 是否正确
   ```powershell
   $h = Invoke-RestMethod -Uri "http://127.0.0.1:8787/health"
   $h.config.anthropic_api_url
   ```

5. **检查日志：** 查看错误信息
   ```bash
   tail -50 ~/.headroom/logs/proxy.log
   ```

6. **检查上游 API：** 直接测试第三方 API 是否可达
   ```powershell
   Invoke-RestMethod -Uri "https://你的API地址:端口/v1/models" -Headers @{"x-api-key"="你的密钥"}
   ```

7. **重启 headroom：** 先停止再启动
   ```bash
   # 停止
   Stop-Process -Name headroom -Force  # Windows
   pkill -f "headroom proxy"           # Linux/Mac
   
   # 等待
   sleep 2
   
   # 启动
   # 使用启动脚本
   ```

## 配置文件路径

| 文件 | Windows 路径 | Linux/Mac 路径 |
|------|-------------|---------------|
| Claude Code 配置 | `C:\Users\用户名\.claude\settings.json` | `~/.claude/settings.json` |
| Headroom 日志 | `C:\Users\用户名\.headroom\logs\proxy.log` | `~/.headroom/logs/proxy.log` |
| Headroom 配置 | `C:\Users\用户名\.headroom\config.yaml` | `~/.headroom/config.yaml` |
| 启动脚本 | `C:\Users\用户名\start-headroom.ps1` | `~/start-headroom.sh` |
| Windows 自启动 | `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Headroom.lnk` | - |

## 两种模式对比

| 特性 | 反向代理模式（推荐） | MCP 模式 |
|------|-------------------|---------|
| 配置复杂度 | 低 | 中 |
| 透明度 | 全自动 | 需手动调用 |
| 适用用户 | API key 用户 | 订阅用户 |
| 压缩方式 | 自动压缩所有请求 | 按需压缩 |
| 推荐场景 | **第三方 API** | 官方订阅 |
| 启动方式 | `headroom proxy` | `headroom mcp serve` |

**建议：** 使用第三方 API 时，使用反向代理模式即可。

## 更新与卸载

**更新：**
```bash
pip install --upgrade headroom-ai
# 重启 headroom
```

**卸载：**
```bash
# 停止
Stop-Process -Name headroom  # Windows
pkill -f "headroom proxy"    # Linux/Mac

# 删除配置（可选）
rm -rf ~/.headroom

# 删除启动项
rm "$APPDATA/Microsoft/Windows/Start Menu/Programs/Startup/Headroom.lnk"  # Windows
systemctl --user disable headroom                                          # Linux
launchctl unload ~/Library/LaunchAgents/com.headroom.plist                 # Mac

# 卸载
pip uninstall headroom-ai
```

## 示例配置

### 示例 1：使用 meshcade API

**settings.json：**
```json
{
  "env": {
    "ANTHROPIC_API_KEY": "",
    "ANTHROPIC_AUTH_TOKEN": "sk-xxxxxxxxxxxx",
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:8787",
    "ANTHROPIC_MODEL": "glm-5",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-5",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-5",
    "ANTHROPIC_SMALL_FAST_MODEL": "glm-5"
  }
}
```

**启动命令：**
```bash
headroom proxy --memory --anthropic-api-url https://www.meshcade.com:2998
```

### 示例 2：使用 one-api

**settings.json：**
```json
{
  "env": {
    "ANTHROPIC_API_KEY": "",
    "ANTHROPIC_AUTH_TOKEN": "sk-xxxxxxxxxxxx",
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:8787",
    "ANTHROPIC_MODEL": "claude-3-5-sonnet-20241022",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-3-5-sonnet-20241022",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "claude-3-5-haiku-20241022",
    "ANTHROPIC_SMALL_FAST_MODEL": "claude-3-5-haiku-20241022"
  }
}
```

**启动命令：**
```bash
headroom proxy --memory --anthropic-api-url http://localhost:3000
```

## 总结

**成功集成的关键点：**

1. ✅ 正确配置 `settings.json`（`ANTHROPIC_API_KEY` 留空，使用 `ANTHROPIC_AUTH_TOKEN`）
2. ✅ 启动时显式指定 `--anthropic-api-url`
3. ✅ 启动脚本等待足够时间（60秒）
4. ✅ 验证 health check 返回正确的配置
5. ✅ 设置开机自启动

**常见错误：**

1. ❌ 只等待几秒钟就判断启动失败
2. ❌ 不指定 `--anthropic-api-url` 导致转发到官方 API
3. ❌ 设置系统环境变量导致冲突
4. ❌ `ANTHROPIC_API_KEY` 和 `ANTHROPIC_AUTH_TOKEN` 混淆

**遇到 403 错误时：**

1. 检查 headroom 是否正在运行
2. 检查 health endpoint 的 `anthropic_api_url` 配置
3. 检查日志中的转发地址
4. 重启 headroom 并确保指定正确的上游地址
