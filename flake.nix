{
  description = "netboot.xyz boot files (netbootxyz/netboot.xyz).";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-lib = {
      url = "github:jgus-org/flake-lib/v1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
      flake-lib,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pin = import ./pin.nix;
        inherit (pin) version assets;
        pkgs = import nixpkgs { inherit system; };
        treefmtEval = treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
          programs.shfmt.enable = true;
        };
        source = {
          type = "github";
          owner = "netbootxyz";
          repo = "netboot.xyz";
        };

        sanitizeName = name: builtins.replaceStrings [ "." ] [ "-" ] name;

        mkBootFile =
          name: hash:
          pkgs.runCommand (sanitizeName name) { } ''
            mkdir -p $out
            cp ${
              builtins.fetchurl {
                url = "https://github.com/netbootxyz/netboot.xyz/releases/download/${version}/${name}";
                sha256 = hash;
              }
            } $out/${name}
          '';

        bootFiles = builtins.listToAttrs (
          builtins.map (name: {
            name = sanitizeName name;
            value = mkBootFile name assets.${name};
          }) (builtins.attrNames assets)
        );
      in
      {
        formatter = treefmtEval.config.build.wrapper;

        checks.formatting = treefmtEval.config.build.check self;

        packages = bootFiles // {
          default = bootFiles."netboot-xyz-iso";
          # Bespoke build (per-asset fetchurl) + bespoke update-version (enumerates the release's
          # checksum file into a keyed hash table); only the per-version-branch orchestrator is shared.
          update-version = pkgs.writeShellApplication {
            name = "update-version";
            text = ''exec ${./update-version.sh} "$@"'';
          };
          update-branches = flake-lib.lib.mkUpdateBranches {
            minimumTrackingVersion = "3.0.2";
            inherit pkgs source;
            pinSchema = "version-only";
          };
        };
      }
    );
}
