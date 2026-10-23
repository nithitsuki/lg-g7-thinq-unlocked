#!/usr/bin/env bash
# Upload the LG G7 ThinQ (LM-G710EMW) preservation bundle to archive.org.
#
# Prerequisites:
#   uv tool install internetarchive
#   ia configure            # once, with a free archive.org account
#
# The bundle contains:
#   - the stock KDZ (the file most likely to disappear)
#   - the Unlock845 toolkit zip
#   - both LGUP installers
#   - a tarball of the firmware partition dumps (no device-private partitions)
#   - the document set from this repository
set -euo pipefail
cd "$(dirname "$0")/../../.."          # repository root

IDENTIFIER="${ARCHIVE_IDENTIFIER:-lg-g7-thinq-emw-unlock-archive-2026}"
DOCS_ONLY=0
[ "${1:-}" = "--docs-only" ] && DOCS_ONLY=1
KDZ="${KDZ_PATH:-$HOME/Downloads/G710EMW30e_00_0916.kdz}"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

require() { command -v "$1" >/dev/null || { echo "missing: $1" >&2; exit 1; }; }
require ia
require tar

[ -f "$KDZ" ] || [ "$DOCS_ONLY" = 1 ] || { echo "KDZ not found: $KDZ" >&2; exit 1; }

if [ "$DOCS_ONLY" = 0 ]; then
  echo "== staging firmware dumps (public-safe partitions only)"
  mkdir -p "$STAGE/dumps"
  for p in abl_a abl_b boot_a boot_b dtbo_a dtbo_b laf_a laf_b vbmeta_a vbmeta_b; do
    cp "backups/$p.bin" "$STAGE/dumps/"
  done
  cp backups/SHA256SUMS.txt "$STAGE/dumps/" 2>/dev/null || true
  ( cd "$STAGE" && sha256sum dumps/*.bin > dumps/SHA256SUMS-archive.txt )
  tar -C "$STAGE" -cf "$STAGE/lg-g7-thinq-emw-firmware-dumps.tar" dumps
fi

echo "== staging documents"
tar -cf "$STAGE/lg-g7-thinq-unlocked-docs.tar" \
  README.md TIMELINE.md NOTES.md INVENTORY.md PRESERVATION.md \
  MANIFEST.sha256 verify.sh device journey captures images/rawprogram4.xml \
  images/eabl.img images/frp-patched.img \
  tools/linux/scripts tools/linux/prog_ufs_firehose_Sdm845_lge.elf

echo "== uploading to archive.org: $IDENTIFIER"
FILES=("$STAGE/lg-g7-thinq-unlocked-docs.tar")
if [ "$DOCS_ONLY" = 0 ]; then
  FILES=("$KDZ" "tools/windows/unlock845-toolkit/Unlock845.zip" \
    "tools/windows/installers/LGUP_Store_Frame_Ver_1_14_3.msi" \
    "tools/windows/installers/LGUP_Lab_Frame_Ver_1_16_0_3.msi" \
    "$STAGE/lg-g7-thinq-emw-firmware-dumps.tar" "${FILES[@]}")
fi
ia upload "$IDENTIFIER" "${FILES[@]}" \
  --metadata="mediatype:software" \
  --metadata="title:LG G7 ThinQ (LM-G710EMW) — bootloader unlock and LineageOS 22.2 archive" \
  --metadata="creator:nithilan" \
  --metadata="date:2026-10-23" \
  --metadata="subject:LG G7 ThinQ; LM-G710EMW; judyln; bootloader unlock; LineageOS; EDL; firehose" \
  --metadata="description:Preservation bundle for the LG G7 ThinQ (LM-G710EMW, judyln) bootloader unlock and LineageOS 22.2 installation. Contains the G710EMW30e stock KDZ, the Unlock845 toolkit, LGUP installers, SHA256-verified firmware partition dumps, and the full document set with the reproducible method. See https://github.com/nithitsuki/lg-g7-thinq-unlocked" \
  --retries=10

echo "== done. Verify at https://archive.org/details/$IDENTIFIER"
