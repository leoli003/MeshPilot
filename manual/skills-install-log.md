# skills CLI 安装日志

## 安装信息

| 项目 | 值 |
|------|-----|
| **包名** | `skills` |
| **版本** | 1.5.10 |
| **安装方式** | npm 全局安装 |
| **安装时间** | 2026-06-08 |
| **用途** | Agent Skills 生态系统 CLI 工具 |

## 安装命令

```bash
npm install -g skills
```

## 卸载命令

```bash
npm uninstall -g skills
```

## 主要功能

| 命令 | 说明 |
|------|------|
| `skills add <package>` | 安装技能包 |
| `skills use <package>@<skill>` | 不安装直接使用技能 |
| `skills find [query]` | 搜索技能 |
| `skills list` | 列出已安装技能 |
| `skills update` | 更新技能 |
| `skills remove` | 删除技能 |
| `skills init [name]` | 创建新技能模板 |

## 常用示例

```bash
# 搜索 git 相关技能
skills find git

# 安装技能到 Claude Code
skills add github/awesome-copilot@git-commit -a claude-code

# 不安装直接使用
skills use github/awesome-copilot@git-commit | claude

# 列出全局技能
skills ls -g

# 列出 Claude Code 技能
skills ls -a claude-code
```

## 技能发现平台

https://skills.sh

## 备注

- 包名是 `skills`，不是 `@vercel-labs/skills`
- 支持 67+ 种 coding agent
- 技能格式：SKILL.md (YAML frontmatter + Markdown)
