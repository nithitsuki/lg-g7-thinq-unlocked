# Inventory

Hashes are in `MANIFEST.sha256` (git tree) and `MANIFEST.local.sha256` (large
files kept off git). Sizes are approximate.

## Root

| File | Purpose |
|---|---|
| `README.md` | Overview and result |
| `NOTES.md` | Method and traps |
| `PRESERVATION.md` | Mirrors and what matters |
| `TIMELINE.md` | The session as a story |
| `journey/` | Short chronology |
| `device/` | Device and firmware facts |
| `INVENTORY.md` | This file |
| `MANIFEST*.sha256` | Hashes |
| `verify.sh` | Checks the tree against the manifests |

## backups/

Read from the phone over EDL on 2026-10-22, before any write.

| File | Size | Partition |
|---|---|---|
| `abl_a.bin`, `abl_b.bin` | 1 MB each | Stock bootloader |
| `boot_a.bin`, `boot_b.bin` | 64 MB each | Kernel boot images |
| `dtbo_a.bin`, `dtbo_b.bin` | 8 MB each | Device tree overlays |
| `laf_a.bin`, `laf_b.bin` | 48 MB each | Download mode |
| `vbmeta_a.bin`, `vbmeta_b.bin` | 64 KB each | AVB metadata |
| `frp.bin` | 2 MB | FRP (LUN 6) |
| `devinfo.bin` | 256 KB | LG/Qualcomm devinfo |
| `SHA256SUMS.txt` | — | Hashes of the above |
| `misc-original/misc-bcb-captured-before-wipe.bin` | 1 MB | `misc` boot block captured mid-session |

## images/

| File | Size | Note |
|---|---|---|
| `eabl.img` | 1 MB | Engineering ABL (V35 prototype) |
| `frp-patched.img` | 2 MB | Patched FRP |
| `rawprogram4.xml` | 1 KB | QFIL script from Unlock845 |
| `boot-unlock845-judyln.bin` | 64 MB | Boot image shipped in Unlock845; not used |
| `stock-abl/laf/dtbo-from-unlock845.bin` | 1/48/8 MB | Stock images from the toolkit; not used on this phone |

## verification-readbacks/

Read-backs taken after writes: `verify_abl_a/b`, `verify_frp`, `verify_frp2`,
`verify_misc`, `verify_misc2`, `verify_devinfo_unlocked`, `check_abl_a`,
`check_devinfo`, `check_limits`, and the Lineage writes
`verify_los_dtbo_a/b`, `verify_los_vbmeta_a/b`, `verify_boot_a/b`.

## state-sweeps/

Read-only dumps from the boot-loop diagnosis: `mpt` (32 MB, LG data
filesystem), `oem_a/b` (8 MB each), `sec` (256 KB), `devinfo` and
`devinfo_unlocked` (256 KB each), `limits` (4 KB), `fsc` (512 KB, zero),
`logfs` (8 MB, empty FAT12), `logdump` (64 MB, zero).

## tools/windows/

`installers/` holds the LGUP 1.14.3 and 1.16 MSIs.
`unlock845-toolkit/` holds `Unlock845.zip` and its extracted tree: firehose
loader, `v35abl/`, LGUP tools, Windows adb/fastboot, drivers.

## tools/linux/

`prog_ufs_firehose_Sdm845_lge.elf`, clones of `bkerler/edl`,
`Lekensteyn/lglaf`, and two `runningnak3d/lglaf` forks, plus these scripts:

| Script | Purpose |
|---|---|
| `edl_watch.sh` | polls for `05c6:9008`, alerts when EDL is up |
| `lafrun.sh` | retries download-mode sessions |
| `laf_probe.py` | sends LAF frames over the vendor interface |
| `diag_probe.py` | Qualcomm DIAG probe |
| `upload-to-archive-org.sh` | builds and uploads the archive.org bundle |

## captures/

`gpt_full.txt` (partition map), `getvar_now.txt` (`fastboot getvar all`),
`getvar_all.txt`, `g7_props.txt` (getprop, redacted), `bootlog*.bin` (empty),
`edl_config.json`, `lgrom_page.html`, and REA tool outputs.

## lineage/

| File | Size | Note |
|---|---|---|
| `lineage-22.2-*-judyln-signed.zip` | 949 MB | ROM |
| `boot.img` | 64 MB | Lineage recovery |
| `dtbo.img`, `vbmeta.img` | 8 MB, 4 KB | Matching images |
| `copy-partitions-20220613-signed.zip` | 4 KB | Slot sync |
| `gapps/MindTheGapps-*.zip` | 484 MB | Google apps |
| `magisk/Magisk-v30.7.apk` | 12 MB | Magisk app |
| `magisk/magisk_patched-*.img` | 64 MB | Patched stock boot |
| `verify_*.img` | — | Read-backs from the direct-flash attempt |

## firmware/

`G710EMW30e_00_0916.kdz` — stock Android 10 firmware, India, 3.7 GB.
