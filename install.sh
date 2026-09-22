#!/usr/bin/env bash
# install.sh — Claude Code agents + hooks + settings installer
#
# Installs:
#   ~/.claude/agents/        12 specialist subagents
#   ~/.claude/commands/      3 custom slash commands
#   ~/.claude/skills/        7 reusable skills (commit-message, pr-description, etc.)
#   ~/.claude/hooks/         3 safety/context hook scripts
#   ~/.claude/settings.json  global config
#
# Usage:
#   ./install.sh                    # install everything (backs up existing files)
#   ./install.sh --project PATH     # also copy CLAUDE.md into that project
#   ./install.sh --dry-run          # show what would be done, don't modify anything
#   ./install.sh --uninstall        # remove everything (with confirmation)
#   ./install.sh --help             # show usage

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
AGENTS_DIR="$CLAUDE_DIR/agents"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SKILLS_DIR="$CLAUDE_DIR/skills"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$CLAUDE_DIR/backup-$TIMESTAMP"

DRY_RUN=0
UNINSTALL=0
PROJECT_PATH=""

# ── Colors (respects NO_COLOR) ────────────────────────────────────────────
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RESET="$(printf '\033[0m')"
  C_RED="$(printf '\033[31m')"
  C_GREEN="$(printf '\033[32m')"
  C_YELLOW="$(printf '\033[33m')"
  C_BLUE="$(printf '\033[34m')"
  C_BOLD="$(printf '\033[1m')"
else
  C_RESET=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_BOLD=""
fi

info()    { echo "${C_BLUE}ℹ${C_RESET}  $*"; }
ok()      { echo "${C_GREEN}✓${C_RESET}  $*"; }
warn()    { echo "${C_YELLOW}⚠${C_RESET}  $*"; }
err()     { echo "${C_RED}✗${C_RESET}  $*" >&2; }
header()  { echo ""; echo "${C_BOLD}▸ $*${C_RESET}"; }

# ── Usage ─────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
${C_BOLD}Claude Code agents installer${C_RESET}

USAGE
  $(basename "$0") [--project PATH] [--dry-run] [--uninstall] [--help]

OPTIONS
  --project PATH   Also copy CLAUDE.md to the given project directory
  --dry-run        Show what would be done without modifying anything
  --uninstall      Remove all files installed by this script (with backups)
  --help           Show this message

LOCATIONS
  Agents     → $AGENTS_DIR
  Commands   → $COMMANDS_DIR
  Skills     → $SKILLS_DIR
  Hooks      → $HOOKS_DIR
  Settings   → $SETTINGS_FILE
  Backups    → $CLAUDE_DIR/backup-<timestamp>/
EOF
}

# ── Arg parsing ───────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)    DRY_RUN=1; shift ;;
    --uninstall)  UNINSTALL=1; shift ;;
    --project)    PROJECT_PATH="${2:-}"; shift 2 ;;
    --help|-h)    usage; exit 0 ;;
    *)            err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# ── Dry-run wrapper ───────────────────────────────────────────────────────
run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "    [dry-run] $*"
  else
    eval "$@"
  fi
}

# ── Dependency checks ─────────────────────────────────────────────────────
check_dependencies() {
  header "Checking dependencies"

  local missing=0

  if command -v jq >/dev/null 2>&1; then
    ok "jq found ($(jq --version))"
  else
    err "jq is required for hooks to work (parses JSON on stdin)"
    case "$(uname -s)" in
      Darwin)  echo "    Install with: brew install jq" ;;
      Linux)   echo "    Install with: sudo apt-get install jq   (or equivalent)" ;;
    esac
    missing=1
  fi

  if command -v claude >/dev/null 2>&1; then
    ok "Claude Code CLI found ($(claude --version 2>/dev/null | head -1))"
  else
    warn "Claude Code CLI not found in PATH — hooks and agents will install, but"
    warn "you need Claude Code to use them. Install: https://claude.com/claude-code"
  fi

  if command -v git >/dev/null 2>&1; then
    ok "git found"
  else
    warn "git not found — session-context hook will silently no-op outside repos (fine)"
  fi

  if [ $missing -eq 1 ]; then
    err "Missing required dependencies. Aborting."
    exit 1
  fi
}

