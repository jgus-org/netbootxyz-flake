# netboot.xyz Nix flake

A Nix flake that packages the boot files published by [netboot.xyz](https://netboot.xyz/) as [upstream GitHub releases](https://github.com/netbootxyz/netboot.xyz/releases).

## What it publishes

One package per asset in the pinned upstream release. Each package places that single upstream file in the store at `$out/<upstream filename>` — there is no `$out/bin`, no wrapper and no entry point, so these are paths to serve or copy, not programs to run.

```nix
# flake.nix
{
  inputs.netbootxyz.url = "github:jgus-org/netbootxyz-flake";

  # inputs.netbootxyz.packages.${system}.netboot-xyz-kpxe
  # inputs.netbootxyz.packages.${system}.netboot-xyz-efi
  # inputs.netbootxyz.packages.${system}.netboot-xyz-arm64-efi
}
```

Attribute names are the upstream filenames with `.` replaced by `-`: `netboot.xyz.kpxe` becomes `netboot-xyz-kpxe`, `netboot.xyz-arm64.efi` becomes `netboot-xyz-arm64-efi`. The set follows upstream, so `nix flake show` lists what the pinned release carries. `packages.default` is `netboot-xyz-iso`, the `netboot.xyz.iso` image. The flake also publishes its own maintenance scripts, `update-version` and `update-branches`, as packages; they are not part of the offering.

Which file a given boot path needs — an iPXE chainload (`netboot.xyz.kpxe`, `netboot.xyz.undionly.kpxe`, `netboot.xyz.efi`, `netboot.xyz.snponly.efi`), a mountable image (`.iso`, `.img`), or one of the arm64, `metal` or Secure Boot variants — is covered by upstream's [documentation](https://netboot.xyz/docs/). The flake passes all of them through unchanged.

## Runtime assumptions

Nothing on the build or target host executes these files. A consumer serves `$out/<file>` over TFTP or HTTP for a PXE or UEFI boot path, or writes an `.iso`/`.img` to media. The delivered bytes are upstream's release artifacts and do not depend on the build host; outputs are defined for `x86_64-linux`, `aarch64-linux` and `aarch64-darwin`, and building one needs a builder for that host.

## Licence

This flake is MIT (see `LICENSE`). The boot files are not: the upstream source repository is Apache-2.0, and each released image bundles third-party boot components under their own licences. Check those before redistributing a boot file.
