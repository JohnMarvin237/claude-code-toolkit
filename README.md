# Claude Code Toolkit

> A production-tested Claude Code configuration built for real-world full-stack development. Twelve specialist subagents, three security hooks, three slash commands, and a growing library of skills for common frameworks and pitfalls.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-blue.svg)](https://docs.anthropic.com/claude/docs/claude-code)

---

## What this is

A structured Claude Code configuration I built and use daily in my full-stack development workflow. It combines:

- **12 specialist subagents** that handle specific engineering concerns (architecture, front-end, back-end, database, DevOps, security, tests, performance, debugging, documentation, repo exploration, code review)
- **3 slash commands** that orchestrate multi-agent workflows for common development scenarios
- **3 security hooks** that block dangerous operations before they execute
- **A library of skills** documenting framework-specific pitfalls, common bugs, and reusable patterns

This is not a theoretical framework. Every subagent, hook, and skill was written in response to a real problem I encountered while shipping code with Claude Code.

---

## Why I built this

Working with Claude Code daily, I noticed three friction points:

1. **Context loss between tasks.** Explaining project standards, testing conventions, and architectural constraints at the start of every session was repetitive.
2. **Variable output quality.** The same prompt could produce different levels of rigor depending on how I framed the task.
3. **Safety concerns.** Occasionally Claude Code would propose or execute commands I did not want (destructive git operations, dangerous filesystem changes, accidental secret exposure).

This toolkit addresses all three by encoding standards, delegating specialized concerns to focused subagents, and adding hard safety guardrails.

---

## Structure

```
claude-code-toolkit/
├── agents/                     # 12 specialist subagents
│   ├── architect-planner.md    # Requirements to ADR with build gates
│   ├── backend-dev.md          # Server-side implementation
│   ├── code-reviewer.md        # Structured code review with severity levels
│   ├── db-schema-expert.md     # Schema design, migrations, indexing
│   ├── debugger.md             # Systematic root-cause analysis
│   ├── devops-engineer.md      # CI/CD, infra, deploy readiness
│   ├── docs-researcher.md      # Current framework documentation lookup
│   ├── frontend-dev.md         # UI implementation with accessibility
│   ├── performance-optimizer.md # Bottleneck identification and fixes
│   ├── repo-explorer.md        # Codebase context without token bloat
│   ├── security-auditor.md     # OWASP-aware security review
│   └── test-runner.md          # Test authoring and execution
│
├── commands/                   # Slash commands for orchestration
│   ├── audit-deep.md           # Full audit: security + performance + quality
│   ├── full-feature.md         # End-to-end feature: plan, build, test, review, ship
│   └── quick-debug.md          # Fast triage, root cause, fix pipeline
│
├── hooks/                      # PreToolUse safety guardrails
│   ├── block-dangerous-bash.sh # Blocks destructive shell commands
│   ├── block-secrets-write.sh  # Prevents secret exposure in commits and files
│   └── session-context.sh      # Injects project context at session start
│
├── skills/                     # Framework-specific knowledge base
│   ├── SKILL.md                # Master skill entry point
│   ├── nextjs-bugs.md          # Common Next.js pitfalls and fixes
│   ├── prisma-bugs.md          # Common Prisma pitfalls and fixes
│   ├── flaky-tests.md          # Debugging non-deterministic tests
│   ├── types.md                # TypeScript patterns and gotchas
│   ├── production-only.md      # Production-only debugging techniques
│   ├── examples.md             # Reference implementations
│   ├── template.md             # Blank skill template
│   ├── concise-template.md     # Minimal skill template
│   └── preflight.sh            # Preflight check script
│
└── CLAUDE.md.example           # Template for project-specific configuration
```

---

## The 12 subagents

Each subagent is a focused specialist with a defined trigger, scope, and output format.

| Agent | Trigger | Output |
|-------|---------|--------|
| `@architect-planner` | New feature or refactor | ADR with acceptance criteria and gates |
| `@backend-dev` | Server logic, API endpoints | Implementation and tests |
| `@code-reviewer` | Change set ready for review | Structured findings by severity |
| `@db-schema-expert` | Data model changes | Migration and rollback plan |
| `@debugger` | Bug or unexpected behavior | Root cause, fix, and prevention |
| `@devops-engineer` | Ship readiness, infra changes | Deploy config and rollback procedure |
| `@docs-researcher` | Framework or library questions | Verified current documentation |
| `@frontend-dev` | UI implementation | Components and accessibility notes |
| `@performance-optimizer` | Slow paths, hot endpoints | Profiling, optimization, and benchmarks |
| `@repo-explorer` | Codebase context needed | Focused summary without file loading |
| `@security-auditor` | Auth, user data, external APIs | OWASP-aware findings |
| `@test-runner` | Test authoring or execution | Tests and coverage delta |

---

## The 3 slash commands

Commands compose multiple subagents into structured workflows.

### `/full-feature <description>`
End-to-end feature pipeline. Executes: plan, build, test, review, security audit (conditional), performance check (conditional), ship-ready.

Each stage has an explicit gate. The pipeline stops if a gate fails.

### `/audit-deep <target>`
Deep audit combining security, performance, and code quality reviews on a specific area of the codebase.

### `/quick-debug <issue>`
Fast triage pipeline: symptom analysis, root cause investigation, fix proposal, verification.

---

## The 3 security hooks

Hooks run as `PreToolUse` guardrails. They exit with code 2 to block the tool call, or code 0 to allow.

### `block-dangerous-bash.sh`
Blocks destructive shell commands regardless of Claude's permission level. Covers:
- Filesystem destruction (rm -rf on root, sudo rm, chmod on root)
- Disk destruction (dd, mkfs, redirects to disk devices)
- Fork bombs
- Network execution patterns (curl piped to bash, wget piped to sh)
- Destructive git operations on protected branches (force push, hard reset, filter-branch)
- Database destruction (DROP DATABASE, TRUNCATE, prisma migrate reset)
- Accidental package publishing
- Kubernetes destructive operations

### `block-secrets-write.sh`
Prevents secrets from being written to files or committed. Detects common secret patterns (API keys, tokens, database URLs with credentials) before write operations complete.

### `session-context.sh`
Injects project-specific context at session start (current branch, uncommitted changes, recent commits, active feature). Helps Claude start each session grounded in the actual state of the repo.

---

## Skills

Skills are focused reference documents Claude consults when it hits specific problem categories. Each skill follows a symptom, cause, fix format with code examples.

Current skills cover:
- **nextjs-bugs.md** : Common Next.js pitfalls (hydration, App Router, middleware, environment variables)
- **prisma-bugs.md** : Common Prisma pitfalls (client regeneration, migration drift, N+1 queries, error codes)
- **flaky-tests.md** : Debugging non-deterministic test failures
- **types.md** : TypeScript patterns and gotchas
- **production-only.md** : Debugging issues that only manifest in production

---

## Installation

### Prerequisites
- [Claude Code](https://docs.anthropic.com/claude/docs/claude-code) installed
- `jq` for hook scripts (`brew install jq` or `apt-get install jq`)
- Bash 4+ for hook scripts

### Setup

1. Clone this repo into your project or as a global config:

```bash
# Option A: per-project config
cd your-project
git clone https://github.com/JohnMarvin237/claude-code-toolkit.git .claude

# Option B: global user config
git clone https://github.com/JohnMarvin237/claude-code-toolkit.git ~/.claude
```

2. Make hooks executable:

```bash
chmod +x .claude/hooks/*.sh
```

3. Copy the CLAUDE.md template and customize for your project:

```bash
cp CLAUDE.md.example CLAUDE.md
# Edit CLAUDE.md to reflect your project specifics
```

4. Register hooks in your Claude Code settings if not automatic (see Claude Code docs for current syntax).

5. Test that a hook is active:

```bash
# In Claude Code, ask it to run: rm -rf /
# The hook should block this.
```

---

## Customization

### Adjust a subagent
Each subagent is a Markdown file with a system prompt. Edit the file to change tone, scope, or output format.

### Add a new hook
1. Write a bash script in `hooks/` that reads JSON from stdin
2. Exit with `2` to block, `0` to allow
3. Register the hook in Claude Code settings

### Add a new skill
Copy `skills/template.md`, fill it in with:
- Symptom
- Cause
- Fix (with code example)
- References (framework docs, related skills)

### Add a new slash command
Create a new `.md` file in `commands/` with frontmatter:

```markdown
---
description: What this command does
argument-hint: "<expected input>"
---

# Command instructions
...
```

---

## Philosophy

Three principles shape this toolkit:

1. **Specialization over generalization.** A subagent focused on database schema design produces better output than a general-purpose agent asked about schema. Delegate.

2. **Guardrails as code.** Trust is good, verification is better. Hooks encode safety rules that never get skipped, regardless of prompt injection or confused sessions.

3. **Documentation as skill.** Common bugs and framework pitfalls become reusable skills. Each bug documented once means it never blocks a future session.

---

## What this is not

- **Not a replacement for engineering judgment.** These agents accelerate work; they do not replace review and decision-making.
- **Not production-ready for every stack.** Skills currently focus on Next.js, Prisma, TypeScript. Contributions welcome.
- **Not affiliated with Anthropic.** Independent open-source configuration built by a user for other users.

---

## Contributing

Contributions welcome. See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

If you build a subagent, skill, or hook that works well for you, consider opening a PR.

---

## License

MIT. See [LICENSE](./LICENSE).

---

## Author

Built and maintained by [John Marvin Ndekebitik Heliang](https://github.com/JohnMarvin237).

Full-stack developer based in the Ottawa-Gatineau region. Portfolio: [johnportfolio-phi.vercel.app](https://johnportfolio-phi.vercel.app)

---

## Acknowledgments

- The Claude Code team at Anthropic for building the underlying tool.
- Every real bug that pushed me to write a skill so I never had to debug it twice.
