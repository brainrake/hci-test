{
  description = "Plutus specification language";

  inputs.psl.url = "git+ssh://git@github.com/mlabs-haskell/plutus-specification-language.git";
  inputs.psl.flake = false;
  inputs.idris = {
    url = "github:idris-lang/Idris2";
  };
  inputs.nixpkgs.follows = "idris/nixpkgs";
  inputs.flake-utils.follows = "idris/flake-utils";

  outputs = { self, nixpkgs, idris, flake-utils, ... }@inputs: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      psl = idris.buildIdris.${system} {
        projectName = "psl";
        src = inputs.psl;
        idrisLibraries = [ ];
      };
      idrisLibraries = [ psl.installLibrary ];

      libSuffix = "lib/${idris.packages.${system}.idris2.name}";
      lib-dirs = nixpkgs.lib.strings.concatMapStringsSep ":" (p: "${p}/${libSuffix}") idrisLibraries;
    in
    rec {
      packages = idris.buildIdris.${system} {
        projectName = "bashoswap";
        src = "${self}";
        inherit idrisLibraries;
      };
      defaultPackage = packages.installLibrary;
      devShell = pkgs.mkShell {
        IDRIS2_PACKAGE_PATH = lib-dirs;
        buildInputs = [ idris.packages.${system}.idris2 pkgs.rlwrap ];
        shellHook = ''
          alias idris2="rlwrap -s 1000 idris2 --no-banner"
        '';
      };
    }
  );
}
