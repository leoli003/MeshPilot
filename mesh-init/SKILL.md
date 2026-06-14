---
name: mesh-init
description: 项目初始化技能。自动检测并初始化 CLAUDE.md、CodeGraph 和 OpenSpec 目录。当用户说"初始化项目"、"setup project"、"mesh-init"、"项目初始化"时触发，或在新项目开始时自动运行。
---

# Mesh Init - 项目智能初始化

一键完成项目的四大核心工具初始化，让 Claude Code 更智能地理解你的代码库。

## 快速开始

直接运行 `/mesh-init` 或说"初始化项目"，本技能将自动：

1. 检测并初始化 CLAUDE.md（项目指令文件）
2. 检测并初始化 CodeGraph（代码知识图谱）
3. 检测并初始化 OpenSpec（变更管理目录结构）

---

## 初始化流程

### Phase 1: CLAUDE.md 初始化

CLAUDE.md 是项目级别的指令文件，告诉 Claude 如何处理这个项目。

**检测逻辑：**
```bash
# 检查项目根目录是否存在 CLAUDE.md
test -f "$PROJECT_ROOT/CLAUDE.md"
```

**如果不存在：**
1. 分析项目结构（package.json / pyproject.toml / Cargo.toml 等）
2. 检测主要技术栈和框架
3. 生成基础 CLAUDE.md 模板：

```markdown
# 项目名称

## 技术栈
- 语言: [自动检测]
- 框架: [自动检测]
- 包管理器: [自动检测]

## 代码规范
- [根据项目类型添加规范]

## 重要文件
- [列出关键配置文件和入口点]

## 注意事项
- [根据项目特点生成的建议]
```

**如果存在：** 跳过，报告"✓ CLAUDE.md 已存在"

---

### Phase 2: CodeGraph 初始化

CodeGraph 是基于 SQLite 的代码知识图谱，让 Claude 能快速查询符号定义、调用关系、影响范围等。

**检测逻辑：**
```bash
# 检查 .codegraph 目录是否存在
test -d "$PROJECT_ROOT/.codegraph"
# 检查 codegraph 是否全局安装
command -v codegraph
```

**初始化步骤：**

1. **安装 CodeGraph（如未安装）：**
   ```bash
   npm install -g @anthropic-ai/codegraph
   ```
   或使用官方仓库版本：
   ```bash
   npm install -g @colbymchenry/codegraph
   ```

2. **初始化并索引项目：**
   ```bash
   cd "$PROJECT_ROOT"
   codegraph init -i
   ```

3. **验证初始化成功：**
   ```bash
   codegraph status
   ```

**CodeGraph 功能：**
- 符号搜索（函数、类、变量定义）
- 调用关系追踪（callers/callees）
- 影响范围分析（修改某符号会影响什么）
- 跨文件代码流追踪

**如果已存在：** 报告"✓ CodeGraph 已初始化"

---

### Phase 3: OpenSpec 目录初始化

OpenSpec 是 comet 技能的变更管理目录结构，用于管理变更流程和规格文档。

**检测逻辑：**
```bash
# 检查 openspec 目录是否存在
test -d "$PROJECT_ROOT/openspec"
```

**初始化步骤：**

1. **创建目录结构：**
   ```bash
   mkdir -p "$PROJECT_ROOT/openspec/changes"
   mkdir -p "$PROJECT_ROOT/openspec/specs"
   ```

2. **添加 .gitkeep（确保空目录可被 git 追踪）：**
   ```bash
   touch "$PROJECT_ROOT/openspec/changes/.gitkeep"
   touch "$PROJECT_ROOT/openspec/specs/.gitkeep"
   ```

**创建的目录用途：**
| 目录 | 用途 |
|------|------|
| `openspec/changes/` | 活跃的变更流程（由 comet-open 创建） |
| `openspec/specs/` | 规格文档（由 comet-build 维护） |

**与 comet 的关系：**
- `/comet-open <name>` 在 `openspec/changes/<name>/` 创建 proposal.md, design.md, tasks.md
- `/comet-archive` 将完成的变更移动到 `openspec/changes/archive/`
- mesh-init 只创建骨架目录，实际变更文件由 comet 子技能管理

**如果已存在：** 报告"✓ OpenSpec 目录已存在"

---

## 执行顺序

```
┌─────────────────────────────────────────────────────────────┐
│                     mesh-init 流程                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Phase 1: CLAUDE.md                                         │
│  ├── 检测 CLAUDE.md 是否存在                                 │
│  ├── [不存在] 分析项目 → 生成 CLAUDE.md                      │
│  └── [存在] ✓ 跳过                                          │
│                                                             │
│  Phase 2: CodeGraph                                         │
│  ├── 检测 .codegraph/ 目录                                  │
│  ├── 检测 codegraph 命令                                    │
│  ├── [未安装] npm install -g codegraph                      │
│  ├── [未初始化] codegraph init -i                           │
│  └── [已存在] ✓ 跳过                                        │
│                                                             │
│  Phase 3: OpenSpec                                          │
│  ├── 检测 openspec/ 目录                                    │
│  ├── [不存在] 创建 openspec/changes/ 和 openspec/specs/     │
│  └── [已存在] ✓ 跳过                                        │
│                                                             │
│  最终报告: 初始化状态摘要                                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 最终报告格式

```
╔═══════════════════════════════════════════════════════════════╗
║                    Mesh Init 完成报告                         ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  CLAUDE.md    [✓ 已存在 / ✓ 新建 / - 跳过]                    ║
║  CodeGraph    [✓ 已存在 / ✓ 新建 / ✗ 失败]                    ║
║  OpenSpec     [✓ 已存在 / ✓ 新建 / ✗ 失败]                    ║
║                                                               ║
║  项目根目录: /path/to/project                                 ║
║  技术栈: Node.js, TypeScript, React                           ║
║                                                               ║
║  下一步建议:                                                  ║
║  - 使用 codegraph_search 查询符号定义                         ║
║  - 使用 /comet-open 开始一个变更流程                          ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## 错误处理

| 错误情况 | 处理方式 |
|----------|----------|
| npm 不可用 | 提示用户安装 Node.js |
| 项目目录非 git 仓库 | 警告但不阻止初始化 |
| CodeGraph 初始化失败 | 记录错误，继续执行其他步骤 |
| OpenSpec 目录创建失败 | 记录错误，继续执行其他步骤 |
| 权限问题 | 提示用户检查目录权限 |

---

## 依赖要求

- Node.js 20+
- npm / pnpm / yarn
- Claude Code CLI
- Git（推荐，非必需）

---

## 触发条件

自动触发场景：
- 用户说"初始化项目"、"setup project"、"mesh-init"
- 用户说"init"、"初始化"、"项目设置"
- 用户在新目录开始工作，请求初始化

手动触发：
```
/mesh-init
```

强制重新初始化：
```
/mesh-init --force
```
（会备份现有配置后重新创建）
