{
  inputs.haskell-nix.url = "github:input-output-hk/haskell.nix";
  inputs.nixpkgs.follows = "haskell-nix/nixpkgs-unstable";
  outputs = { nixpkgs, haskell-nix, ... }: let
    overlay = final: prev: {
      myproject = final.haskell-nix.project' {
        src = ./.;
        # compiler-nix-name = "ghc922";
        compiler-nix-name = "ghc8107";
        shell.tools = {
          haskell-language-server = {};
        };
      };
    };
    overlays =  [ haskell-nix.overlay overlay ];
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system overlays; inherit (haskell-nix) config; };
    flake = pkgs.myproject.flake {};
  in {
    packages.${system}.default = flake.packages."myproject:exe:myexe";
  };
}
