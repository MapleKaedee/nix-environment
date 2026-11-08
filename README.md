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

No clone needed. `skills/index.json` makes this repo an opencode HTTP skill catalog. Add its URL to the `skills` array in `~/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "skills": [
    "https://raw.githubusercontent.com/MapleKaedee/nix-environment/main/skills/"
  ]
}
```

opencode downloads the files listed in `skills/index.json` into its cache. The skill ID is `nix-environment`. opencode lists it to the model and loads it when a task matches. To load it yourself, mention `@nix-environment` in the prompt.

opencode downloads the files again only when `version` in `skills/index.json` changes.

Keep only one copy for opencode. A second `nix-environment` folder in `~/.config/opencode/skills`, `~/.claude/skills` or `~/.agents/skills` defines the same ID, and opencode then loads only one of them.

## Contents

```
.claude-plugin/
  plugin.json
  marketplace.json
skills/index.json   # opencode catalog: skill files and version
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

After changing anything in `skills/nix-environment/`, raise `version` in `skills/index.json`, so opencode downloads the new files. Keep its `files` list equal to the tracked files. This prints nothing when they match:

```sh
diff <(cd skills/nix-environment && git ls-files | sort) <(jq -r '.skills[0].files[]' skills/index.json | sort)
```
