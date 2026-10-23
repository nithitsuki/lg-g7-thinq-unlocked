# LG G7 ThinQ (LM-G710EMW) — unlock + LineageOS 22.2

Unlocked an LG G7 ThinQ on stock Android 10 and installed LineageOS 22.2.
This repo has the method, the notes, and the files that are hard to find.

## Result

- Bootloader unlocked: `fastboot getvar unlocked` → `yes`, `unlock_count: 1`.
  It persists across ABL reflashes and a full firmware reflash.
- LineageOS 22.2 (`22.2-20261018-NIGHTLY-judyln`), Android 15,
  MindTheGapps 15.0.0 arm64.
- Phone model `LM-G710EMW`, firmware `G710EMW30e` (India).

## Path taken

1. Unlock on stock Android 10 using the V35 engineering ABL and the leaked
   LG SDM845 firehose (EDL).
2. Reflash the stock KDZ with LGUP to repair the boot state.
3. Root stock with Magisk.
4. Write the Lineage recovery to both boot slots with `dd`, then sideload
   LineageOS and Gapps.

## Start here

| File | What it is |
|---|---|
| `NOTES.md` | The working method and the traps |
| `PRESERVATION.md` | Where the hard-to-find files are mirrored |
| `device/` | Device facts and firmware values |
| `journey/` | Short chronology, including the dead ends |
| `TIMELINE.md` | The whole session as a narrative (blog source) |
| `INVENTORY.md` | File list with sizes and sources |

## Files in git

`images/eabl.img`, `images/frp-patched.img`, and
`tools/linux/prog_ufs_firehose_Sdm845_lge.elf` are the three files that make
the unlock possible. They are small and they are committed here.

Everything else large (KDZ, partition dumps, Windows toolkit, LGUP installers)
is listed in `MANIFEST.local.sha256` and mirrored:

- https://github.com/nithitsuki/lg-g7-thinq-unlocked/releases/tag/v1.0
  (Unlock845 toolkit, LGUP installers)
- archive.org item `lg-g7-thinq-emw-unlock-archive-2026`
  (KDZ, firmware dumps, docs)

## Check the tree

```bash
./verify.sh                # files tracked by git
./verify.sh --with-local   # also the local-only payloads
```

## Risks

Unlocking wipes data. Directly flashing a Lineage `boot.img` to `boot_a`/`boot_b`
does not work on this device — see `NOTES.md`. Keep the partition backups in
`backups/` before you write anything.

Repository: https://github.com/nithitsuki/lg-g7-thinq-unlocked
