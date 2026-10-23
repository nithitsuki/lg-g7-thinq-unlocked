# Notes

What worked on `LM-G710EMW` (`judyln`), stock Android 10, firmware
`G710EMW30e` (India), October 2026. Commands are Linux, with
[`edl`](https://github.com/bkerler/edl) and the loader
`prog_ufs_firehose_Sdm845_lge.elf` from `tools/linux/`.

## Two things that block the obvious path

1. **The stock fastboot is read-only in practice.** `adb reboot bootloader`
   reaches real fastboot (`18d1:d00d`), and `getvar` works. `flash`, `erase`,
   `boot`, and `oem unlock` all hang or refuse. If you queue a command before
   the session opens, it sometimes runs as the first packet and then the
   session dies. Do not rely on it.
2. **The LG bootloader will not boot a Lineage boot image written straight to
   `boot_a`/`boot_b`.** It shows the orange warning, then drops to fastboot,
   and the slot retry counters go down with each attempt. Writing the matching
   Lineage `vbmeta` and `dtbo` does not change this. The install has to use the
   wiki's `dd` method from a rooted stock system.

EDL is the only reliable write path on this phone.

## EDL

Enter: power off, hold Vol- + Power, and tap Vol+ rapidly in the black gap
before the logo. The phone shows nothing; it appears as `05c6:9008`.

```sh
L=$PWD/tools/linux/prog_ufs_firehose_Sdm845_lge.elf
sudo edl printgpt --loader=$L --memory=ufs
sudo edl r abl_a abl_a.bin --loader=$L --memory=ufs --lun=4
sudo edl w abl_a abl_a.bin --loader=$L --memory=ufs --lun=4
sudo edl e misc --loader=$L --memory=ufs
sudo edl reset
```

`abl`, `boot`, `dtbo`, `laf`, `vbmeta`, `devinfo` are on LUN 4. `frp` is on
LUN 6. `system`/`vendor`/`userdata` are on LUN 0. Partition map:
`captures/gpt_full.txt`.

Back up before writing:

```sh
for p in abl_a abl_b laf_a laf_b boot_a boot_b dtbo_a dtbo_b vbmeta_a vbmeta_b; do
  sudo edl r $p backups/$p.bin --loader=$L --memory=ufs --lun=4
done
sudo edl r frp backups/frp.bin --loader=$L --memory=ufs --lun=6
```

## Unlock

Stock Android, OEM unlock enabled in Developer options.

1. Write the engineering ABL to both slots:

   ```sh
   sudo edl w abl_a images/eabl.img --loader=$L --memory=ufs --lun=4
   sudo edl w abl_b images/eabl.img --loader=$L --memory=ufs --lun=4
   sudo edl reset
   ```

   The phone now shows the Red Case and falls into fastboot. That is expected:
   the image is an unsigned Oreo prototype ABL.

2. From fastboot, run `fastboot oem unlock`. The replies rotate between
   `unknown command`, silence, and `Set device unlocked! failed: 00000050`.
   Repeat on fresh sessions. When `fastboot getvar unlocked` reports `yes`,
   the state is set (`unlock_count: 1`).

3. Restore the stock bootloader and FRP from the backups, then flash the stock
   KDZ with LGUP (see below).

## Repair the boot state after the unlock

On this phone the unlock left both A/B slots marked unbootable, so every boot
went to fastboot.

- LG's `fastboot set_active` is not implemented (`Device does not support slots`).
- Wiping `misc` and rewriting the boot control block made no difference.
- `devinfo`, `fsc`, `logfs`, `logdump`, `limits` had nothing useful.

What fixed it: **LGUP Refurbish** with `G710EMW30e_00_0916.kdz` on Windows.
Install LGUP (MSIs in release `v1.0`), copy `LGUP_Common.dll` from the
Unlock845 toolkit into `LGUP/model/common/`, pick the port, select the KDZ,
choose **Refurbish**, start. The phone reflashes and boots stock Android with
the orange warning.

## Root stock with Magisk

1. `adb install Magisk-v30.7.apk` (in `lineage/magisk/`).
2. `adb push backups/boot_a.bin /sdcard/boot.img`
3. Magisk → Install → Select and Patch a File → `boot.img`. Keep
   "Preserve Force Encryption" and "Preserve AVB 2.0/dm-verity" on.
4. `adb pull /sdcard/Download/magisk_patched-*.img`
5. Write it over EDL to `boot_a` and `boot_b`, then `edl reset`.
6. Magisk → Settings → Superuser access → **Apps and ADB**. If "Shell" is
   listed as denied in the Superuser tab, delete it. Check: `adb shell su -c id`
   → `uid=0(root)`.

## Install LineageOS

With root, from the phone:

```sh
adb push lineage/boot.img /sdcard/lineage-recovery.img
adb shell su -c 'dd if=/sdcard/lineage-recovery.img of=/dev/block/bootdevice/by-name/boot_a'
adb shell su -c 'dd if=/sdcard/lineage-recovery.img of=/dev/block/bootdevice/by-name/boot_b'
adb reboot recovery
```

In Lineage recovery:

1. **Advanced → Enable ADB** (the recovery's adb is unauthorized until this).
2. **Apply update → Apply from ADB**, then
   `adb sideload lineage/copy-partitions-20220613-signed.zip`.
3. **Advanced → Reboot to recovery**.
4. **Factory reset → Format data**.
5. **Apply update → Apply from ADB**, then
   `adb sideload lineage/lineage-22.2-*-judyln-signed.zip`.
6. Answer **Yes** to "reboot to recovery now", then sideload
   `lineage/gapps/MindTheGapps-*.zip`.
7. **Reboot system now**.

## Traps

- Sideload can stop at ~47% with `adb: failed to read command: Success`.
  The install is fine; the phone shows Step 1/2 and Step 2/2.
- Recovery says `Signature verification failed` for Gapps. Install anyway —
  add-ons are not signed with LineageOS keys.
- Recovery adb shows `unauthorized` with no prompt until
  **Advanced → Enable ADB**.
- Do not reboot to system between the ROM and the add-on.
- First boot takes several minutes.

## LineageOS notes

- `ro.lineage.version` `22.2-20261018-NIGHTLY-judyln`, Android 15.
- IMS does not work on this device. No VoLTE or VoWiFi. A Jio SIM gets no
  voice calls; Airtel and Vi fall back to 2G/3G.
- Play Integrity fails. Banking apps need extra work.
- Magisk root does not carry over from stock. Patch the Lineage boot image
  separately if you want root.
- Lineage recovery lives in the boot slot. Reflashing `boot.img` replaces it.

## If you need stock again

Write `backups/boot_a.bin` and `backups/boot_b.bin` back with EDL, then the
stock KDZ via LGUP Refurbish. Keep `backups/` before any write.
