# Contributing to Claude Code Toolkit

Thanks for your interest in contributing. This toolkit grows from real-world use, so contributions are especially valuable when they come from actual pain points you have hit while using Claude Code.

## Ways to contribute

### Report an issue
Found a subagent that produces poor output for your stack? A hook that misses a dangerous pattern? A skill that is outdated?

Open an issue with:
- What you tried
- What happened
- What you expected

### Add a subagent
Do you have a specialist agent that works well? Open a PR with:
- The agent Markdown file in `agents/`
- A brief description of when to use it
- An example of its output

### Add a skill
Common bugs and framework pitfalls are perfect candidates. Follow the format of existing skills:
- Symptom
- Cause
- Fix (with code examples)
- References

### Add a hook
Guardrails welcome. Requirements:
- Bash script that reads JSON from stdin
- Exit 2 to block, 0 to allow
- Clear error message when blocking
- Tested against real dangerous inputs

### Improve documentation
Typos, unclear instructions, missing examples. All welcome.

## Pull request guidelines

- Keep PRs focused. One subagent, one skill, one hook per PR.
- Write clear commit messages.
- Update the README if you add new components.
- Test your changes with Claude Code before submitting.

## Code style

- Markdown files: use frontmatter for metadata
- Bash scripts: use `set -euo pipefail`
- Follow existing formatting conventions

## What we do not accept

- Content that could be used to compromise security (bypass authentication, exfiltrate data, etc.)
- Subagents that promote unsafe practices
- Skills without verified examples
- Contributions that violate the [Anthropic Usage Policies](https://www.anthropic.com/legal/aup)

## Questions

Open a discussion in the GitHub Discussions tab or reach out via the maintainer's portfolio.
