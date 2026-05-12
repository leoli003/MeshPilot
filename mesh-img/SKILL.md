---
name: mesh-img
description: 识别图片内容并返回文本描述。当用户说"识图"、"识别图片"、"mesh-img"、或提供图片路径请求识别时触发此技能。支持本地图片路径，使用 OpenAI 兼容格式的视觉模型 API。
---

# mesh-img - 图片内容识别技能

识别指定图片的内容并返回文本描述。

## 使用方式

**手动调用：**
```
/mesh-img E:\path\to\image.png
```

**关键词触发：**
- "识图 E:\path\to\image.png"
- "识别图片 E:\path\to\image.png"
- "mesh-img E:\path\to\image.png"

**交互式调用：**
直接说 `/mesh-img` 或 "识图"，技能会询问图片路径。

## 配置

首次使用时，需要配置 API 设置。配置文件位于：
```
~/.claude/skills/mesh-img/config.json
```

配置模板：
```json
{
  "apiKey": "your-api-key-here",
  "baseUrl": "https://api.openai.com/v1",
  "model": "gpt-4o"
}
```

### 配置说明

| 字段 | 说明 |
|------|------|
| apiKey | 视觉模型的 API Key |
| baseUrl | API 基础地址（OpenAI 兼容格式） |
| model | 模型名称，如 `gpt-4o`、`gpt-4-vision-preview`、`qwen-vl-plus` 等 |

## 工作流程

1. **获取图片路径**
   - 如果命令提供了路径参数，直接使用
   - 如果没有，使用 AskUserQuestion 询问用户

2. **验证路径**
   - 检查文件是否存在
   - 检查是否为支持的图片格式（jpg、jpeg、png、gif、webp、bmp）

3. **图片预处理**
   - 检查图片尺寸，若长边超过 2048px 则按比例缩放
   - 保持宽高比，长边缩至 2048px

4. **读取配置**
   - 从 `~/.claude/skills/mesh-img/config.json` 读取配置
   - 如果配置文件不存在，提示用户创建

5. **调用 API**
   - 将图片转为 base64 编码
   - 构建符合 OpenAI 格式的请求
   - 临时文件存入系统临时目录（%TEMP% 或 /tmp）
   - 调用 `{baseUrl}/chat/completions` 端点
   - 完成后删除临时文件

6. **返回结果**
   - 输出识别到的图片内容描述

## 实现指令

执行以下步骤完成图片识别：

### Step 1: 解析图片路径

检查用户输入是否包含图片路径。如果没有，询问用户：

```
请提供图片的完整路径：
```

### Step 2: 检查配置文件

读取配置文件 `~/.claude/skills/mesh-img/config.json`：

```bash
cat ~/.claude/skills/mesh-img/config.json
```

如果文件不存在，创建配置模板并提示用户填写：

```json
{
  "apiKey": "",
  "baseUrl": "https://api.openai.com/v1",
  "model": "gpt-4o"
}
```

然后告知用户："配置文件已创建，请填写 apiKey 后再使用。"

### Step 3: 图片预处理（尺寸检查与缩放）

检查图片尺寸，若长边超过 2048px 则按比例缩放：

**Windows (PowerShell):**
```powershell
# 获取图片尺寸
$img = [System.Drawing.Image]::FromFile("$imagePath")
$width = $img.Width
$height = $img.Height
$img.Dispose()

# 计算缩放比例
$maxSize = 2048
if ($width -gt $maxSize -or $height -gt $maxSize) {
    $ratio = [Math]::Min($maxSize / $width, $maxSize / $height)
    $newWidth = [Math]::Round($width * $ratio)
    $newHeight = [Math]::Round($height * $ratio)
    # 缩放图片并保存到临时目录
}
```

**Linux/Mac (ImageMagick):**
```bash
identify -format "%w %h" "$imagePath"
# 若超过 2048px，使用 convert 缩放
convert "$imagePath" -resize 2048x2048\> "$resizedPath"
```

### Step 4: 生成 Base64 并调用 API

**临时文件处理：** 所有临时文件存入系统临时目录，完成后删除。

