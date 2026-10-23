# Inventory — every file, with provenance

Hashes: `MANIFEST.sha256` holds the SHA256 of every git-tracked file (36 files,
about 4 MB). `MANIFEST.local.sha256` holds the SHA256 of the large local-only
payloads that are not in git: the KDZ, the raw partition dumps, the Windows
toolkit and installers, and the LineageOS artefacts. Run `./verify.sh` for the
tracked tree, or `./verify.sh --with-local` for both. This document gives size,
purpose, and provenance per file or per group.

## Root files

| File | Purpose |
|------|---------|
| `README.md` | Orientation, result, layout, safety notes |
| `TIMELINE.md` | The session as a time-marked narrative, with quotations |
| `NOTES.md` | Technical findings and repeatable procedures |
| `INVENTORY.md` | This file |
| `MANIFEST.sha256` | SHA-256 for every git-tracked file |
| `MANIFEST.local.sha256` | SHA-256 for the large files kept off git |
| `PRESERVATION.md` | Where the fragile LG files live, with mirror links |
| `verify.sh` | Regenerates the hashes and diffs them against the manifest |
| `FIXES-LEFT.md` | Documentation review status: landed fixes and open items |
| `journey/README.md` | The short technical chronology |

## backups/ — phone partition dumps taken via EDL (read-only session)

Source: read from the phone (LM-G710EMW, LUN 4 unless noted) with
`edl r <partition> <file>` on 2026-10-22. The 12 main dumps were taken at
21:33–21:34, before the first write at 21:39. The `misc` block was captured
mid-session at 23:07. These are byte-exact copies of the phone's own firmware
state at those times. Their integrity is proven by `SHA256SUMS.txt`, which the
same session produced.

| File | Size | Note |
|------|------|------|
| `abl_a.bin` | 1.0M | Stock bootloader, slot A (active slot at dump time) |
| `abl_b.bin` | 1.0M | Stock bootloader, slot B |
| `boot_a.bin` | 0x4000000 bytes (64 MiB) | Kernel boot image, slot A |
| `boot_b.bin` | 64 MiB | Kernel boot image, slot B |
| `dtbo_a.bin` / `dtbo_b.bin` | 8 MiB each | Device tree overlays |
| `laf_a.bin` / `laf_b.bin` | 48 MiB each | Download-mode (LAF) boot images |
| `frp.bin` | 2 MiB | Factory Reset Protection partition (LUN 6) |
| `vbmeta_a.bin` / `vbmeta_b.bin` | 64 KiB each | AVB metadata |
| `devinfo.bin` | 256 KiB | LG/Qualcomm devinfo (`ANDROID-BOOT!` magic, version bytes `01 01`, then zeros) |
| `SHA256SUMS.txt` | — | Checksums, generated the same session |

`backups/misc-original/misc-bcb-captured-before-wipe.bin`
(1 MiB): the `misc` partition as captured mid-session, containing the
bootloader control block `recovery
--wipe_data
--reason=MasterClearConfirm
--locale=en_US`. The `edl` we ran later wiped `misc` and we restored this
block byte-for-byte; see `journey/README.md` for why it did not matter.

## images/ — what we wrote to the phone, and reference stock bins

| File | Size | Provenance and use |
|------|------|---------------------|
| `eabl.img` | 1 MiB | Engineering (unsigned Oreo prototype) ABL from Unlock845. We flashed this to `abl_a` and later to `abl_b` via EDL; read-back hashes matched byte-for-byte. Reference: it makes the phone show the Red Case and stay in fastboot; it never booted the OS on this unit. |
| `frp-patched.img` | 2 MiB | Patched FRP from Unlock845 (deliberate OEM-unlock bit set; contains a TWRP-style marker directory). Flashed once to LUN 6 via EDL. Later restored to stock. |
| `rawprogram4.xml` | 990 B | QFIL rawprogram from Unlock845; documents the sector offsets Unlock845 uses for `abl_a/b` and `boot_a/b` on LUN 4. Kept for reference. |
| `boot-unlock845-judyln.bin` | 64 MiB | Android bootimg shipped inside Unlock845, `androidboot.hardware=judyln`, `buildvariant=user`. We did not flash it. |
| `stock-abl-from-unlock845.bin` | 1 MiB | Stock-looking ABL shipped inside Unlock845 `tools/`. Reference only; our `abl` restores used our own `backups/`, not this file. |
| `stock-laf-from-unlock845.bin` | 48 MiB | Stock-looking laf from Unlock845 `tools/`. Reference only. |
| `stock-dtbo-from-unlock845.bin` | 8 MiB | Stock-looking dtbo from Unlock845 `tools/`. Reference only. |

