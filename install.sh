#!/usr/bin/env bash
#
# gsw installation script
#
#   curl -sSL https://raw.githubusercontent.com/donghyuklee1/gsw/main/install.sh | bash
#   curl -sSL https://raw.githubusercontent.com/donghyuklee1/gsw/main/install.sh | bash -s -- --prefix=$HOME/.local
#
# Copyright (c) 2026 Donghyuk Lee

set -e

REPO="donghyuklee1/gsw"
PREFIX="/usr/local"
REF="main"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

say()  { printf "${BLUE}==>${NC} %s\n" "$*"; }
ok()   { printf "${GREEN}✓${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}!${NC} %s\n" "$*"; }
die()  { printf "${RED}error:${NC} %s\n" "$*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage: install.sh [VERSION] [OPTIONS]

Arguments:
  VERSION            Tag to install (e.g. v1.0.0). Defaults to the main branch.

Options:
  --prefix=PATH      Install to PATH/bin (default: /usr/local)
  -h, --help         Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)  usage; exit 0 ;;
        --prefix=*) PREFIX="${1#--prefix=}" ;;
        --prefix)   shift; [[ -n "${1:-}" ]] || die "--prefix requires a path"; PREFIX="$1" ;;
        v*|[0-9]*)  REF="v${1#v}" ;;
        *)          die "unknown argument: $1" ;;
    esac
    shift
done

BINDIR="$PREFIX/bin"
URL="https://raw.githubusercontent.com/$REPO/$REF/bin/gsw"

say "Installing gsw ($REF) to $BINDIR"

command -v git >/dev/null 2>&1 || die "git is required"
if command -v curl >/dev/null 2>&1; then
    fetch() { curl -fsSL "$1" -o "$2"; }
elif command -v wget >/dev/null 2>&1; then
    fetch() { wget -qO "$2" "$1"; }
else
    die "curl or wget is required"
fi

tmp="$(mktemp "${TMPDIR:-/tmp}/gsw.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

# Prefer a local checkout when run from inside the repository.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [[ "$REF" == "main" && -f "$script_dir/bin/gsw" ]]; then
    cp "$script_dir/bin/gsw" "$tmp"
else
    fetch "$URL" "$tmp" || die "failed to download $URL"
fi
head -n 1 "$tmp" | grep -q bash || die "downloaded file does not look like gsw"
chmod +x "$tmp"

SUDO=""
if [[ ! -d "$BINDIR" ]]; then
    mkdir -p "$BINDIR" 2>/dev/null || SUDO="sudo"
fi
if [[ -z "$SUDO" && ! -w "$BINDIR" ]]; then
    SUDO="sudo"
fi
[[ -n "$SUDO" ]] && warn "$BINDIR is not writable; using sudo"
$SUDO mkdir -p "$BINDIR"
$SUDO install -m 0755 "$tmp" "$BINDIR/gsw"

ok "Installed $("$BINDIR/gsw" --version) to $BINDIR/gsw"

if ! command -v fzf >/dev/null 2>&1; then
    warn "fzf is not installed. gsw needs it for the interactive picker:"
    echo "    macOS:          brew install fzf"
    echo "    Debian/Ubuntu:  sudo apt install fzf"
    echo "    Arch:           sudo pacman -S fzf"
fi

case ":$PATH:" in
    *":$BINDIR:"*) ;;
    *) warn "$BINDIR is not on your PATH. Add it to your shell profile:"
       echo "    export PATH=\"$BINDIR:\$PATH\"" ;;
esac

echo
echo "Run 'gsw' inside any git repository to get started."
