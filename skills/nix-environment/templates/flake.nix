{
  description = "PROJECT development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      devshell,
      treefmt-nix,
      git-hooks,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      treefmt = treefmt-nix.lib.evalModule pkgs ./nix/treefmt.nix;
      hooks = git-hooks.lib.${system}.run {
        src = self;
        imports = [ ./nix/hooks.nix ];
        hooks.treefmt.package = treefmt.config.build.wrapper;
      };
    in
    {
      devShells.${system}.default = devshell.legacyPackages.${system}.mkShell {
        imports = [ ./nix/devshell.nix ];
        _module.args = {
          inherit treefmt hooks;
        };
      };
      formatter.${system} = treefmt.config.build.wrapper;
      checks.${system} = {
        formatting = treefmt.config.build.check self;
        pre-commit = hooks;
      };
    };
}
