# Security Policy

## Supported versions

Only the latest release receives security fixes.

## Reporting a vulnerability

Please **do not** open a public issue. Report vulnerabilities privately through
[GitHub Security Advisories](https://github.com/donghyuklee1/gsw/security/advisories/new).
You should receive a response within 7 days.

## Scope notes

gsw runs only local `git` commands in the current repository. It makes no
network calls of its own. Branch names are always passed to git as quoted
arguments and are never evaluated by a shell.