## verification-readbacks/ — proof after each write

Each file is a fresh partition read taken seconds after a write. A matching
SHA256 between write input and read-back proves the flash laid down the exact
bytes.

| File | Proves |
|------|--------|
| `verify_abl_a.bin` | engineering ABL was byte-exact on `abl_a` after write 1 |
| `verify_abl_b.bin` | same for `abl_b` after write 2 |
| `verify_frp.bin` | patched FRP write landed (first pass) |
| `verify_frp2.bin` | stock FRP restore landed byte-exact |
| `verify_misc.bin` | `misc` fully zero after erase (all 1048576 bytes zero) |
| `verify_misc2.bin` | `misc` restored to the captured BCB content |
| `check_abl_a.bin` | `abl_a` was still engineering content at the check read (pre-restore state) |
| `check_devinfo.bin` | `devinfo` unchanged through the unlock attempts |
| `check_limits.bin` | `limits` content captured during the boot-loop diagnosis |
| `verify_devinfo_unlocked.bin` | the single-byte `is_unlocked=1` write read back identical, with no effect on boot (see "The devinfo experiment" in `NOTES.md`; no revert write exists in the log) |

## state-sweeps/ — hidden state partition dumps (read-only diagnosis)

| File | Size | Content |
|------|------|---------|
| `mpt.bin` | 32 MiB | Mounted LG data filesystem (`/mnt/vendor/mpt`, SElinux `mpt_file`): `LDB_MainData.db`, EULA/log files. Not a boot-control store. |
| `oem_a.bin`, `oem_b.bin` | 8 MiB each | LG "OP" data filesystems (SElinux `op_file`), identical non-zero content. |
| `devinfo.bin` | 256 KiB | Same dump as `backups/devinfo.bin`, taken during diagnosis. |
| `devinfo_unlocked.bin` | 256 KiB | The modified devinfo we wrote (only byte at offset 0x10 changed 0x00 to 0x01). |
| `limits.bin` | 4 KiB | LG anti-rollback/counter structure (16 non-zero bytes at head). |
| `fsc.bin` | 512 KiB | Fully zero. |
| `logfs.bin` | 8 MiB | Empty FAT12 volume ("LOGFS", 0 files, mtime 2016). |
| `logdump.bin` | 64 MiB | Fully zero. |

## tools/windows/

**`installers/LGUP_Store_Frame_Ver_1_14_3.msi`** (15 MiB) and
**`installers/LGUP_Lab_Frame_Ver_1_16_0_3.msi`** (17 MiB) — LGUP frameworks,
downloaded from `lg-firmwares.com/downloads/flash-tools/` on 2026-10-23. We
installed both on the Windows PC, with `model/common/LGUP_Common.dll` copied
in from the Unlock845 release (the standard community patch step).

**`unlock845-toolkit/Unlock845.zip`** (132,324,348 bytes): the complete
release 3.0_rev1.0-G7 of `log1cs/Unlock845` (GitHub, published 2022-09-26).
The zip's comment field carries the hash string
`b63315b898fb321be547d18b8436d8d43744cc9e`.

