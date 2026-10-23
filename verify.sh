#!/usr/bin/env bash
# Verify this repository against its manifests.
#
#   ./verify.sh              check the files tracked by git against MANIFEST.sha256
#   ./verify.sh --with-local also check the large local-only files against
#                            MANIFEST.local.sha256 (KDZ, raw dumps, Windows
#                            payloads). These files are not in the repository.
set -euo pipefail
cd "$(dirname "$0")"

TMP="$(mktemp)"
TMP2="$(mktemp)"
trap 'rm -f "$TMP" "$TMP2"' EXIT

check_tracked() {
  git ls-files -z \
    | grep -zv '^MANIFEST' \
    | xargs -0 sha256sum \
    | sort > "$TMP"
  sort MANIFEST.sha256 > "$TMP2"
  if diff -u "$TMP2" "$TMP"; then
    echo "manifest OK ($(wc -l < "$TMP") files)"
  else
    echo "manifest MISMATCH" >&2
    exit 1
  fi
}

check_local() {
  [ -f MANIFEST.local.sha256 ] || { echo "no MANIFEST.local.sha256"; return 0; }
  if sha256sum -c --quiet MANIFEST.local.sha256; then
    echo "local manifest OK ($(wc -l < MANIFEST.local.sha256) files)"
  else
    echo "local manifest MISMATCH" >&2
    exit 1
  fi
}

case "${1:-}" in
  --with-local) check_tracked; check_local ;;
  "")           check_tracked ;;
  *)            echo "usage: $0 [--with-local]" >&2; exit 2 ;;
esac
