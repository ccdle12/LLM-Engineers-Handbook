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

        overrides = self: super: {
          pyarrow = super.pyarrow.overridePythonAttrs (old: {
          buildInputs = (old.buildInputs or []) ++ [ pkgs.arrow-cpp_17 ]; # Force arrow-cpp version
          });
        };

        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; })
          mkPoetryEnv;

        poetryEnv = poetry2nix.lib.mkPoetry2Nix {
          inherit pkgs;
        };

        myPythonEnv = mkPoetryEnv {
          projectDir = ./.;
          python = python;
          overrides = poetryEnv.defaultPoetryOverrides.extend overrides;
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
