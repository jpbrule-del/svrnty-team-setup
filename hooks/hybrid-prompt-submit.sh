#!/usr/bin/env bash
# Hook: UserPromptSubmit — Check Overstory mail for pending agent messages
set -euo pipefail

if command -v overstory &>/dev/null && [ -d ".overstory" ]; then
    MAIL=$(overstory mail check 2>/dev/null || true)
    if [ -n "$MAIL" ] && [ "$MAIL" != "No new mail." ]; then
        echo "## Incoming Agent Mail"
        echo "$MAIL"
    fi
fi
