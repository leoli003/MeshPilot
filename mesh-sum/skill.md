---
name: mesh-sum
description: Get a quick project summary before starting work. Use when you need to understand a project fast, at the start of a session, before adding new features, or when asked "what is this project?". Trigger on phrases like "project summary", "project overview", "understand this project", "what does this project do", "quick summary", "mesh-sum".
license: MIT
metadata:
  author: oh-my-claudecode
  version: "1.0"
---

Quickly get a comprehensive project summary. **Works for any project type.**

## Usage

```
/mesh-sum          # Fast mode (default) - ~1 second
/mesh-sum --full   # Full mode - ~3 seconds, includes source analysis
```

---

## How It Works

All channels run **in parallel** with **fault tolerance** - failures don't affect other channels.

```
┌─────────────────────────────────────────────────────────────┐
│                    CHANNEL EXECUTION                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│   │  Memory  │  │   Git    │  │  Specs   │  │ Codegraph│   │
│   │   ⚡⚡⚡   │  │   ⚡⚡⚡   │  │   ⚡⚡    │  │   ⚡⚡    │   │
│   └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│         ↓             ↓             ↓             ↓         │
│   [data/null]   [data/null]   [data/null]   [data/null]    │
│         ↓             ↓             ↓             ↓         │
│                    MERGE & OUTPUT                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Fast Mode Channels (Default)

Execute ALL in parallel. Each handles its own errors silently.

### 1. AgentMemory
```javascript
// Try to recall project memories
try {
  mcp__agentmemory__memory_recall({ query: "project architecture features", limit: 10 })
} catch {
  // MCP not available → return []
}
```
**Returns**: Historical insights, design decisions, past learnings
**On Failure**: Returns empty array, continues

### 2. Git History
```bash
git log --oneline -15 2>/dev/null || echo ""
```
**Returns**: Recent commits showing feature evolution
**On Failure**: Returns empty string (not a git repo), continues

### 3. File Scan (Project Structure)

**⚠️ 关键问题**: Glob 工具的 `*.js` 模式**会返回 node_modules 下的文件**，这与标准 glob 行为不同。必须手动过滤结果。

```javascript
// 第一步：获取文件列表
const htmlFiles = Glob("*.html")
const jsFiles = Glob("*.js")
const tsFiles = Glob("*.ts")
const pyFiles = Glob("*.py")

// 第二步：手动过滤 - 排除 node_modules, .git, dist, build 等目录
const EXCLUDE_PATTERNS = [
  'node_modules/',
  '.git/',
  'dist/',
  'build/',
  '__pycache__/',
  'vendor/',
  '.next/',
  '.nuxt/'
]

function filterFiles(files) {
  return files.filter(f => !EXCLUDE_PATTERNS.some(p => f.includes(p)))
}

const projectFiles = {
  html: filterFiles(htmlFiles),
  js: filterFiles(jsFiles),
  ts: filterFiles(tsFiles),
  py: filterFiles(pyFiles)
}

// 第三步：检测项目类型
Glob("package.json")      // Node.js
Glob("pyproject.toml")    // Python
Glob("Cargo.toml")        // Rust
Glob("go.mod")            // Go
Glob("pom.xml")           // Java
```

**排除规则** (必须手动过滤):
| 目录 | 说明 |
|------|------|
| `node_modules/` | npm/pnpm 依赖 |
| `.git/` | git 元数据 |
| `dist/`, `build/` | 构建产物 |
| `__pycache__/` | Python 缓存 |
| `vendor/` | Go vendor |
| `.next/`, `.nuxt/` | 框架产物 |

**Returns**: Project type, entry points, structure (手动过滤后)
**On Failure**: Never fails (Glob always returns array)

### 4. Specs / Requirements
```javascript
// Try multiple spec locations in order
const specPatterns = [
  "openspec/specs/**/*.md",   // OpenSpec projects
  "specs/**/*.md",            // Standard specs
  "docs/specs/**/*.md",       // Docs folder
  "docs/adr/**/*.md",         // Architecture Decision Records
  "adr/**/*.md"               // ADR root
]

