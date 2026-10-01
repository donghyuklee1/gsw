#!/usr/bin/env bash
#
# gsw uninstallation script
#
# Copyright (c) 2026 Donghyuk Lee

set -e

PREFIX="/usr/local"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)  echo "Usage: uninstall.sh [--prefix=PATH]"; exit 0 ;;
        --prefix=*) PREFIX="${1#--prefix=}" ;;
        --prefix)   shift; PREFIX="${1:?--prefix requires a path}" ;;
        *)          echo "error: unknown argument: $1" >&2; exit 1 ;;
    esac
    shift
done

TARGET="$PREFIX/bin/gsw"

if [[ ! -e "$TARGET" ]]; then
    found="$(command -v gsw 2>/dev/null || true)"
    if [[ -n "$found" ]]; then
        echo "gsw not found at $TARGET, but found at $found"
        echo "Re-run with: uninstall.sh --prefix=$(dirname "$(dirname "$found")")"
    else
        echo "gsw is not installed."
    fi
    exit 0
fi

if [[ -w "$(dirname "$TARGET")" ]]; then
    rm -f "$TARGET"
else
    sudo rm -f "$TARGET"
fi

echo "✓ Removed $TARGET"