**`unlock845-toolkit/Unlock845-3.0_rev1.0-G7/`** — the full extracted tree:
- `prog_ufs_firehose_Sdm845_lge.elf` — the leaked LG SDM845 UFS firehose loader
- `v35abl/` — `eabl.img`, `frp.img`, `boot.bin`, `rawprogram4.xml`
- `tools/` — Windows LGUP portable (`LGUP.exe`, `LGUP_Cmd.exe`,
  `LGUP_Common.dll`, `model/LGUP_LGNPST`), Windows `fastboot.exe`/`adb.exe`,
  and stock `abl.bin`/`laf.bin`/`dtbo.bin`
- `FastbootFix.bat` — three registry keys that fix Windows enumeration of the
  `18d1:d00d` fastboot device (`osvc`, `SkipContainerIdQuery`,
  `SkipBOSDescriptorQuery`). We did not need to run it on this session.
- `Unlock_EN.bat` / `Unlock_VI.bat` — the unlock scripts
- `Prerequisites/` — driver installers (LG Mobile Driver 4.8.0,
  Qualcomm USB driver, vcredist x64/x86). We installed the two driver
  installers silently on the Windows PC during the session.

## tools/linux/

**`prog_ufs_firehose_Sdm845_lge.elf`** (651 KiB / 667 kB) — the same LG firehose loader,
extracted from Unlock845. Every successful `edl` read and write in this
session used this loader (`--loader=…`), with `--memory=ufs`.

**`edl/`** — clone of `bkerler/edl`, branch `master`, HEAD `1cda1a6`. The AUR
metadata reported `edl-git` 3.52.1.r414; the installed build reported
3.52.1.r436. Used for all partition reads/writes, `printgpt`, `erase`, and
`reset`.

**`lglaf/`** — clone of `Lekensteyn/lglaf`, HEAD `7eeac45`. The LAF protocol
implementation. Reads on this firmware never answered; findings documented in
NOTES.md.

**`lglaf-nak3d-gitlab/`** — clone of `gitlab.com/runningnak3d/lglaf`
(HEAD `0a02957`) and **`lglaf-nak3d-github/`** — clone of
`github.com/runningnak3d/lglaf` (HEAD `982b1be`). Both contain the CR
(KILO challenge) logic; neither produced a live LAF session on this phone.

**`scripts/`** — written during this session:
- `edl_watch.sh` — polls `lsusb` every 50 ms for `05c6:9008`, desktop popup,
  alarm sound, and streamable output. This is the button-combo watchdog.
- `lafrun.sh` — retry wrapper for LAF sessions (re-enters download mode).
- `laf_probe.py` — sends `HELO`/`OPEN`/`READ` over the vendor bulk interface
  and logs every response; used to prove that plain LAF framing does not get
  a reply on this build.
- `diag_probe.py` — Qualcomm DIAG probe of the `ff/ff/48` interface
  (version request, echo).

## captures/

| File | Content |
|------|---------|
| `gpt_full.txt` | Full GPT of LUN 0–6 from `edl printgpt` (all partition names, offsets, lengths, flags) |
| `g7_props.txt` | Complete `adb shell getprop` of the phone, taken pre-unlock (45 KB) |
| `getvar_now.txt` | 221-line `fastboot getvar all` from the stock ABL after the unlock: includes `unlocked:yes`, `unlock_count:1`, `current-slot:b`, `slot-unbootable:a:yes`, `slot-unbootable:b:yes` |
| `getvar_all.txt` | A two-line failed `fastboot getvar all` (`unknown command`) from a wedged stock-ABL session; retained as evidence of the one-command-per-boot behavior |
| `bootlog.bin`, `bootlog2.bin` | ttyACM0 captures during boot attempts (both zero bytes: no serial boot log on this unit) |
| `edl_config.json` | bkerler `edl` session config written next to the dumps |
| `lgrom_page.html` | The lgrom.com firmware page HTML, showing the reCAPTCHA-gated download flow (CSRF token + `/downloadnow` POST) |
| `lgrom_cookies.txt` | Session cookies captured while probing the lgrom.com download flow; kept for provenance of the `{"code":604}` captcha rejection |
| `rea-dryrun.json`, `rea-dryrun.err`, `rea-apply.json`, `rea-apply.err` | Session-tooling artifacts from the REA skill setup; not device data |