# ── Source file verification ──────────────────────────────────────────────
verify_sources() {
  header "Verifying source files"

  local errors=0

  for dir in agents commands skills hooks; do
    if [ ! -d "$SCRIPT_DIR/$dir" ]; then
      err "Missing directory: $SCRIPT_DIR/$dir"
      errors=$((errors + 1))
    fi
  done

  if [ ! -f "$SCRIPT_DIR/settings.json" ]; then
    err "Missing file: $SCRIPT_DIR/settings.json"
    errors=$((errors + 1))
  fi

  local agent_count
  agent_count="$(find "$SCRIPT_DIR/agents" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
  local command_count
  command_count="$(find "$SCRIPT_DIR/commands" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
  local skill_count
  skill_count="$(find "$SCRIPT_DIR/skills" -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')"
  local hook_count
  hook_count="$(find "$SCRIPT_DIR/hooks" -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')"

  if [ "$errors" -gt 0 ]; then
    err "Cannot proceed. Make sure you're running install.sh from the claude-agents-config directory."
    exit 1
  fi

  ok "Found $agent_count agents, $command_count commands, $skill_count skills, $hook_count hooks"
}

# ── Backup existing ───────────────────────────────────────────────────────
backup_existing() {
  header "Backing up existing config"

  local needs_backup=0

  for target in "$AGENTS_DIR" "$COMMANDS_DIR" "$SKILLS_DIR" "$HOOKS_DIR" "$SETTINGS_FILE"; do
    if [ -e "$target" ]; then
      needs_backup=1
      break
    fi
  done

  if [ "$needs_backup" -eq 0 ]; then
    info "Nothing to back up (clean install)"
    return 0
  fi

  run "mkdir -p \"$BACKUP_DIR\""

  [ -d "$AGENTS_DIR" ]     && run "cp -R \"$AGENTS_DIR\"    \"$BACKUP_DIR/agents\""
  [ -d "$COMMANDS_DIR" ]   && run "cp -R \"$COMMANDS_DIR\"  \"$BACKUP_DIR/commands\""
  [ -d "$SKILLS_DIR" ]     && run "cp -R \"$SKILLS_DIR\"    \"$BACKUP_DIR/skills\""
  [ -d "$HOOKS_DIR" ]      && run "cp -R \"$HOOKS_DIR\"     \"$BACKUP_DIR/hooks\""
  [ -f "$SETTINGS_FILE" ]  && run "cp    \"$SETTINGS_FILE\" \"$BACKUP_DIR/settings.json\""

  ok "Existing config backed up to $BACKUP_DIR"
}

# ── Install agents ────────────────────────────────────────────────────────
install_agents() {
  header "Installing agents"
  run "mkdir -p \"$AGENTS_DIR\""
  run "cp \"$SCRIPT_DIR/agents/\"*.md \"$AGENTS_DIR/\""
  local count
  count="$(find "$SCRIPT_DIR/agents" -name '*.md' | wc -l | tr -d ' ')"
  ok "Installed $count agents to $AGENTS_DIR"
  if [ "$DRY_RUN" -eq 0 ]; then
    find "$SCRIPT_DIR/agents" -name '*.md' -exec basename {} \; | sed 's/^/    /'
  fi
}

# ── Install commands ──────────────────────────────────────────────────────
install_commands() {
  header "Installing slash commands"
  run "mkdir -p \"$COMMANDS_DIR\""
  run "cp \"$SCRIPT_DIR/commands/\"*.md \"$COMMANDS_DIR/\""
  local count
  count="$(find "$SCRIPT_DIR/commands" -name '*.md' | wc -l | tr -d ' ')"
  ok "Installed $count commands to $COMMANDS_DIR"
  if [ "$DRY_RUN" -eq 0 ]; then
    find "$SCRIPT_DIR/commands" -name '*.md' -exec basename {} \; | sed 's|\.md$||; s|^|    /|'
  fi
}

