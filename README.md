# gsw — Git Smart Switch

[![CI](https://github.com/donghyuklee1/gsw/actions/workflows/ci.yml/badge.svg)](https://github.com/donghyuklee1/gsw/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue)](https://github.com/donghyuklee1/gsw)
[![Shell](https://img.shields.io/badge/shell-bash%203.2%2B-green)](bin/gsw)

Switch Git branches in under a second. Stop typing `feature/issue-302-auth-fix`
or copying names out of `git branch`. Run `gsw`, type a few characters, press Enter.

`gsw` is a single Bash script wrapped around [`fzf`](https://github.com/junegunn/fzf).
There is no runtime, daemon, or config file to install.

```
╭──────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ branch ❯ 302                                       │ feature/issue-302-auth-fix  ↑1 ↓0 vs main       │
│   1/4 ──────────────────────────────────────────── │ donghyuklee1 · 2 minutes ago                    │
│   enter switch · ctrl-r remotes · ctrl-d delete    │                                                 │
│   ● local  (ctrl-r: include remotes)               │ * 0cb6a2b (feature/issue-302-auth-fix) fix auth │
│ ▶ 2m ago   feature/issue-302-auth-fix   fix auth…  │ * 060cacd (HEAD -> main, origin/main) init      │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────╯
```

## Features

- **Sorted by recency.** The branch you touched most recently is at the top, and the branch you're on is hidden.
- **Instant fuzzy search** on branch names and commit subjects. Typing `302` finds `feature/issue-302-auth-fix`.
- **Two-pane view.** The left pane shows relative age (`2m ago`), branch name, and last commit subject. The right pane shows a live `git log --graph` of the highlighted branch, with ahead/behind counts against `HEAD`.
- **One-key actions.** Switch, show remote branches, or delete a branch without leaving the picker.
- **Direct jump.** `gsw 302` switches right away when only one branch matches, and skips the UI.
- **Remote-aware.** Picking `origin/foo` creates a local tracking branch, or switches to `foo` if it already exists.
- **Safe by default.** Deleting asks for confirmation and uses `git branch -d`. If the branch isn't fully merged, gsw asks a second time before using `-D`.
- **Portable.** Works with Bash 3.2+ (the stock macOS `/bin/bash`), Linux, and any git version. It uses `git switch` when available and falls back to `git checkout`.

## Installation

### Install script

```bash
# Latest (installs to /usr/local/bin, uses sudo only if needed)
curl -sSL https://raw.githubusercontent.com/donghyuklee1/gsw/main/install.sh | bash

# No sudo: install to ~/.local/bin
curl -sSL https://raw.githubusercontent.com/donghyuklee1/gsw/main/install.sh | bash -s -- --prefix=$HOME/.local

# Specific release
curl -sSL https://raw.githubusercontent.com/donghyuklee1/gsw/main/install.sh | bash -s v1.0.0
```

### Manual

```bash
curl -L https://raw.githubusercontent.com/donghyuklee1/gsw/main/bin/gsw -o gsw
chmod +x gsw
sudo mv gsw /usr/local/bin/
```

### From source

```bash
git clone https://github.com/donghyuklee1/gsw.git
cd gsw
make install            # or: make install PREFIX=$HOME/.local
```

### As a git alias (optional)

```bash
git config --global alias.sw '!gsw'   # now `git sw` works too
```

## Requirements

- `git`
- `fzf` 0.27+ (`brew install fzf`, `apt install fzf`, `pacman -S fzf`)
- Bash 3.2+

## Usage

```bash
gsw              # open the picker (local branches)
gsw -r           # open the picker with local + remote branches
gsw 302          # switch directly if one branch matches "302", else open the picker pre-filtered
gsw -            # switch back to the previous branch
gsw --list       # print the recency-sorted list and exit (good for scripts)
```

### Keys

| Key              | Action                                                        |
| ---------------- | ------------------------------------------------------------- |
| `Enter`          | Switch to the highlighted branch                              |
| `Ctrl-R`         | Toggle **local only** and **local + remote**                  |
| `Ctrl-D`         | Delete the highlighted local branch, after a `[y/N]` prompt   |
| `Esc` / `Ctrl-C` | Quit without changing anything                                |
| `↑` / `↓`        | Move the selection (standard fzf keys also work)              |

### Messages

```text
$ cd /tmp && gsw
error: Not a git repository (or any of the parent directories)

$ gsw     # in a repo with a single branch
Already on the only available branch: main
```

If you have no other local branches but the remote does, gsw opens in local + remote mode.

## Configuration

Everything works without configuration. These environment variables are optional:

| Variable            | Default | Description                                   |
| ------------------- | ------- | --------------------------------------------- |
| `GSW_PREVIEW_COUNT` | `10`    | Number of commits in the preview pane         |
| `GSW_HEIGHT`        | `80%`   | Picker height (`100%` for fullscreen)         |
| `GSW_FZF_OPTS`      |         | Extra flags passed to fzf (e.g. `--no-border`) |
| `NO_COLOR`          |         | Disable colored output                        |

## How it works

```bash
git for-each-ref --sort=-committerdate refs/heads [refs/remotes] \
    --format='%(refname)%09%(committerdate:unix)%09%(refname:short)%09%(symref)%09%(subject)'
```

The rows are tab-delimited and passed to `fzf`. The full refname is kept as a hidden first column, so preview, switch, and delete always act on an exact ref. Relative ages are computed in `awk` so they stay short (`2m ago` rather than `2 minutes ago`). `Ctrl-R` and `Ctrl-D` are fzf `reload` and `execute` bindings that call back into the same script.

## Development

```bash
make test        # run the test suite (needs git + fzf)
make lint        # ShellCheck
make ci-test     # both
```

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © 2026 Donghyuk Lee
