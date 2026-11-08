{
  pkgs,
  treefmt,
  hooks,
  ...
}:
{
  devshell = {
    name = "PROJECT";
    packages = [
      pkgs.git
      pkgs.direnv
      pkgs.nix-direnv
      treefmt.config.build.wrapper
    ]
    ++ hooks.enabledPackages;
    startup.git-hooks.text = ''
      if ${pkgs.git}/bin/git rev-parse --git-dir >/dev/null 2>&1; then
        ${hooks.shellHook}
      fi
    '';
  };

  commands = [
    {
      name = "fmt";
      category = "Quality";
      help = "Format source files with treefmt";
      command = ''exec ${treefmt.config.build.wrapper}/bin/treefmt "$@"'';
    }
    {
      name = "check";
      category = "Quality";
      help = "Run sandboxed Nix and formatting checks";
      command = ''
        set -euo pipefail
        cd "$PRJ_ROOT"
        exec nix flake check "$@"
      '';
    }
  ];
}
