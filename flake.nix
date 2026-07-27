{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = { nixpkgs, treefmt-nix, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system:
          f (import nixpkgs { inherit system; })
        );
    in
    {
      formatter = forAllSystems (pkgs:
        ((treefmt-nix.lib.evalModule pkgs) {
          programs.nixpkgs-fmt.enable = true;
        }).config.build.wrapper
      );

      nixosModules.default = import ./dashnix.nix;
    };
}
