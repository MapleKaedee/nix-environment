---
name: nix-environment
description: Use when a project has flake.nix, nix/devshell.nix, or an .envrc with `use flake`; when the user asks for a Nix or reproducible dev environment, toolchain, or new project setup in any language; when adding a package, SDK, formatter, environment variable, or devshell command; or before installing anything with pip, venv, npm -g, cargo install, rustup, nvm, pyenv, sdkmanager, or flutter upgrade.
---

# Nix dev environment (house pattern)

## Overview

This skill sets up every dev environment, in any language, with one flake pattern: numtide devshell + treefmt-nix + git-hooks.nix, split into `nix/` modules and loaded by nix-direnv. Reproduce this pattern exactly. Generic Nix setups are wrong here even when they work: plain `mkShell` + `shellHook`, flake-utils or multi-system `genAttrs`, a bare `use flake` `.envrc`.

## Recognise it

| File               | Holds                                                                                                                                                                                                                                                                         |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `flake.nix`        | Inputs `nixpkgs` (nixos-unstable), `devshell`, `treefmt-nix`, `git-hooks`, each with `inputs.nixpkgs.follows`. One `system`, the machine's own (`x86_64-linux` in the template). `let` builds toolchains, `treefmt` and `hooks`. Outputs: `devShells`, `formatter`, `checks`. |
| `nix/devshell.nix` | `devshell.name`, `packages`, `startup.git-hooks`, `env`, `commands` (always `fmt` and `check`, usually `doctor`, then project commands)                                                                                                                                       |
| `nix/treefmt.nix`  | nixfmt, prettier, shfmt, language formatter, excludes                                                                                                                                                                                                                         |
| `nix/hooks.nix`    | `treefmt`, `check-merge-conflicts`                                                                                                                                                                                                                                            |
| `.envrc`           | nix-direnv >= 3.2.0 guard, `watch_file nix/*.nix`, `use flake`                                                                                                                                                                                                                |
| `env.md`           | Setup docs in the user's language; `README.md` links to it                                                                                                                                                                                                                    |

## Project dependencies: an open question

The toolchain always comes from Nix. How the project's own libraries are managed differs per project, and per stack inside one project (for example, Python libraries in `flake.nix` next to a `web/` frontend managed by pnpm). If neither `env.md` nor `CLAUDE.md` records it for the stack you are touching, ask the user before editing anything, and wait for the answer. The two options are listed in `languages.md` ("Project dependencies: ask first"). Record the answer in `env.md`.

## Scaffolding a new project

1. If the folder is not a Git repo, ask the user to run `git init -b main`.
2. Settle the dependency question above.
3. Copy this skill's `templates/` folder into the project: `cp -r <skill base directory>/templates/. .` (the base directory is shown when the skill loads). Replace `PROJECT` in `flake.nix` and `nix/devshell.nix`. If the machine is not `x86_64-linux`, set `system` to the output of `nix eval --raw --impure --expr builtins.currentSystem`.
4. Add the language with the five slots in `languages.md`.
5. Add this block to `.gitignore` (create the file if missing), plus the language's build and cache folders:
   ```gitignore
   # Nix and local environment
   /.direnv/
   /result
   /result-*
   /.pre-commit-config.yaml
   /.env.local
   /.envrc.local
   ```
6. Write `env.md` in the user's language, with headings translated, in this order: Prerequisites, Getting started, Automatic activation with direnv, Daily commands (a table of commands), Formatter and hooks, Updating dependencies, References (links to devshell, nix-direnv, treefmt-nix, git-hooks.nix). "Getting started" lists every first-run step in order, including dependency installs such as `npm ci` or `flutter pub get`. Link `env.md` from `README.md`, and create a short `README.md` if there is none. An existing project without `env.md` gets one the same way.
7. Run `git add -A`, `nix develop -c fmt`, then `nix develop -c check`.

## Working inside an existing setup

Run tools with `nix develop -c <cmd>`, or directly when direnv is active. For an interactive shell other than bash, tell the user `nix develop --command <shell>` (for example `fish` or `zsh`).

| Change                                                       | Where                                                   |
| ------------------------------------------------------------ | ------------------------------------------------------- |
| Plain nixpkgs package or CLI tool                            | `nix/devshell.nix` `packages`, as `pkgs.<name>`         |
| Wrapped or custom toolchain, or a package missing in nixpkgs | `flake.nix` `let`, passed through `_module.args`        |
| Environment variable                                         | `nix/devshell.nix` `env`                                |
| Command                                                      | `nix/devshell.nix` `commands` (shape in `languages.md`) |
| Formatter or linter                                          | `nix/treefmt.nix` `programs`                            |
| Build output, cache, generated code                          | `nix/treefmt.nix` `global.excludes` and `.gitignore`    |
| Language lockfile (`package-lock.json`, `Cargo.lock`, ...)   | `nix/treefmt.nix` `global.excludes` only; commit it     |
| Git hook                                                     | `nix/hooks.nix`                                         |

After a toolchain change, update `doctor` and the Daily commands table in `env.md`.

Rules for every change:

- Stage new files with `git add` before any Nix command, because the flake sees only files Git knows about.
- Name commands like `run-tests`, never `test`. Bind servers to `127.0.0.1`.
- A command that wraps one tool uses `set -euo pipefail`, `cd "$PRJ_ROOT"` and `exec ... "$@"`. A multi-step command such as `doctor` uses `set -euo pipefail` only.
- Commands run tools. They do not install dependencies; installs belong in the "Getting started" steps of `env.md`.
- For a stack in a subfolder such as `web/`, use `cd "$PRJ_ROOT/web"`, and prefix its excludes and `.gitignore` entries with `web/`.
- `nix flake check` covers only sandbox checks (formatting and hooks). Run tests and builds that need network in the devshell.
- Run `nix flake update` only when the user asks, because built artefacts may be tied to locked versions.

## Troubleshooting

| Symptom                                               | Fix                                                                                                                                                           |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `path '...' does not exist`, or a new file is ignored | `git add <file>`                                                                                                                                              |
| Whole folder copied to the store, hooks not installed | Not a Git repo. Ask the user to run `git init -b main`.                                                                                                       |
| `nix-direnv >= 3.2.0 is required`                     | `nix profile add nixpkgs#nix-direnv`, then source its `direnvrc` in `~/.config/direnv/direnvrc`                                                               |
| direnv refuses to load after `.envrc` changed         | `direnv allow`                                                                                                                                                |
| `test` command does nothing                           | A shell builtin shadows it. Rename it to `run-tests`.                                                                                                         |
| `ruff`, `rustfmt` (any formatter): command not found  | treefmt programs are not on PATH. Use `fmt`, or also add the package to `packages` when a CLI or editor calls it directly (`cargo fmt` needs `pkgs.rustfmt`). |
| `cc: not found` or linker errors                      | The devshell has no stdenv compiler. Add `pkgs.gcc` (or `pkgs.clang`) to `packages`.                                                                          |
| Write fails inside an SDK path in `/nix/store`        | The store is read-only. Change versions in `flake.nix`.                                                                                                       |
| `nix flake check` fails on formatting                 | Run `fmt`, stage the changes, then run `check` again.                                                                                                         |
