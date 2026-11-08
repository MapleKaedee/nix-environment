# nix-environment

A Claude Code plugin with one skill, `nix-environment`. It teaches Claude to set up and work inside Nix flake dev environments for any language, always with the same layout:

- `flake.nix` with `nixpkgs`, [devshell](https://github.com/numtide/devshell), [treefmt-nix](https://github.com/numtide/treefmt-nix) and [git-hooks.nix](https://github.com/cachix/git-hooks.nix)
- `nix/devshell.nix`, `nix/treefmt.nix` and `nix/hooks.nix` modules
- `.envrc` for [nix-direnv](https://github.com/nix-community/nix-direnv)
- `env.md` with setup docs

The toolchain always comes from Nix. Before choosing how a project's own libraries are managed, Claude asks you.

## Install

In a terminal:

```sh
claude plugin marketplace add MapleKaedee/nix-environment
claude plugin install nix-environment@kaede-plugins
```

Or in claude.ai: Customize > Plugins > Add > Add marketplace, then enter `MapleKaedee/nix-environment`.

The skill is then available as `/nix-environment:nix-environment`, and Claude also loads it on its own when a task matches.

## Update

```sh
claude plugin marketplace update kaede-plugins
claude plugin update nix-environment@kaede-plugins
```

## Contents

```
.claude-plugin/
  plugin.json
  marketplace.json
skills/nix-environment/
  SKILL.md        # the pattern, rules and troubleshooting
  languages.md    # how to add any language, with a table of common stacks
  templates/      # language-neutral flake.nix, nix/*.nix and .envrc
```

## Develop

```sh
claude plugin validate .
claude --plugin-dir .
```
