{
  description = "Poetry + Nix flake with Python 3.11";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    poetry2nix.url = "github:nix-community/poetry2nix";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, poetry2nix, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        python = pkgs.python311;

        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; })
          mkPoetryEnv;

        myPythonEnv = mkPoetryEnv {
          projectDir = ./.;
          python = python;
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [ myPythonEnv pkgs.poetry ];
          shellHook = ''echo "🐍 Python dev shell loaded." '';
        };

        packages.default = myPythonEnv;
      }
    );
}
