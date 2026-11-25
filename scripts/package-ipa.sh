#!/usr/bin/env bash
# Packages a built .app into an IPA: <app> -> Payload/Lykos.app -> <output>.ipa
# Usage: scripts/package-ipa.sh <path/to/Lykos.app> [output.ipa]
set -euo pipefail

app="${1:?usage: package-ipa.sh <path/to/Lykos.app> [output.ipa]}"
out="${2:-Lykos-unsigned.ipa}"

if [ ! -d "$app" ]; then
  echo "No app bundle at $app" >&2
  exit 1
fi

out_dir="$(cd "$(dirname "$out")" && pwd)"
out_abs="$out_dir/$(basename "$out")"
rm -f "$out_abs"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mkdir "$work/Payload"
# ditto keeps the bundle's symlinks, permissions and extended attributes intact.
ditto "$app" "$work/Payload/Lykos.app"

# -y stores symlinks as links, -X leaves out extra file attributes.
(cd "$work" && zip -qry -X "$out_abs" Payload)

echo "Packaged $out_abs ($(du -h "$out_abs" | cut -f1))"