**Windows (PowerShell):**
```powershell
$tempDir = $env:TEMP
$tempBase64 = "$tempDir\mesh_img_b64.txt"
$tempRequest = "$tempDir\mesh_img_request.json"
$tempResponse = "$tempDir\mesh_img_response.json"

# 生成 base64
[Convert]::ToBase64String([IO.File]::ReadAllBytes($imagePath)) | Out-File $tempBase64 -Encoding ASCII

# 构建 JSON 请求
$base64 = Get-Content $tempBase64 -Raw
$json = @{
    model = $model
    messages = @(
        @{
            role = 'user'
            content = @(
                @{ type = 'text'; text = '请详细描述这张图片的内容。' },
                @{ type = 'image_url'; image_url = @{ url = "data:image/$format;base64,$base64" } }
            )
        }
    )
    max_tokens = 2000
}
$json | ConvertTo-Json -Depth 10 | Out-File $tempRequest -Encoding UTF8

# 调用 API
curl -s -X POST "$baseUrl/chat/completions" -H "Content-Type: application/json" -H "Authorization: Bearer $apiKey" -d "@$tempRequest" -o $tempResponse

# 读取响应并删除临时文件
$result = Get-Content $tempResponse | ConvertFrom-Json
Remove-Item $tempBase64, $tempRequest, $tempResponse -ErrorAction SilentlyContinue
$result.choices[0].message.content
```

**Linux/Mac:**
```bash
temp_dir="/tmp"
pid=$$
temp_base64="$temp_dir/mesh_img_${pid}_b64.txt"
temp_request="$temp_dir/mesh_img_${pid}_request.json"
temp_response="$temp_dir/mesh_img_${pid}_response.json"

# 生成 base64
base64 -w 0 "$imagePath" > "$temp_base64"

# 构建 JSON 请求并调用 API
# ...

# 完成后删除临时文件
rm -f "$temp_base64" "$temp_request" "$temp_response"
```

### Step 5: 处理响应

解析 JSON 响应，提取 `choices[0].message.content` 并输出。

如果出错，检查：
- API Key 是否正确
- baseUrl 是否有效
- 模型是否支持视觉能力
- 图片是否过大（建议 < 20MB）

## 示例

**输入：**
```
/mesh-img E:\photos\screenshot.png
```

**输出：**
```
图片识别结果：

这张图片显示的是一个代码编辑器界面，深色主题。左侧是文件浏览器，
右侧是代码编辑区域，当前打开的是一个 TypeScript 文件...
```

## 错误处理

| 错误 | 处理方式 |
|------|----------|
| 配置文件不存在 | 创建模板，提示填写 apiKey |
| apiKey 为空 | 提示用户配置 apiKey |
| 图片不存在 | 提示检查路径是否正确 |
| API 调用失败 | 显示错误信息，建议检查配置 |
| 图片格式不支持 | 列出支持的格式 |

## 注意事项

- **Token 消耗**：此技能通过 curl 直接调用你的专用视觉模型 API，**不消耗 Claude Code 的 token**。所有 API 调用成本由你配置的专用模型承担。
- API Key 仅用于此技能，不会影响 Claude Code 的其他功能
- 图片会以 base64 编码发送到指定的 API 端点
- 请确保 baseUrl 指向 OpenAI 兼容的 API 服务

## 超时与错误处理

### 超时设置

默认超时时间为 **120 秒**。如果 API 响应较慢，可能出现超时。

**超时提示：**
```
⏱️ 图片识别超时

可能原因：
1. 图片过大，处理时间较长
2. API 服务响应慢
3. 网络连接问题

建议：
- 尝试使用较小的图片
- 检查 API 服务状态
- 稍后重试
```

### 识别失败处理

**API 返回错误时：**
```
❌ 图片识别失败

错误信息：[API 返回的具体错误]

可能原因：
1. API Key 无效或已过期
2. baseUrl 配置错误
3. 模型名称不正确或不支持视觉能力
4. 图片格式不支持或损坏
5. API 服务暂时不可用

请检查配置文件：~/.claude/skills/mesh-img/config.json
```

**识别结果为空时：**
```
⚠️ 未能识别出图片内容

可能原因：
1. 图片内容过于复杂或模糊
2. 模型无法理解图片内容
3. 图片损坏或格式异常

建议：
- 尝试使用更清晰的图片
- 换用其他视觉模型
```

**网络连接失败时：**
```
🔌 无法连接到 API 服务

请检查：
1. baseUrl 是否正确：[当前配置的 baseUrl]
2. 网络是否通畅
3. API 服务是否在线
```
