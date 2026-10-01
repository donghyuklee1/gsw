# Contributing to gsw

Thanks for your interest in improving gsw!

## Ground rules

- **No new runtime dependencies.** gsw needs only `bash`, `git`, and `fzf`. Standard POSIX tools like `awk` and `date` are fine.
- **Bash 3.2 compatible.** macOS still ships Bash 3.2, so don't use `mapfile`, associative arrays, `${var,,}`, and similar features.
- **Startup speed matters.** The picker should open instantly, even in repos with thousands of branches.

## Workflow

1. Fork and create a branch: `git switch -c feat/my-change` (or use `gsw` 😉)
2. Make your change in `bin/gsw`
3. Add or update tests in `tests/test_gsw.sh`
4. Run `make ci-test`, which runs ShellCheck and the test suite
5. Add an entry under `## [Unreleased]` in `CHANGELOG.md`
6. Open a pull request

## Testing the interactive UI

Most logic is reachable without a TTY and is covered by `tests/test_gsw.sh`. For UI changes, also check the picker by hand in a real terminal. Try:

- a repo with many branches, and one with a single branch
- `Ctrl-R` toggling, `Ctrl-D` on merged, unmerged, and remote branches
- a narrow terminal (fewer than 80 columns)
- `NO_COLOR=1`
