#!/usr/bin/env bash
# Hook: UserPromptSubmit — Check Overstory mail for pending agent messages
set -euo pipefail

if command -v overstory &>/dev/null && [ -d ".overstory" ]; then
    MAIL=$(overstory mail check 2>/dev/null || true)
    # Filter out empty results and any "no mail" variant
    if [ -n "$MAIL" ] && ! echo "$MAIL" | grep -qiE '^(no new (mail|message)|no unread|0 unread)'; then
        echo "## Incoming Agent Mail"
        echo "$MAIL"
    else
        echo "## Incoming Agent Mail"
        echo "No new messages."
    fi
fi