# ── Install skills ────────────────────────────────────────────────────────
install_skills() {
  header "Installing skills"
  run "mkdir -p \"$SKILLS_DIR\""
  # Each skill is a directory containing SKILL.md — copy each skill dir
  for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    local skill_name
    skill_name="$(basename "$skill_dir")"
    run "mkdir -p \"$SKILLS_DIR/$skill_name\""
    run "cp -R \"$skill_dir\"* \"$SKILLS_DIR/$skill_name/\""
  done
  local count
  count="$(find "$SCRIPT_DIR/skills" -name 'SKILL.md' | wc -l | tr -d ' ')"
  ok "Installed $count skills to $SKILLS_DIR"
  if [ "$DRY_RUN" -eq 0 ]; then
    find "$SCRIPT_DIR/skills" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sed 's/^/    /'
  fi
}

# ── Install hooks ─────────────────────────────────────────────────────────
install_hooks() {
  header "Installing hook scripts"
  run "mkdir -p \"$HOOKS_DIR\""
  run "cp \"$SCRIPT_DIR/hooks/\"*.sh \"$HOOKS_DIR/\""
  run "chmod +x \"$HOOKS_DIR/\"*.sh"
  ok "Installed hook scripts to $HOOKS_DIR (chmod +x applied)"
  if [ "$DRY_RUN" -eq 0 ]; then
    find "$SCRIPT_DIR/hooks" -name '*.sh' -exec basename {} \; | sed 's/^/    /'
  fi
}

# ── Install settings.json ─────────────────────────────────────────────────
install_settings() {
  header "Installing settings.json"

  if [ -f "$SETTINGS_FILE" ] && [ "$DRY_RUN" -eq 0 ]; then
    warn "Existing settings.json found (already backed up to $BACKUP_DIR)"
    warn "Overwriting. Review the backup if you had custom rules."
  fi

  run "cp \"$SCRIPT_DIR/settings.json\" \"$SETTINGS_FILE\""
  ok "Installed settings.json to $SETTINGS_FILE"
}

# ── Optional: copy CLAUDE.md to a project ─────────────────────────────────
copy_project_template() {
  [ -z "$PROJECT_PATH" ] && return 0

  header "Installing project template"

  if [ ! -d "$PROJECT_PATH" ]; then
    err "Project path does not exist: $PROJECT_PATH"
    return 1
  fi

  local target="$PROJECT_PATH/CLAUDE.md"

  if [ -f "$target" ] && [ "$DRY_RUN" -eq 0 ]; then
    local project_backup="$target.backup-$TIMESTAMP"
    cp "$target" "$project_backup"
    warn "Existing CLAUDE.md backed up to $project_backup"
  fi

  run "cp \"$SCRIPT_DIR/CLAUDE.md\" \"$target\""
  ok "Installed CLAUDE.md to $target"
  info "Review and customize the template for your project"
}

# ── Uninstall ─────────────────────────────────────────────────────────────
uninstall() {
  header "Uninstalling"

  if [ "$DRY_RUN" -eq 0 ]; then
    printf "This will remove all files under %s/ (with a backup). Continue? [y/N] " "$CLAUDE_DIR"
    read -r confirm
    case "$confirm" in
      y|Y|yes|YES) ;;
      *) info "Aborted"; exit 0 ;;
    esac
  fi

  backup_existing

  run "rm -rf \"$AGENTS_DIR\""
  run "rm -rf \"$COMMANDS_DIR\""
  run "rm -rf \"$SKILLS_DIR\""
  run "rm -rf \"$HOOKS_DIR\""
  run "rm -f  \"$SETTINGS_FILE\""

  ok "Removed agents, commands, skills, hooks, and settings"
  info "Backup preserved at $BACKUP_DIR"
}

