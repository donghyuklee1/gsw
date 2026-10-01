# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-10-02

### Added

- Interactive fzf picker sorted by last commit time, with the current branch hidden.
- Left pane with relative age, branch name, and last commit subject.
- Right pane preview showing `git log --graph` and ahead/behind counts against `HEAD`.
- `Enter` to switch (uses `git switch`, falls back to `git checkout`).
- `Ctrl-R` to toggle local only and local + remote branches.
- `Ctrl-D` to delete a branch with confirmation, plus a second confirmation before `-D`.
- `gsw <query>` switches directly when exactly one branch matches.
- `gsw -` switches to the previous branch.
- `gsw --list` prints the list without opening the UI.
- Friendly errors for non-git directories and repositories with a single branch.
- Install and uninstall scripts, Makefile, test suite, and CI.
