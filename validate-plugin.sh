#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# validate-plugin.sh — Validate svrnty-team-setup plugin structure
#
# Checks:
#   1. Manifest exists and is valid JSON with required fields
#   2. All skills referenced in manifest have SKILL.md files
#   3. All commands referenced in manifest have .md files
#   4. All SKILL.md files have YAML frontmatter
#   5. All command .md files have YAML frontmatter
#   6. hooks.json exists, is valid JSON, all referenced scripts exist
#   7. All hook scripts use svrnty-* prefix (warning if not)
#   8. All scripts are executable
#   9. Required docs exist
# ============================================================================

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"

ERRORS=0
WARNINGS=0

ok()   { echo -e "\033[0;32m✓\033[0m $1"; }
warn() { echo -e "\033[1;33m⚠\033[0m $1"; WARNINGS=$((WARNINGS + 1)); }
fail() { echo -e "\033[0;31m✗\033[0m $1"; ERRORS=$((ERRORS + 1)); }
info() { echo -e "\033[1;36m→\033[0m $1"; }

echo ""
echo "==========================================="
echo " Plugin Validation"
echo "==========================================="
echo ""

# --- 1. Manifest ---
echo "--- [1/9] Manifest ---"
MANIFEST="$PLUGIN_DIR/.claude-plugin/plugin.json"

if [ -f "$MANIFEST" ]; then
    if jq empty "$MANIFEST" 2>/dev/null; then
        ok "Manifest is valid JSON"

        # Check required fields
        for field in name version description; do
            VALUE=$(jq -r ".$field // empty" "$MANIFEST" 2>/dev/null)
            if [ -n "$VALUE" ]; then
                ok "Manifest has '$field': $VALUE"
            else
                fail "Manifest missing required field: $field"
            fi
        done
    else
        fail "Manifest is not valid JSON"
    fi
else
    fail "Manifest not found at $MANIFEST"
fi
echo ""

# --- 2. Skills referenced in manifest ---
echo "--- [2/9] Skills ---"
if [ -f "$MANIFEST" ]; then
    SKILL_COUNT=$(jq -r '.skills // [] | length' "$MANIFEST" 2>/dev/null || echo "0")
    if [ "$SKILL_COUNT" -gt 0 ]; then
        for i in $(seq 0 $((SKILL_COUNT - 1))); do
            SKILL_PATH=$(jq -r ".skills[$i].path" "$MANIFEST" 2>/dev/null)
            RESOLVED_PATH="$PLUGIN_DIR/${SKILL_PATH#./}"
            if [ -f "$RESOLVED_PATH/SKILL.md" ]; then
                ok "Skill '$SKILL_PATH' has SKILL.md"
            else
                fail "Skill '$SKILL_PATH' missing SKILL.md at $RESOLVED_PATH/SKILL.md"
            fi
        done
    else
        warn "No skills defined in manifest"
    fi
else
    fail "Cannot check skills — manifest missing"
fi
echo ""

# --- 3. Commands referenced in manifest ---
echo "--- [3/9] Commands ---"
if [ -f "$MANIFEST" ]; then
    CMD_COUNT=$(jq -r '.commands // [] | length' "$MANIFEST" 2>/dev/null || echo "0")
    if [ "$CMD_COUNT" -gt 0 ]; then
        for i in $(seq 0 $((CMD_COUNT - 1))); do
            CMD_PATH=$(jq -r ".commands[$i].path" "$MANIFEST" 2>/dev/null)
            RESOLVED_PATH="$PLUGIN_DIR/${CMD_PATH#./}"
            if [ -f "$RESOLVED_PATH" ]; then
                ok "Command '$CMD_PATH' exists"
            else
                fail "Command '$CMD_PATH' not found at $RESOLVED_PATH"
            fi
        done
    else
        warn "No commands defined in manifest"
    fi
else
    fail "Cannot check commands — manifest missing"
fi
echo ""

