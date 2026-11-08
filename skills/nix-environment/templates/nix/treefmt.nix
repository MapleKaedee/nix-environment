{ ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt.enable = true;
    prettier = {
      enable = true;
      includes = [
        "*.md"
        "*.yaml"
        "*.yml"
        "*.json"
      ];
    };
    shfmt.enable = true;
  };
  settings = {
    global.excludes = [
      ".direnv/**"
      ".git/**"
      ".pre-commit-config.yaml"
      "flake.lock"
    ];
    formatter.shfmt.includes = [
      "*.sh"
      ".envrc"
    ];
  };
}
