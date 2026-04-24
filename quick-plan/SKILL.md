---
name: quick-plan
description: |
  Quickly generate implementation plans without user confirmation during planning phase.
  Triggers when user wants to create a plan, design implementation, or break down a task.
  Use this skill when user says: "quick plan", "快速plan", "帮我规划", "create a plan", "design implementation".
---

## What this skill does

Generates implementation plans in a single step, skipping the usual plan mode confirmation. After generating the plan, outputs it directly to the conversation for user review and modification.

## Usage

```
/mesh-quick-plan <task description>
```

Or simply describe what you want to plan:
```
帮我规划一个用户认证系统
```

## Workflow

1. **Analyze the task** - Understand what the user wants to implement
2. **Select appropriate agent** - Choose based on task nature:
   - `ecc:planner` - For complex features, architectural decisions, refactoring
   - `Plan` - For general planning tasks
   - `ecc:architect` - For system design, scalability, technical decisions
   - Default to `ecc:planner` if no specific match
3. **Generate plan** - Use selected agent to create comprehensive plan
4. **Output for review** - Present plan to user for confirmation/modification

## Agent Selection Logic

| Task Type | Agent |
|-----------|-------|
| Feature implementation, refactoring | ecc:planner |
| System architecture, scalability | ecc:architect |
| General planning, simple tasks | Plan |

## Output Format

```markdown
# Plan: [Task Name]

## Overview
[Brief description of what will be implemented]

## Steps
1. [Step 1]
   - Details: ...
   - Files: ...
2. [Step 2]
   ...

## Dependencies
- [Any dependencies needed]

## Risks
- [Potential issues to watch for]

## Estimated Effort
- [Time/complexity estimate]
```

## After Plan Generation

Once the plan is output:
1. Ask user: "请确认这个 plan，或者告诉我需要修改的地方"
2. Wait for user response
3. If modifications needed, update plan accordingly
4. Once confirmed, user can proceed with implementation

## Example

User: `/mesh-quick-plan 添加用户登录功能`

Output:
```markdown
# Plan: 用户登录功能

## Overview
实现基于 JWT 的用户认证系统，包含登录、登出、token 刷新功能。

## Steps
1. 创建认证模块结构
   - Files: src/auth/, src/auth/types.ts
2. 实现 JWT token 管理
   - Files: src/auth/jwt.ts
3. 创建登录 API 端点
   - Files: src/api/auth.ts
4. 添加前端登录表单
   - Files: src/components/LoginForm.tsx
5. 集成认证中间件
   - Files: src/middleware/auth.ts

## Dependencies
- jsonwebtoken package
- bcrypt for password hashing

## Risks
- Token 存储安全性
- 密码传输加密

## Estimated Effort
- Medium: 2-3 days
```

请确认这个 plan，或者告诉我需要修改的地方。
```

## Notes

- This skill is designed for speed - no intermediate confirmations
- The plan is a starting point - user can always modify
- For complex tasks, the selected agent may do additional exploration
- Keep plans actionable and specific
