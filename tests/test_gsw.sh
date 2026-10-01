#!/usr/bin/env bash
#
# gsw test suite. Builds throwaway repositories and exercises every
# non-interactive code path. Requires git; fzf-dependent tests are skipped
# when fzf is not installed.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GSW="$ROOT/bin/gsw"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gsw-test.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

export NO_COLOR=1
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME="gsw test" GIT_AUTHOR_EMAIL="test@example.com"
export GIT_COMMITTER_NAME="gsw test" GIT_COMMITTER_EMAIL="test@example.com"

PASS=0 FAIL=0 SKIP=0

pass() { PASS=$((PASS + 1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  \033[31m✗\033[0m %s\n' "$1"; [[ -n "${2:-}" ]] && printf '      %s\n' "$2"; }
skip() { SKIP=$((SKIP + 1)); printf '  \033[33m-\033[0m %s (skipped)\n' "$1"; }

assert_eq() {
    if [[ "$2" == "$3" ]]; then pass "$1"; else fail "$1" "expected [$3], got [$2]"; fi
}
assert_contains() {
    if [[ "$2" == *"$3"* ]]; then pass "$1"; else fail "$1" "expected output to contain [$3], got [$2]"; fi
}
assert_not_contains() {
    if [[ "$2" != *"$3"* ]]; then pass "$1"; else fail "$1" "did not expect [$3] in [$2]"; fi
}

# Commit with a fixed committer date offset (in seconds) from now.
commit_at() {
    local ago="$1" msg="$2" ts
    ts=$(( $(date +%s) - ago ))
    GIT_COMMITTER_DATE="@$ts +0000" GIT_AUTHOR_DATE="@$ts +0000" \
        git commit -q --allow-empty -m "$msg"
}

has_fzf() { command -v fzf >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
echo "CLI basics"

out="$("$GSW" --version)"
assert_contains "--version prints version" "$out" "gsw "

out="$("$GSW" --help)"
assert_contains "--help shows usage" "$out" "Usage:"

"$GSW" --definitely-not-an-option >/dev/null 2>&1
assert_eq "unknown option exits 2" "$?" "2"

# ---------------------------------------------------------------------------
echo "Safety net"

mkdir -p "$WORK/not-a-repo"
out="$(cd "$WORK/not-a-repo" && GIT_CEILING_DIRECTORIES="$WORK" "$GSW" 2>&1)"
status=$?
assert_eq "non-git dir prints friendly error" "$out" \
    "error: Not a git repository (or any of the parent directories)"
assert_eq "non-git dir exits 128" "$status" "128"

git init -q -b main "$WORK/single"
(cd "$WORK/single" && commit_at 60 "init")
out="$(cd "$WORK/single" && "$GSW" 2>&1)"
assert_eq "single branch message" "$out" "Already on the only available branch: main"

# ---------------------------------------------------------------------------
echo "Branch listing"

ORIGIN="$WORK/origin"
git init -q -b main "$ORIGIN"
(
    cd "$ORIGIN" || exit 1
    commit_at 86400 "init"
    git switch -q -c feature/issue-302-auth-fix; commit_at 120 "fix auth token refresh"
    git switch -q -c bugfix/login-crash main;   commit_at 10800 "handle nil session"
    git switch -q -c chore/deps main;           commit_at 1728000 "bump deps"
    git switch -q main
)
CLONE="$WORK/clone"
git clone -q "$ORIGIN" "$CLONE"
(
    cd "$CLONE" || exit 1
    git branch -q local-old origin/chore/deps --no-track
    git branch -q feature/issue-302-auth-fix origin/feature/issue-302-auth-fix
)

out="$(cd "$CLONE" && "$GSW" --list)"
assert_eq "local list sorted by recency" "$(printf '%s\n' "$out" | awk -F '\t' '{gsub(/ +$/, "", $2); print $2}' | tr '\n' ' ')" \
    "feature/issue-302-auth-fix local-old "
assert_not_contains "current branch excluded" "$out" "main"
assert_contains "relative age shown" "$out" "2m ago"
assert_contains "commit subject shown" "$out" "fix auth token refresh"

out="$(cd "$CLONE" && "$GSW" --remote --list)"
assert_contains "remote list includes remotes" "$out" "origin/bugfix/login-crash"
assert_not_contains "origin/HEAD excluded" "$out" "origin/HEAD"
assert_not_contains "upstream of current excluded" "$out" "origin/main"
first="$(printf '%s\n' "$out" | head -n 1)"
assert_contains "most recent first in remote list" "$first" "issue-302"

# ---------------------------------------------------------------------------
echo "Switching"

if has_fzf; then
    out="$(cd "$CLONE" && "$GSW" 302 2>&1)"
    assert_eq "unique query switches immediately" "$(git -C "$CLONE" branch --show-current)" \
        "feature/issue-302-auth-fix"

    out="$(cd "$CLONE" && "$GSW" - 2>&1)"
    assert_eq "'gsw -' returns to previous branch" "$(git -C "$CLONE" branch --show-current)" "main"

    out="$(cd "$CLONE" && "$GSW" login 2>&1)"
    assert_eq "remote-only match creates tracking branch" "$(git -C "$CLONE" branch --show-current)" \
        "bugfix/login-crash"
    assert_eq "tracking upstream configured" \
        "$(git -C "$CLONE" rev-parse --abbrev-ref '@{upstream}')" "origin/bugfix/login-crash"

    git -C "$CLONE" switch -q main
    out="$(cd "$CLONE" && "$GSW" zzz-no-such-branch 2>&1)"
    status=$?
    assert_contains "no match reports error" "$out" "no branch matches"
    assert_eq "no match exits 1" "$status" "1"

    out="$(cd "$CLONE" && "$GSW" -r chore 2>&1)"
    assert_eq "-r query reaches remote-only branches" \
        "$(git -C "$CLONE" branch --show-current)" "chore/deps"
    git -C "$CLONE" switch -q main
else
    skip "query switching (fzf not installed)"
fi

# ---------------------------------------------------------------------------
echo "Picker internals"

state="$WORK/state"
printf 'local' >"$state"
out="$(cd "$CLONE" && "$GSW" --_feed "$state" toggle)"
assert_eq "ctrl-r toggle flips state to all" "$(cat "$state")" "all"
assert_contains "toggled feed includes remotes" "$out" "refs/remotes/origin/"
out="$(cd "$CLONE" && "$GSW" --_feed "$state" toggle)"
assert_eq "ctrl-r toggle flips back to local" "$(cat "$state")" "local"
assert_not_contains "local feed hides remotes" "$out" "refs/remotes/"

out="$(cd "$CLONE" && "$GSW" --_preview refs/heads/feature/issue-302-auth-fix)"
assert_contains "preview shows log" "$out" "fix auth token refresh"
assert_contains "preview shows ahead/behind" "$out" "↑1"

# ---------------------------------------------------------------------------
echo
total=$((PASS + FAIL))
printf 'Passed %d/%d' "$PASS" "$total"
[[ $SKIP -gt 0 ]] && printf ' (%d skipped)' "$SKIP"
echo
[[ $FAIL -eq 0 ]]
