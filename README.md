# netboot.xyz Nix flake

Nix flake packaging [netboot.xyz](https://netboot.xyz/) boot files from upstream GitHub releases.

A GitHub Action checks daily for new releases and automatically updates versions, hashes, and tags.

## Usage

```nix
# flake.nix
{
  inputs.netbootxyz.url = "github:jgus-org/netbootxyz-flake";

  # Access individual boot files:
  # inputs.netbootxyz.packages.${system}.netboot-xyz-kpxe
  # inputs.netbootxyz.packages.${system}.netboot-xyz-efi
  # inputs.netbootxyz.packages.${system}.netboot-xyz-snponly-efi
  # etc.
}
```

Each package installs a single boot file into `$out/<original-filename>`. Attribute names replace dots with dashes (e.g., `netboot.xyz.kpxe` becomes `netboot-xyz-kpxe`).

## Available packages

All assets from the upstream release are available. Run `nix flake show` to list them.