# --- 4. SKILL.md YAML frontmatter ---
echo "--- [4/9] Skill Frontmatter ---"
while IFS= read -r -d '' skill_file; do
    if head -1 "$skill_file" | grep -q "^---$"; then
        ok "$(basename "$(dirname "$skill_file")")/SKILL.md has frontmatter"
    else
        fail "$(basename "$(dirname "$skill_file")")/SKILL.md missing YAML frontmatter"
    fi
done < <(find "$PLUGIN_DIR/skills" -name "SKILL.md" -print0 2>/dev/null)
echo ""

# --- 5. Command .md frontmatter ---
echo "--- [5/9] Command Frontmatter ---"
for cmd_file in "$PLUGIN_DIR/commands"/*.md; do
    [ -f "$cmd_file" ] || continue
    if head -1 "$cmd_file" | grep -q "^---$"; then
        ok "$(basename "$cmd_file") has frontmatter"
    else
        fail "$(basename "$cmd_file") missing YAML frontmatter"
    fi
done
echo ""

# --- 6. hooks.json validity + script references ---
echo "--- [6/9] Hooks Configuration ---"
HOOKS_JSON="$PLUGIN_DIR/hooks/hooks.json"

if [ -f "$HOOKS_JSON" ]; then
    if jq empty "$HOOKS_JSON" 2>/dev/null; then
        ok "hooks.json is valid JSON"

        # Extract all .sh filenames from hooks.json
        HOOK_SCRIPTS=$(jq -r '.. | .command? // empty' "$HOOKS_JSON" 2>/dev/null | grep -oE '[a-zA-Z0-9_-]+\.sh' || true)
        for script in $HOOK_SCRIPTS; do
            if [ -f "$PLUGIN_DIR/hooks/$script" ]; then
                ok "Hook script exists: $script"
            else
                fail "Hook script missing: $script (referenced in hooks.json)"
            fi
        done
    else
        fail "hooks.json is not valid JSON"
    fi
else
    fail "hooks.json not found"
fi
echo ""

# --- 7. Hook naming convention ---
echo "--- [7/9] Hook Naming Convention ---"
for hook_file in "$PLUGIN_DIR/hooks"/*.sh; do
    [ -f "$hook_file" ] || continue
    basename=$(basename "$hook_file")
    if [[ "$basename" == svrnty-* ]]; then
        ok "$basename uses svrnty-* prefix"
    else
        warn "$basename does not use svrnty-* prefix"
    fi
done
echo ""

# --- 8. Script permissions ---
echo "--- [8/9] Script Permissions ---"
for script in "$PLUGIN_DIR/hooks"/*.sh "$PLUGIN_DIR/scripts"/*.sh; do
    [ -f "$script" ] || continue
    basename=$(basename "$script")
    if [ -x "$script" ]; then
        ok "$basename is executable"
    else
        fail "$basename is not executable"
    fi
done
if [ -f "$PLUGIN_DIR/validate-plugin.sh" ] && [ -x "$PLUGIN_DIR/validate-plugin.sh" ]; then
    ok "validate-plugin.sh is executable"
elif [ -f "$PLUGIN_DIR/validate-plugin.sh" ]; then
    fail "validate-plugin.sh is not executable"
fi
echo ""

# --- 9. Required docs ---
echo "--- [9/9] Required Documentation ---"
for doc in README.md LICENSE VERSIONS.md CONTRIBUTING.md AGENTS.md; do
    if [ -f "$PLUGIN_DIR/$doc" ]; then
        ok "$doc exists"
    else
        fail "$doc missing"
    fi
done
echo ""

# --- Summary ---
echo "==========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "\033[0;32m\033[1m Validation Passed\033[0m"
else
    echo -e "\033[0;31m\033[1m Validation Failed\033[0m"
fi
echo "==========================================="
echo ""
echo -e "  Errors:   \033[0;31m$ERRORS\033[0m"
echo -e "  Warnings: \033[1;33m$WARNINGS\033[0m"
echo ""

exit $ERRORS
