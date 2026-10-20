#!/usr/bin/env -S nix shell nixpkgs#bash nixpkgs#curl nixpkgs#gh nixpkgs#jq nixpkgs#nix nixpkgs#coreutils --command bash

# Pins pin.nix to a specific (or latest) netboot.xyz release and rewrites the assets table from upstream's sha256 checksum file. Run from the flake root:
#
#   nix run .#update-version              # latest GitHub release
#   nix run .#update-version -- 3.0.2     # specific version (no v prefix)
#
# Always re-downloads the checksum file and rewrites pin.nix if anything changed.

set -euo pipefail

FLAKE_ROOT="${FLAKE_ROOT:-${PWD}}"
pin="${FLAKE_ROOT}/pin.nix"
repo_owner=netbootxyz
repo_name=netboot.xyz

if [[ ! -f ${pin} ]]; then
  echo "error: no pin.nix in ${FLAKE_ROOT}" >&2
  exit 1
fi

if [[ $# -ge 1 && -n ${1} ]]; then
  new_version="${1#[Vv]}"
  echo "Using requested version: ${new_version}"
else
  echo "Querying GitHub for latest release of ${repo_owner}/${repo_name}..."
  new_version=$(gh api "/repos/${repo_owner}/${repo_name}/releases/latest" --jq '.tag_name')
  new_version="${new_version#[Vv]}"
fi

cur_version=$(nix eval --raw --file "${pin}" version 2>/dev/null || echo "")
echo "  current: ${cur_version}"
echo "  target:  ${new_version}"

checksums_url="https://github.com/${repo_owner}/${repo_name}/releases/download/${new_version}/netboot.xyz-sha256-checksums.txt"
echo "Downloading ${checksums_url}..."
tmp=$(mktemp)
trap 'rm -f "${tmp}"' EXIT
curl -sSfL "${checksums_url}" >"${tmp}"

echo "Writing pin.nix..."
{
  echo '# Auto-managed by `nix run .#update-version`. Manual edits will be overwritten by the next bump.'
  echo "{"
  echo "  version = \"${new_version}\";"
  echo "  assets = {"
  while IFS=' *' read -r hex name; do
    [[ ${hex} == "#"* || -z ${hex} || -z ${name} ]] && continue
    sri=$(nix hash convert --to sri --hash-algo sha256 "${hex}")
    printf '    "%s" = "%s";\n' "${name}" "${sri}"
  done <"${tmp}"
  echo "  };"
  echo "}"
} >"${pin}"

echo "Verifying flake evaluates..."
nix eval --raw --file "${pin}" version >/dev/null

echo
echo "Updated to ${new_version}."
echo "  pin.nix updated. Commit to capture."
