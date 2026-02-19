#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Svrnty Team Setup — One-Time Setup
#
# Usage:
#   git clone <repo-url> ~/Developer/svrnty-team-setup
#   ~/Developer/svrnty-team-setup/setup.sh
#
# This script:
#   1. Installs all dependencies (Bun, Overstory, Mulch, Beads, jq)
#   2. Verifies Claude Code, tmux, Node.js, git
#   3. Configures Claude Code global settings for agent teams
#   4. Registers the plugin via shell alias
#   5. Makes all scripts executable
# ============================================================================

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }

# Cross-platform sed -i wrapper (macOS vs Linux)
sedi() {
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Warn if plugin is in a temporary directory
case "$PLUGIN_DIR" in
    /tmp/*|/var/tmp/*)
        echo ""
        warn "Plugin is in a temporary directory: $PLUGIN_DIR"
        warn "This path will be wiped on reboot!"
        echo ""
        info "Recommended: move the plugin to a permanent location:"
        echo "    mv $PLUGIN_DIR ~/Developer/svrnty-team-setup"
        echo "    ~/Developer/svrnty-team-setup/setup.sh"
        echo ""
        read -rp "Continue anyway? [y/N] " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Aborting. Move the plugin first."
            exit 1
        fi
        ;;
esac

echo ""
echo -e "${BOLD}==========================================="
echo " Svrnty Team Setup"
echo -e "===========================================${NC}"
echo ""
echo "Plugin directory: $PLUGIN_DIR"
echo ""

MISSING=()
INSTALLED=()

# -------------------------------------------------------
# 1. Prerequisites (must exist, won't auto-install)
# -------------------------------------------------------
echo -e "${BOLD}--- [1/6] Prerequisites ---${NC}"

# Git
if command -v git &>/dev/null; then
    ok "git $(git --version 2>/dev/null | head -1)"
else
    fail "git not found — install from https://git-scm.com"
    MISSING+=("git")
fi

# Node.js
if command -v node &>/dev/null; then
    ok "Node $(node --version)"
else
    fail "Node.js not found — install from https://nodejs.org"
    MISSING+=("node")
fi

# npm
if command -v npm &>/dev/null; then
    ok "npm $(npm --version)"
else
    fail "npm not found — comes with Node.js"
    MISSING+=("npm")
fi

# tmux
if command -v tmux &>/dev/null; then
    ok "tmux $(tmux -V 2>/dev/null)"
else
    info "Installing tmux..."
    if command -v brew &>/dev/null; then
        brew install tmux && ok "tmux installed" || { fail "tmux install failed"; MISSING+=("tmux"); }
    elif command -v apt-get &>/dev/null; then
        sudo apt-get install -y tmux && ok "tmux installed" || { fail "tmux install failed"; MISSING+=("tmux"); }
    else
        fail "tmux not found — install with: brew install tmux (macOS) or sudo apt-get install tmux (Debian/Ubuntu)"
        MISSING+=("tmux")
    fi
fi

# Claude Code
if command -v claude &>/dev/null; then
    ok "Claude Code $(claude --version 2>/dev/null | head -1 || echo 'installed')"
else
    fail "Claude Code not found — install from: npm install -g @anthropic-ai/claude-code"
    MISSING+=("claude")
fi

# jq (required by hook scripts)
if command -v jq &>/dev/null; then
    ok "jq $(jq --version 2>/dev/null)"
else
    info "Installing jq..."
    if command -v brew &>/dev/null; then
        brew install jq && ok "jq installed" || { fail "jq install failed"; MISSING+=("jq"); }
    elif command -v apt-get &>/dev/null; then
        sudo apt-get install -y jq && ok "jq installed" || { fail "jq install failed"; MISSING+=("jq"); }
    else
        fail "jq not found — install with: brew install jq"
        MISSING+=("jq")
    fi
fi
echo ""

# -------------------------------------------------------
# 2. Agent stack (auto-install)
# -------------------------------------------------------
echo -e "${BOLD}--- [2/6] Agent Stack ---${NC}"

# Bun — ensure ~/.bun/bin is in PATH so we detect existing installs
if [ -d "$HOME/.bun/bin" ]; then
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi
if command -v bun &>/dev/null; then
    ok "Bun $(bun --version)"
else
    info "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
    if command -v bun &>/dev/null; then
        ok "Bun $(bun --version) installed"
        INSTALLED+=("bun")
    else
        fail "Bun installation failed"
        MISSING+=("bun")
    fi
fi

# Overstory
if command -v overstory &>/dev/null; then
    ok "Overstory $(overstory --version 2>/dev/null | head -1 || echo 'installed')"
else
    info "Installing Overstory..."
    OVERSTORY_DIR="$HOME/Developer/overstory"
    mkdir -p "$HOME/Developer"
    if [ -d "$OVERSTORY_DIR/.git" ]; then
        cd "$OVERSTORY_DIR" && git pull
    else
        git clone https://github.com/jayminwest/overstory.git "$OVERSTORY_DIR"
    fi
    cd "$OVERSTORY_DIR"
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
    bun install && bun link
    cd "$PLUGIN_DIR"
    # Create a wrapper script so overstory is immediately executable
    mkdir -p "$HOME/.local/bin"
    cat > "$HOME/.local/bin/overstory" << 'WRAPPER'
#!/bin/bash
exec "$HOME/.bun/bin/bun" "$HOME/.bun/install/global/node_modules/overstory/src/index.ts" "$@"
WRAPPER
    chmod +x "$HOME/.local/bin/overstory"
    # Ensure ~/.local/bin is in PATH for this session
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi
    if command -v overstory &>/dev/null; then
        ok "Overstory installed"
        INSTALLED+=("overstory")
    else
        warn "Overstory installed — add ~/.local/bin to your PATH"
        INSTALLED+=("overstory (add ~/.local/bin to PATH)")
    fi
fi

# Mulch
if command -v mulch &>/dev/null; then
    ok "Mulch $(mulch --version 2>/dev/null || echo 'installed')"
else
    info "Installing Mulch (mulch-cli)..."
    npm install -g mulch-cli
    if command -v mulch &>/dev/null; then
        ok "Mulch installed"
        INSTALLED+=("mulch")
    else
        fail "Mulch installation failed — try: npm install -g mulch-cli"
        MISSING+=("mulch")
    fi
fi

# Beads
if command -v bd &>/dev/null; then
    ok "Beads $(bd --version 2>/dev/null | head -1 || echo 'installed')"
else
    info "Installing Beads..."
    if command -v brew &>/dev/null; then
        brew tap steveyegge/beads 2>/dev/null && brew install bd 2>/dev/null
    fi
    if ! command -v bd &>/dev/null; then
        npm install -g @beads/bd 2>/dev/null || true
    fi
    if command -v bd &>/dev/null; then
        ok "Beads installed"
        INSTALLED+=("beads")
    else
        fail "Beads installation failed"
        warn "Install manually from: https://github.com/steveyegge/beads"
        MISSING+=("bd")
    fi
fi

# Beads CGO check — the npm binary is often built without CGO, which breaks
# the Dolt storage backend on Linux. Detect and rebuild from source if needed.
if command -v bd &>/dev/null; then
    CGO_SCRIPT="$PLUGIN_DIR/scripts/ensure-bd-cgo.sh"
    if [ -f "$CGO_SCRIPT" ]; then
        source "$CGO_SCRIPT"
        ensure_bd_cgo || warn "bd CGO rebuild failed — bd init may not work"
    fi
fi
echo ""

# -------------------------------------------------------
# 3. Make scripts executable
# -------------------------------------------------------
echo -e "${BOLD}--- [3/6] Permissions ---${NC}"
chmod +x "$PLUGIN_DIR/hooks/"*.sh 2>/dev/null && ok "Hook scripts executable ($(ls "$PLUGIN_DIR/hooks/"*.sh 2>/dev/null | wc -l | tr -d ' ') files)" || warn "No hook scripts found"
chmod +x "$PLUGIN_DIR/scripts/"*.sh 2>/dev/null && ok "Skill scripts executable ($(ls "$PLUGIN_DIR/scripts/"*.sh 2>/dev/null | wc -l | tr -d ' ') files)" || warn "No skill scripts found"
chmod +x "$PLUGIN_DIR/setup.sh" 2>/dev/null || true
echo ""

# -------------------------------------------------------
# 4. Claude Code global settings
# -------------------------------------------------------
echo -e "${BOLD}--- [4/6] Claude Code Settings ---${NC}"

SETTINGS_FILE="$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude"

if [ -f "$SETTINGS_FILE" ]; then
    if grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$SETTINGS_FILE" 2>/dev/null; then
        ok "Agent teams already enabled in settings.json"
    else
        if command -v node &>/dev/null; then
            node -e "
const fs = require('fs');
const settings = JSON.parse(fs.readFileSync('$SETTINGS_FILE', 'utf8'));
settings.env = settings.env || {};
settings.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1';
settings.teammateMode = settings.teammateMode || 'tmux';
fs.writeFileSync('$SETTINGS_FILE', JSON.stringify(settings, null, 2) + '\n');
"
            ok "Agent teams enabled in settings.json"
        else
            warn "Could not update settings.json (node not available)"
        fi
    fi
else
    cat > "$SETTINGS_FILE" << 'JSON'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "teammateMode": "tmux"
}
JSON
    ok "Created settings.json with agent teams enabled"
fi
echo ""

# -------------------------------------------------------
# 5. Shell alias
# -------------------------------------------------------
echo -e "${BOLD}--- [5/6] Shell Alias ---${NC}"

if [[ "$SHELL" == *zsh* ]]; then
    SHELL_RC="$HOME/.zshrc"
else
    SHELL_RC="$HOME/.bashrc"
fi

ALIAS_LINE="alias claude='claude --plugin-dir $PLUGIN_DIR'"
ALIAS_MARKER="svrnty-team-setup"

# Remove any old hybrid-orchestration-plugin aliases
if grep -qF "hybrid-orchestration-plugin" "$SHELL_RC" 2>/dev/null; then
    sedi '/# Hybrid orchestration plugin/d' "$SHELL_RC" 2>/dev/null || true
    sedi '/hybrid-orchestration-plugin/d' "$SHELL_RC" 2>/dev/null || true
    info "Removed old hybrid-orchestration-plugin alias"
fi

if grep -qF "$ALIAS_MARKER" "$SHELL_RC" 2>/dev/null; then
    if grep -qF "$ALIAS_LINE" "$SHELL_RC" 2>/dev/null; then
        ok "Alias already configured"
    else
        sedi "/$ALIAS_MARKER/d" "$SHELL_RC" 2>/dev/null || true
        sedi '/svrnty-team-setup/d' "$SHELL_RC" 2>/dev/null || true
        echo "" >> "$SHELL_RC"
        echo "# Svrnty team setup — Claude Code plugin (auto-load) [$ALIAS_MARKER]" >> "$SHELL_RC"
        echo "$ALIAS_LINE" >> "$SHELL_RC"
        ok "Alias updated in $SHELL_RC"
    fi
else
    echo "" >> "$SHELL_RC"
    echo "# Svrnty team setup — Claude Code plugin (auto-load) [$ALIAS_MARKER]" >> "$SHELL_RC"
    echo "$ALIAS_LINE" >> "$SHELL_RC"
    ok "Alias added to $SHELL_RC"
fi

if ! grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$SHELL_RC" 2>/dev/null; then
    echo "export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1" >> "$SHELL_RC"
    ok "Agent teams env var added to $SHELL_RC"
fi
echo ""

# -------------------------------------------------------
# 6. Verification
# -------------------------------------------------------
echo -e "${BOLD}--- [6/6] Verification ---${NC}"

ALL_OK=true
for cmd in git node npm bun overstory mulch bd tmux claude jq; do
    if command -v "$cmd" &>/dev/null; then
        ok "$cmd"
    else
        fail "$cmd: NOT FOUND"
        ALL_OK=false
    fi
done

echo ""
if [ -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]; then
    ok "Plugin manifest"
else
    fail "Plugin manifest missing"
    ALL_OK=false
fi

if [ -f "$PLUGIN_DIR/hooks/hooks.json" ]; then
    HOOK_COUNT=$(ls "$PLUGIN_DIR/hooks/"*.sh 2>/dev/null | wc -l | tr -d ' ')
    ok "Hooks: $HOOK_COUNT scripts registered"
else
    fail "Hooks configuration missing"
    ALL_OK=false
fi

SKILL_COUNT=$(find "$PLUGIN_DIR/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
ok "Skills: $SKILL_COUNT commands (/svrnty:init, /svrnty:status, /svrnty:teardown)"

echo ""
echo "==========================================="
if $ALL_OK; then
    echo -e "${GREEN}${BOLD} Setup Complete!${NC}"
else
    echo -e "${YELLOW}${BOLD} Setup Complete (with warnings)${NC}"
    if [ ${#MISSING[@]} -gt 0 ]; then
        echo ""
        warn "Missing: ${MISSING[*]}"
    fi
fi
echo "==========================================="
echo ""
if [ ${#INSTALLED[@]} -gt 0 ]; then
    info "Newly installed: ${INSTALLED[*]}"
    echo ""
fi
echo "Next steps:"
echo "  1. Reload shell:    exec \$SHELL"
echo "  2. Start Claude:    claude --dangerously-skip-permissions"
echo "  3. In any project:  /svrnty:init backend frontend testing"
echo ""
echo "Available commands:"
echo "  /svrnty:init [domains...]   — Initialize orchestration in current project"
echo "  /svrnty:status              — Check stack status"
echo "  /svrnty:teardown            — Merge branches, sync, clean up"
echo ""
