#!/usr/bin/env bash
# Hook: Stop — Sync Beads + record Mulch learnings
set -euo pipefail

[ -d ".beads" ] && command -v bd &>/dev/null && bd sync 2>/dev/null || true
if command -v mulch &>/dev/null && [ -d ".mulch" ]; then
    mulch learn 2>/dev/null || true
    mulch sync 2>/dev/null || true
fi