for (const pattern of specPatterns) {
  const files = Glob(pattern)
  if (files.length > 0) return files  // Use first match
}
return []  // No specs found
```
**Returns**: Structured requirements, design decisions
**On Failure**: Returns empty array, continues

### 5. Codegraph
```javascript
try {
  mcp__codegraph__codegraph_context({ task: "project overview and architecture" })
} catch {
  // Codegraph not initialized → return null
}
```
**Returns**: Symbol relationships, call graphs, architecture
**On Failure**: Returns null, continues

### 6. README / Documentation
```javascript
Glob("README*.md")
Glob("CLAUDE.md")
Glob("docs/README*.md")
```
**Returns**: Project description, setup instructions
**On Failure**: Returns empty array, continues

---

## Full Mode Channels (--full)

Includes ALL fast mode channels PLUS:

### 7. Source Code Analysis
```javascript
// Read key source files (limit: 3 files, 200 lines each)
const entryFile = findEntryFile()  // Based on project type
if (entryFile) {
  Read(entryFile, { limit: 200 })
}
```
**Returns**: Implementation details, patterns
**On Failure**: Skips if no entry file found

### 8. Dependencies Detail
```javascript
// Read package config fully
if (Glob("package.json").length > 0) {
  Read("package.json")
}
if (Glob("pyproject.toml").length > 0) {
  Read("pyproject.toml")
}
```
**Returns**: Full dependency list, scripts, metadata
**On Failure**: Skips if no config file

---

## Output Format

### Header: Channel Status
```markdown
## [Project Name] Summary

### 📊 Channel Status
| Channel | Status | Data |
|---------|--------|------|
| AgentMemory | ✅ | 3 memories |
| Git History | ✅ | 15 commits |
| Specs | ✅ | 2 specs |
| Codegraph | ⚠️ Not initialized | - |
| README | ✅ | README.md |

> 💡 Tip: Run `codegraph init` for code relationship analysis
```

### Body Sections
```markdown
### Overview
[Description from README or inferred from files]

### Tech Stack
| Layer | Technology |
|-------|------------|
| Language | [detected] |
| Framework | [detected or "none"] |
| Build | [detected or "none"] |

### Project Type
[Web App / CLI / Library / API / Game / Static Site]

### Core Features
| Feature | Status | Source |
|---------|--------|--------|
| [feature] | ✅ | [spec/memory/git] |

### Key Files
| File | Purpose |
|------|---------|
| [entry] | Main entry point |
| [config] | Configuration |

### Recent Activity
```
[commit hash] - [commit message]
```

### Specs / Requirements
[List from OpenSpec or specs directory]

### Architecture Notes
[From memory, specs, or codegraph]
```

---

## Project Type Detection

```
package.json + "react"    → React App
package.json + "vue"      → Vue App
package.json + "next"     → Next.js App
package.json + "express"  → Express API
package.json + (none)     → Node.js Project
pyproject.toml            → Python Project
Cargo.toml                → Rust Project
go.mod                    → Go Project
pom.xml                   → Java/Maven Project
*.html only               → Static HTML
```

---

## Fault Tolerance Summary

| Channel | Failure Condition | Behavior |
|---------|-------------------|----------|
| AgentMemory | MCP not configured | Return `[]`, continue |
| Git | Not a git repo | Return `""`, continue |
| Specs | No specs directory | Return `[]`, continue |
| Codegraph | Not initialized | Return `null`, continue |
| README | No README files | Return `[]`, continue |
| File Scan | (Always succeeds) | N/A |

**⚠️ File Scan 关键问题**: Glob 工具的 `*.js` 模式会返回 `node_modules` 下的文件，这与标准 glob 行为不同。必须**手动过滤**结果，排除包含 `node_modules/`、`.git/`、`dist/`、`build/` 等路径的文件。

**Key Principle**: No single channel failure stops the summary. We use what's available.

---

## Token Budget

| Mode | Tokens | Time |
|------|--------|------|
| Fast | ~800-1500 | ~1s |
| Full | ~3000-5000 | ~3s |

---

## Example Usage

```
User: /mesh-sum

Output:
## snake-game Summary

### 📊 Channel Status
| Channel | Status | Data |
|---------|--------|------|
| AgentMemory | ✅ | 2 memories |
| Git History | ✅ | 15 commits |
| Specs | ✅ | 2 specs |
| Codegraph | ⚠️ Not initialized | - |

### Overview
A snake game with colorful visuals and multi-food system.

### Tech Stack
| Layer | Technology |
|-------|------------|
| Language | JavaScript |
| Framework | None (vanilla) |

### Core Features
| Feature | Status | Source |
|---------|--------|--------|
| Wall wrap-around | ✅ | spec |
| Multi-food system | ✅ | git |
| Color inheritance | ✅ | memory |
```

---
