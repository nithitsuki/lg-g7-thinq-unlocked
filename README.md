# lg-g7-thinq-unlocked

This directory preserves every file from the bootloader-unlock session of the
LG G7 ThinQ (LM-G710EMW, codename `judyln`) on 2026-10-22 and 2026-10-23.

## Result

The phone is unlocked and runs **LineageOS 22.2** (`22.2-20261018-NIGHTLY-judyln`,
Android 15, security patch 2026-10-01) with MindTheGapps 15.0.0 arm64.

Verified over ADB after the install: `ro.lineage.version` =
`22.2-20261018-NIGHTLY-judyln`, `ro.lineage.device` = `judyln`, active slot `_b`,
`ro.boot.verifiedbootstate` = `orange`.

The bootloader unlock is persistent and counted by LG's secure store
(`fastboot getvar` reports `unlocked:yes` and `unlock_count:1`). While the phone
still ran stock Android, Settings showed "Bootloader is already unlocked" in
Developer options.

The work ran in three stages: unlock the bootloader on stock Android 10 (30e),
root stock with Magisk, then install LineageOS 22.2 with the wiki's `dd` plus
sideload method. The method is in `NOTES.md`; the night itself is in
`TIMELINE.md`.

## Layout

| Path | Contents |
|------|----------|
| `TIMELINE.md` | The night as a story, chapter by chapter, with times and quotes |
| `README.md` | This file: result, layout, integrity, safety |
| `NOTES.md` | Technical findings and repeatable procedures |
| `INVENTORY.md` | File-by-file inventory with provenance |
| `journey/` | The short technical chronology, in order |
| `device/` | Device facts: model, serials, firmware values |
| `backups/` | 12 read-only partition dumps taken before any write, plus `SHA256SUMS.txt` and the captured `misc` block |
| `images/` | The images written to the phone, plus reference stock images from Unlock845 |
| `state-sweeps/` | Read-only dumps of LG's hidden state partitions |
| `verification-readbacks/` | Read-back dumps taken after each write |
| `tools/windows/` | LGUP installers and the Unlock845 release |
| `tools/linux/` | `edl`, three `lglaf` clones, the firehose loader, four helper scripts |
| `captures/` | Partition map, fastboot dumps, getprop, page captures |
| `firmware/` | The stock KDZ used for the final reflash |
| `lineage/` | LineageOS 22.2 build, recovery `boot.img`, `vbmeta`/`dtbo`, copy-partitions zip, MindTheGapps, Magisk APK and the patched stock boot image |
| `verify.sh` | Regenerates the hashes and diffs them against the manifest |
| `FIXES-LEFT.md` | Review status of the documentation pass: what landed, what is open |
| `PRESERVATION.md` | Where the fragile LG files live (archive.org, GitHub release) and why |

## Verification

`MANIFEST.sha256` lists every file tracked by git: **36 files**, a 4 MB
clone. The large local-only payloads (KDZ, raw dumps, Windows tools) are
recorded in `MANIFEST.local.sha256` and are hosted on archive.org instead. Run
the check from the repository root:

```bash
./verify.sh
```

The script regenerates the hashes with the same exclusions and runs `diff`
against `MANIFEST.sha256`. A clean run prints `manifest OK` and exits 0.
`./verify.sh --with-local` additionally checks the local-only payloads.

Large binaries (the KDZ, the Unlock845 zip, and all `.bin`/`.img` dumps) are
present on disk but excluded from git by `.gitignore`. Their hashes are in
`MANIFEST.sha256` like every other file. If you push this repository to a
hosting service, re-run `verify.sh` before you trust the tree.

## Safety notes

- The `.bin` files in `backups/` are the phone's own bootloader and modem
  configuration. Do not flash them to another phone. Restore them only against
  the partition they came from.
- `images/eabl.img` is an unsigned Oreo engineering ABL. Flashing it to a
  production G7 makes the phone refuse to boot Android until the stock ABL is
  restored. That is expected behavior, not a brick.
- The final reflash used `G710EMW30e` while the phone was running `V30w`, per
  the user. That is a **downgrade**. It worked here, but LG anti-rollback counters exist and
  the outcome is not guaranteed on another unit. Check `limits` and the
  anti-rollback state before repeating it.
- Every EDL partition write in this session was followed by a read-back and a
  SHA-256 comparison. The `edl e` erases were checked by reading zeros. The
  final LGUP KDZ flash was not instrumented. Keep the read-back rule.

## Where to start reading

1. `TIMELINE.md` — the night, as it happened
2. `journey/README.md` — the short chronology, with the wrong turns
3. `NOTES.md` — the technical findings and the repeatable procedures
4. `device/README.md` — the device identity and firmware values
5. `INVENTORY.md` — the file inventory with provenance