# ── Post-install verification ─────────────────────────────────────────────
verify_install() {
  [ "$DRY_RUN" -eq 1 ] && return 0

  header "Verifying installation"

  local errors=0

  for agent in "$SCRIPT_DIR"/agents/*.md; do
    [ -f "$agent" ] || continue
    local name; name="$(basename "$agent")"
    if [ ! -f "$AGENTS_DIR/$name" ]; then
      err "Missing installed agent: $name"
      errors=$((errors + 1))
    fi
  done

  for skill_dir in "$SCRIPT_DIR"/skills/*/; do
    [ -d "$skill_dir" ] || continue
    local skill_name; skill_name="$(basename "$skill_dir")"
    if [ ! -f "$SKILLS_DIR/$skill_name/SKILL.md" ]; then
      err "Missing installed skill: $skill_name"
      errors=$((errors + 1))
    fi
  done

  for hook in "$SCRIPT_DIR"/hooks/*.sh; do
    [ -f "$hook" ] || continue
    local name; name="$(basename "$hook")"
    if [ ! -x "$HOOKS_DIR/$name" ]; then
      err "Hook not executable: $name"
      errors=$((errors + 1))
    fi
  done

  if [ ! -f "$SETTINGS_FILE" ]; then
    err "settings.json not installed"
    errors=$((errors + 1))
  fi

  # Validate settings.json is valid JSON
  if command -v jq >/dev/null 2>&1 && [ -f "$SETTINGS_FILE" ]; then
    if jq empty "$SETTINGS_FILE" 2>/dev/null; then
      ok "settings.json is valid JSON"
    else
      err "settings.json is NOT valid JSON — check the file"
      errors=$((errors + 1))
    fi
  fi

  if [ "$errors" -eq 0 ]; then
    ok "All files verified"
    return 0
  else
    err "$errors verification errors"
    return 1
  fi
}

# ── Next steps message ────────────────────────────────────────────────────
next_steps() {
  [ "$DRY_RUN" -eq 1 ] && return 0

  cat <<EOF

${C_BOLD}${C_GREEN}Installation complete!${C_RESET}

${C_BOLD}Next steps:${C_RESET}
  1. Open Claude Code in your project:   ${C_BLUE}claude${C_RESET}
  2. List available agents:               ${C_BLUE}/agents${C_RESET}
  3. Verify hooks are loaded:             ${C_BLUE}/hooks${C_RESET}
  4. Try an agent explicitly:             ${C_BLUE}@repo-explorer where is auth configured?${C_RESET}
  5. Try a slash command:                 ${C_BLUE}/full-feature add a dark mode toggle${C_RESET}
  6. Try a skill (auto-triggered):        ${C_BLUE}write a commit message for these changes${C_RESET}

${C_BOLD}Per-project setup:${C_RESET}
  Copy ${C_BLUE}CLAUDE.md${C_RESET} to your project root (or re-run with ${C_BLUE}--project PATH${C_RESET}).

${C_BOLD}Customization:${C_RESET}
  • Agents:  $AGENTS_DIR/*.md
  • Skills:  $SKILLS_DIR/*/SKILL.md
  • Hooks:   $HOOKS_DIR/*.sh  (your safety net — edit with care)
  • Config:  $SETTINGS_FILE

${C_BOLD}Uninstall:${C_RESET}
  ${C_BLUE}./install.sh --uninstall${C_RESET}

EOF
}

# ── Main ──────────────────────────────────────────────────────────────────
main() {
  echo "${C_BOLD}Claude Code agents installer${C_RESET}"

  if [ "$DRY_RUN" -eq 1 ]; then
    warn "DRY RUN — no files will be modified"
  fi

  check_dependencies

  if [ "$UNINSTALL" -eq 1 ]; then
    uninstall
    exit 0
  fi

  verify_sources
  backup_existing
  install_agents
  install_commands
  install_skills
  install_hooks
  install_settings
  copy_project_template
  verify_install
  next_steps
}

main "$@"