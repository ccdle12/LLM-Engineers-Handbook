# file: flake.nix
{
  description = "Python application packaged using poetry2nix";

  # inputs.nixpkgs.url = "github:NixOS/nixpkgs/3b5d20eaa1838cc82a7809c188e4e53920e520ec"; # April 2024 known good
  # inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  # inputs.flake-utils.url = "github:numtide/flake-utils";
  # inputs.poetry2nix.url = "github:nix-community/poetry2nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    # Last working commit from nixos-small-unstable
    nixpkgs.url = "github:NixOS/nixpkgs?rev=75e28c029ef2605f9841e0baa335d70065fe7ae2";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };


  # outputs = { self, nixpkgs, poetry2nix }:
  outputs = { self, nixpkgs, poetry2nix, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      python = pkgs.python311;
      poetry2nixLib = poetry2nix.lib.mkPoetry2Nix {
        inherit pkgs;
        fetchPypiLegacy = pkgs.fetchPypi;
      };

      overrides = self: super: {
          pyarrow = super.buildPythonPackage rec {
            pname = "pyarrow";
            version = "17.0.0";
            pyproject= true;

            src = pkgs.fetchPypi {
              inherit pname version;
              sha256 = "sha256-EY2r3x3PvMIb7AyAOkGgDFAEHo/AB3UlS1ThP8YIfUQ="; # update this if needed
            };

            build-system = [ super.setuptools ];

            nativeBuildInputs = [ pkgs.cmake pkgs.pkg-config ];
            buildInputs = [
              pkgs.arrow-cpp
              pkgs.boost
              pkgs.snappy
              pkgs.zlib
            ];

            propagatedBuildInputs = [ ];
            doCheck = false;
            pythonImportsCheck = [ "pyarrow" ];
          };
        };


      # create a custom "mkPoetryApplication" API function that under the hood uses
      # the packages and versions (python3, poetry etc.) from our pinned nixpkgs above:
      inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication;
      myPythonApp = {poetry2nix, lib }: poetry2nix.mkPoetryApplication {
        projectDir = self;
        overrides = poetry2nix.overrides.withDefaults (final: super:
            lib.mapAttrs
              (attr: systems: super.${attr}.overridePythonAttrs
                (old: {
                  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ map (a: final.${a}) systems;
                }))
              {
                # https://github.com/nix-community/poetry2nix/blob/master/docs/edgecases.md#modulenotfounderror-no-module-named-packagename
                # package = [ "setuptools" ];
              }
          );
      };
    in
    {
       devShells.default = pkgs.mkShell {
          buildInputs = [ myPythonApp pkgs.poetry ];
          shellHook = ''echo "🐍 Python + Poetry dev shell ready."'';
      };

      # apps.${system}.default = {
        # type = "app";
        # replace <script> with the name in the [tool.poetry.scripts] section of your pyproject.toml
        # program = "${myPythonApp}/bin/<script>";
      # };

    });
}
