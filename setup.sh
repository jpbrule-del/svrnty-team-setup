#!/usr/bin/env bash
# Thin wrapper — delegates to scripts/setup.sh
exec bash "$(cd "$(dirname "$0")" && pwd)/scripts/setup.sh" "$@"
