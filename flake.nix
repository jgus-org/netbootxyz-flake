{
  description = "netboot.xyz boot files (netbootxyz/netboot.xyz).";

  inputs = {
    flake-lib.url = "github:jgus-org/flake-lib/v1";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      self,
      flake-lib,
      nixpkgs,
    }:
    flake-lib.lib.eachDefaultSystem (
      system:
      let
        pin = import ./pin.nix;
        inherit (pin) assets version;
        pkgs = import nixpkgs { inherit system; };
        orgFormatting = flake-lib.lib.mkFormatting {
          inherit self system;
        };
        source = {
          owner = "netbootxyz";
          repo = "netboot.xyz";
          type = "github";
        };

        sanitizeName = name: builtins.replaceStrings [ "." ] [ "-" ] name;

        mkBootFile =
          name: hash:
          pkgs.runCommand (sanitizeName name) { } ''
            mkdir -p $out
            cp ${
              builtins.fetchurl {
                sha256 = hash;
                url = "https://github.com/netbootxyz/netboot.xyz/releases/download/${version}/${name}";
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
        checks.formatting = orgFormatting.check;
        formatter = orgFormatting.formatter;
        packages = bootFiles // {
          default = bootFiles."netboot-xyz-iso";
          update-branches = flake-lib.lib.mkUpdateBranches {
            inherit pkgs source;
            minimumTrackingVersion = "3.0.2";
            pinSchema = "version-only";
          };
          # Bespoke build (per-asset fetchurl) + bespoke update-version (enumerates the release's
          # checksum file into a keyed hash table); only the per-version-branch orchestrator is shared.
          update-version = pkgs.writeShellApplication {
            name = "update-version";
            text = ''exec ${./update-version.sh} "$@"'';
          };
        };
      }
    );
}