## firmware/

**`G710EMW30e_00_0916.kdz`** — 3.7 GiB, stock Android 10 firmware for
LM-G710EMW, region IND. The user downloaded it in Firefox from the lgrom.com
IND 30E page (`lgrom.com/firmware/LMG710EMW/IND/G710EMW30E_00/9824`); the
scripted POST to `/downloadnow` was rejected with `{"code":604}`. The KDZ page
on `lg-firmwares.com` is `downloads-file/25952`; the LGUP MSIs came from
`lg-firmwares.com/downloads/flash-tools/`. SHA256 `575e07fcb8f283f7f9dbc27da302d95ae441120c470f90b8
6b291be330bbe91e` (full value in `MANIFEST.sha256`). Flashed via LGUP on the
Windows PC; the instructions specified Refurbish, but the user's exact GUI
selection was not captured. This reflash restored the phone to a booting stock
state.

## device/

- `README.md` — device identity, firmware values, and unlock-state evidence
- `getprop-full.txt` — the same complete getprop dump as `captures/g7_props.txt`

## journey/

- `README.md` — the full chronological story of the session, including the
  wrong turns and how each got resolved

## lineage/ — the LineageOS 22.2 install (23 October)

All files downloaded on 2026-10-23 from `download.lineageos.org` and
`mirrorbits.lineageos.org`; the ROM and `boot.img` SHA256 values were checked
against the download API before use.

| File | Size | Note |
|------|------|------|
| `lineage-22.2-20261018-nightly-judyln-signed.zip` | 949 MB | The ROM. SHA256 `71c9be17845afbf9926f4063a0d03ded04a9e3381082cbf8e0bc32261e7b8915` |
| `boot.img` | 64 MB | Lineage recovery image. SHA256 `48748a27406c676af5bf779df3b165654ed4b8e8fe7ca8a8e5a7fd7da0df66f2` |
| `dtbo.img` | 8 MB | Matches the Lineage boot/vbmeta chain |
| `vbmeta.img` | 4 KB | avbtool vbmeta for `lge/lineage_judyln` |
| `copy-partitions-20220613-signed.zip` | 4 KB | A/B slot sync package |
| `edl_config.json` | 320 B | `edl` session config written during the boot-flash attempt |
| `gapps/MindTheGapps-15.0.0-arm64-20260915_032013.zip` | 484 MB | Google apps add-on. SHA256 `e979601ef70b03d9214ea24ca7a103cb408ab102718fff38ec170a6ca03e263d`, matches the release `.sha256sum` |
| `gapps/MindTheGapps-....zip.sha256sum` | 112 B | The release checksum file |
| `magisk/Magisk-v30.7.apk` | 12 MB | Magisk app used to root stock Android |
| `magisk/magisk_patched-30700_VvoN2.img` | 64 MB | Stock boot image patched by the Magisk app (force-encryption and AVB preserved). SHA256 `a6bb191592fd690adad337bcf836a68e04f5947f4721c408fa10fba8fe0328f6` |
| `verify_boot_a.img`, `verify_boot_b.img` | 64 MB each | Read-back after writing the Lineage `boot.img` to the boot slots |
| `verify_los_dtbo_a.img`, `verify_los_dtbo_b.img` | 8 MB each | Read-back after writing Lineage `dtbo` |
| `verify_los_vbmeta_a.img`, `verify_los_vbmeta_b.img` | 64 KB each | Read-back after writing Lineage `vbmeta` |

Note: the Lineage boot image was written to both boot slots directly through EDL
and read back byte-exact, but the LG ABL refused to boot it (see `NOTES.md`).
The install that worked wrote the same image with `dd` from the rooted stock
system. These files are kept as evidence of that dead end and of the final
method.
