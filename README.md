# nix-environment

One agent skill, `nix-environment`, packaged as a Claude Code plugin and usable from opencode. It teaches the agent to set up and work inside Nix flake dev environments for any language, always with the same layout:

- `flake.nix` with `nixpkgs`, [devshell](https://github.com/numtide/devshell), [treefmt-nix](https://github.com/numtide/treefmt-nix) and [git-hooks.nix](https://github.com/cachix/git-hooks.nix)
- `nix/devshell.nix`, `nix/treefmt.nix` and `nix/hooks.nix` modules
- `.envrc` for [nix-direnv](https://github.com/nix-community/nix-direnv)
- `env.md` with setup docs

The toolchain always comes from Nix. Before choosing how a project's own libraries are managed, the agent asks you.

## Claude Code

Install in a terminal:

```sh
claude plugin marketplace add MapleKaedee/nix-environment
claude plugin install nix-environment@kaede-plugins
```

Or in claude.ai: Customize > Plugins > Add > Add marketplace, then enter `MapleKaedee/nix-environment`.

The skill is then available as `/nix-environment:nix-environment`, and Claude also loads it on its own when a task matches.

Update:

```sh
claude plugin marketplace update kaede-plugins
claude plugin update nix-environment@kaede-plugins
```

## opencode

Clone the repo, then add its `skills/` folder to the `skills` array in `~/.config/opencode/opencode.json`:

```sh
git clone https://github.com/MapleKaedee/nix-environment.git ~/Projects/nix-environment
```

```json
{
  "$schema": "https://opencode.ai/config.json",
  "skills": ["~/Projects/nix-environment/skills"]
}
```

The skill ID is `nix-environment`, taken from the folder name. opencode lists it to the model and loads it when a task matches. To load it yourself, mention `@nix-environment` in the prompt. Update with `git pull` in the clone.

Keep only one copy for opencode. A second `nix-environment` folder in `~/.config/opencode/skills`, `~/.claude/skills` or `~/.agents/skills` defines the same ID, and opencode then loads only one of them.

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
