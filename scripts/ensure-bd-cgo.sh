#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# ensure-bd-cgo.sh — Verify bd binary has CGO support; rebuild if not.
#
# The npm-distributed @beads/bd binary is often compiled WITHOUT CGO,
# which breaks the Dolt storage backend on Linux.  This script detects
# the problem and transparently rebuilds from source with CGO_ENABLED=1.
#
# Usage (sourced by other scripts):
#   source "$(dirname "$0")/ensure-bd-cgo.sh"
#   ensure_bd_cgo          # exits 0 on success, 1 on failure
#
# Requirements: gcc (or build-essential), git, node (for npm bd path)
# Go is auto-installed to ~/.local/go if missing.
# ============================================================================

# Colours (inherit from caller or define fresh)
RED="${RED:-\033[0;31m}"; GREEN="${GREEN:-\033[0;32m}"
YELLOW="${YELLOW:-\033[1;33m}"; CYAN="${CYAN:-\033[1;36m}"; NC="${NC:-\033[0m}"
_ok()   { echo -e "${GREEN}✓${NC} $1"; }
_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
_fail() { echo -e "${RED}✗${NC} $1"; }
_info() { echo -e "${CYAN}→${NC} $1"; }

# ---------------------------------------------------------------------------
# Detect whether a bd binary was built with CGO (dynamically linked).
# Returns 0 if CGO is present, 1 otherwise.
# ---------------------------------------------------------------------------
_bd_has_cgo() {
    local bin="$1"
    if ! [ -f "$bin" ]; then return 1; fi

    # On Linux, a CGO binary is dynamically linked; a non-CGO binary is static.
    if command -v ldd &>/dev/null; then
        ldd "$bin" &>/dev/null 2>&1 && return 0 || return 1
    fi

    # Fallback: check `file` output for "dynamically linked"
    if command -v file &>/dev/null; then
        file "$bin" 2>/dev/null | grep -qi "dynamically linked" && return 0 || return 1
    fi

    # Cannot determine — assume OK
    return 0
}

# ---------------------------------------------------------------------------
# Locate the bd binary installed by npm (or in PATH).
# ---------------------------------------------------------------------------
_find_bd_binary() {
    # 1. Resolve the wrapper script to the real binary
    local bd_js
    bd_js="$(command -v bd 2>/dev/null || true)"
    if [ -n "$bd_js" ]; then
        local bd_dir
        bd_dir="$(dirname "$(readlink -f "$bd_js" 2>/dev/null || echo "$bd_js")")"
        if [ -f "$bd_dir/bd" ] && file "$bd_dir/bd" 2>/dev/null | grep -q "ELF"; then
            echo "$bd_dir/bd"
            return 0
        fi
    fi

    # 2. Search common npm global paths
    local candidates=(
        "$(npm root -g 2>/dev/null)/@beads/bd/bin/bd"
    )
    for c in "${candidates[@]}"; do
        if [ -f "$c" ] && file "$c" 2>/dev/null | grep -q "ELF"; then
            echo "$c"
            return 0
        fi
    done

    return 1
}

# ---------------------------------------------------------------------------
# Ensure Go is available (install to ~/.local/go if missing).
# ---------------------------------------------------------------------------
_ensure_go() {
    export PATH="$HOME/.local/go/bin:$HOME/go/bin:$PATH"
    if command -v go &>/dev/null; then return 0; fi

    _info "Installing Go (needed to rebuild bd with CGO)..."

    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64)  arch="amd64" ;;
        aarch64) arch="arm64" ;;
        *)       _fail "Unsupported architecture: $arch"; return 1 ;;
    esac

    local go_version="1.23.6"
    local tarball="go${go_version}.linux-${arch}.tar.gz"
    local url="https://go.dev/dl/${tarball}"

    curl -fsSL "$url" -o "/tmp/$tarball"
    mkdir -p "$HOME/.local"
    tar -C "$HOME/.local" -xzf "/tmp/$tarball"
    rm -f "/tmp/$tarball"

    export PATH="$HOME/.local/go/bin:$PATH"
    if command -v go &>/dev/null; then
        _ok "Go $(go version | awk '{print $3}') installed to ~/.local/go"
        return 0
    fi
    _fail "Go installation failed"
    return 1
}

# ---------------------------------------------------------------------------
# Rebuild bd from source with CGO_ENABLED=1 and replace the binary.
# ---------------------------------------------------------------------------
_rebuild_bd() {
    local target_bin="$1"
    local bd_version
    bd_version="$(bd version 2>/dev/null | awk '{print $3}' || echo "0.52.0")"

    # Strip leading 'v' if present for tag, keep for git tag
    local tag="v${bd_version#v}"

    _info "Rebuilding bd ${tag} from source with CGO_ENABLED=1..."

    # Verify C compiler
    if ! command -v gcc &>/dev/null && ! command -v cc &>/dev/null; then
        _fail "No C compiler found. Install build-essential: sudo apt-get install -y build-essential"
        return 1
    fi

    # Ensure Go
    _ensure_go || return 1

    # Clone at the matching tag
    local build_dir="/tmp/beads-cgo-build"
    rm -r "$build_dir" 2>/dev/null || true
    _info "Cloning beads ${tag}..."
    if ! git clone --depth 1 --branch "$tag" https://github.com/steveyegge/beads.git "$build_dir" 2>&1; then
        _fail "Failed to clone beads repo at tag $tag"
        return 1
    fi

    # Build
    cd "$build_dir"
    export CGO_ENABLED=1
    export GOTOOLCHAIN=auto
    _info "Compiling (this may take a minute on first build)..."
    if ! go build -ldflags="-X main.Build=$(git rev-parse --short HEAD)" -o ./bd ./cmd/bd 2>&1; then
        _fail "Build failed"
        cd - >/dev/null
        return 1
    fi

    # Verify new binary has CGO
    if ! _bd_has_cgo "./bd"; then
        _fail "Rebuilt binary still lacks CGO — check your C toolchain"
        cd - >/dev/null
        return 1
    fi

    # Replace the target binary
    cp ./bd "$target_bin"
    chmod 755 "$target_bin"

    # Also install to ~/.local/bin for PATH-based access
    mkdir -p "$HOME/.local/bin"
    cp ./bd "$HOME/.local/bin/bd"
    chmod 755 "$HOME/.local/bin/bd"
    ln -sf bd "$HOME/.local/bin/beads" 2>/dev/null || true

    cd - >/dev/null
    rm -r "$build_dir" 2>/dev/null || true

    _ok "bd rebuilt with CGO support and installed"
    return 0
}

# ---------------------------------------------------------------------------
# Main entry point: ensure the bd binary has CGO support.
# ---------------------------------------------------------------------------
ensure_bd_cgo() {
    if ! command -v bd &>/dev/null; then
        _warn "bd not found — skipping CGO check"
        return 1
    fi

    local bd_bin
    bd_bin="$(_find_bd_binary)" || {
        _warn "Could not locate bd binary — skipping CGO check"
        return 1
    }

    if _bd_has_cgo "$bd_bin"; then
        _ok "bd binary has CGO support"
        return 0
    fi

    _warn "bd binary was built WITHOUT CGO — Dolt backend will not work"
    _info "Rebuilding from source..."

    if _rebuild_bd "$bd_bin"; then
        return 0
    else
        _fail "Could not rebuild bd. Install Go and build-essential, then retry."
        return 1
    fi
}
