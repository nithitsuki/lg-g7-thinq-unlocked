# Technical notes — LG G7 ThinQ (judyln) unlock on Linux

These notes record what we learned that the public guides do not say. Read them
before running any of the procedures again.

## Modes and PIDs seen on this unit

| PID | Meaning observed here |
|-----|------------------------|
| `1004:633e` | Stock Android, MTP/normal. ADB available. |
| `1004:633a` | Transient composite mode reached via `adb reboot edl` and `adb reboot download`. No download-mode screen. It exposes a CDC-ACM AT port (`/dev/ttyACM0`) and a vendor interface `ff/ff/48`, which matches Qualcomm DIAG rather than LG LAF. It also appears on its own after some reboots, then exits after about a minute. |
| `18d1:d00d` | Fastboot. Reachable with `adb reboot bootloader` even on stock, locked firmware. |
| `05c6:9008` | EDL (Qualcomm QDL). Entered only by the button sequence. |

## EDL entry that works on this unit

There are two routes. Use the one that matches the screen you are on.

**From Android or powered off:**

1. Power the phone off fully (hold Vol- + Power until black; release).
2. Connect the USB cable.
3. Hold **Volume Down** and **Power** together. The moment the screen goes
   black, keep holding both and tap **Volume Up** rapidly, about 5 taps per
   second, for around 5 seconds.
4. Silence on the phone is success; the watchdog
   (`tools/linux/scripts/edl_watch.sh`) reports `05c6:9008` with a desktop
   popup and an alarm.

**From the fastboot screen:**

1. Highlight **Restart bootloader** with the volume keys.
2. Hold **Volume Down** and keep it held.
3. Press **Power** to confirm. The bootloader restarts.
4. In the black gap, keep Vol- held and tap Vol+ rapidly.

Vol- + Power does **nothing** on the fastboot menu. This cost us several failed
attempts before the on-screen menu was used.

The window is short (a few seconds between "off" and "logo"). If the G7 logo
appears instead, the window closed; retry.

## The LAF / DIAG dead end

`1004:633a` looks like a download-mode device, but this firmware does not speak
the classic LAF protocol on it. Findings:

- The vendor interface is `ff/ff/48` with two bulk endpoints. `lglaf` expects
  `ff/ff/ff`; the matcher was relaxed to reach it.
- `HELO` gets no banner. `OPEN` gets an I/O error. The `runningnak3d` fork,
  which implements the KILO challenge-response for `0x633a`, also failed; the
  `laf_crypto` path was installed and exercised.
- A passive read of `/dev/ttyACM0` caught `ate0\r\r\nOK\r\n`: the serial port is
  an AT channel for the modem, not the LAF transport.
- On this generation, an invalid LAF frame reboots the phone. That is why the
  early attempts kept returning to the home screen.
- `lafd` lives in the `laf` boot partition, not in `/system`, so it cannot be
  pulled from a running Android.
- The DIAG probe (`tools/linux/scripts/diag_probe.py`) sent a version request
  to `ff/ff/48`; it did not produce a usable session before the mode exited.

Conclusion: the software routes tried here failed. The hidden service menu
(`*#546368#*710#`) and the DIAG reboot packet were proposed but never tested.
Do not claim that no software route exists; claim only that these did not work.

## What works from EDL

Everything, with bkerler `edl` and the LG loader:

```bash
L=/path/to/prog_ufs_firehose_Sdm845_lge.elf
sudo edl printgpt --loader=$L --memory=ufs          # full partition map, all LUNs
sudo edl r <partition> <file> --loader=$L --memory=ufs --lun=<n>
sudo edl w <partition> <file> --loader=$L --memory=ufs --lun=<n>
sudo edl e <partition> --loader=$L --memory=ufs      # TRIM (fast on UFS)
sudo edl reset                                       # reboot out of EDL
```

- `abl_a`, `abl_b`, `boot_a/b`, `dtbo_a/b`, `laf_a/b`, `vbmeta_a/b`,
  `devinfo`, `sec`, `misc`, `logfs`, `logdump`, `limits` live on LUN 4.
- `frp` lives on LUN 6.
- `fsc` lives on LUN 5.
- LUN 0 holds the big LG/system/userdata partitions (`mpt`, `oem_a/b`,
  `userdata`).

Every EDL partition write we did was verified with a fresh read after the
write (see `verification-readbacks/`). The `edl e` erases were checked by
reading zeros, not by SHA-256. The final LGUP KDZ flash was not instrumented at
all. Do the same read-back for any future EDL write.

## Stock fastboot on this firmware: what it accepts

With the *stock* ABL, `adb reboot bootloader` reaches a real fastboot
(PID `18d1:d00d`, serial `LMG710…`). Observed behavior:

- `fastboot getvar all` works on a fresh session (about 221 lines: counters,
  slots, partition sizes). It reports `unlocked:no` when the device is locked.
- `fastboot oem unlock` hangs with no reply on a locked bootloader. The stock
  ABL does not emit `00000050`; that error comes from the engineering ABL (see
  below). LG wants its own `unlock.bin` here, and the server that issued those
  closed in 2021.
- After the unlock state exists, the stock ABL reports `unlocked:yes` and
  `unlock_count:1`, and keeps that state across reboots and ABL restores.
- `fastboot set_active` is refused ("Device does not support slots"), even
  though `getvar` reports `slot-count:2`. `fastboot --set-active=a` is accepted
  on a fresh session, but the phone still did not boot. The unbootable flags
  were never re-read, so we do not know whether the command changed them.
- `fastboot flash`, `fastboot boot`, `fastboot erase` hang or drop the session.
  A fresh fastboot session often accepts only **one** command, then the USB
  link dies. This is a tendency, not a rule: some sessions answered `getvar`
  twice. Queue the command before the device enumerates if timing matters.
- `fastboot getvar all` returns `unknown command` on some boots, and full
  output on others. The ABL's command state is not stable across boots.

## Engineering ABL (eabl.img) behavior on this unit

- Identifies as product `LM-V350EMW`, carrier `judyp_lao_com`, HW rev_10,
  secure boot `yes`, state `locked`, with our serial appended
  (`LMV350EMWa65939f9`).
- The OS boot shows the Red Case (g.co/ABH) and falls back to fastboot. This is
  Unlock845's documented failure mode: the ABL is an unsigned Oreo prototype
  image.
- `fastboot oem unlock` cycles through three observed states:
  `unknown command`, silent hang then `Set device unlocked! failed: 00000050`,
  and `unlocked: yes`.
- The command leaves the fastboot channel answering inconsistently: `getvar`
  may go silent, then a later `reboot-bootloader` returns OKAY. It is not a
  reliable wedge.
- `fastboot flash` hangs on this ABL, including `frp` on LUN 6. Use EDL for
  every write.

## The unlock state machine we observed

Across many attempts with the engineering ABL:

1. `FAILED (remote: 'unknown command')`
2. Silent hang, then `getvar` reports
   `Set device unlocked! failed: 00000050`
3. On a later fresh session, `unlocked: yes`

Community threads (XDA 4168771 and forum.earlybird.club) describe exactly this
three-state rotation and report that repeated attempts eventually land the
unlocked state, even when the screen keeps saying locked. The error surfaced
from `getvar unlocked`, after a sequence of unlock verbs. It is consistent with
a failure inside the set-unlocked routine. The store it writes was not
reverse-engineered.

We tried the community remedy: fire `oem unlock` as the first packet of a fresh
session, from a background watcher. The watcher's command did not reach the
device (host-side write error), and the following `getvar` already said
`unlocked: yes`. The state had been set by an earlier attempt. The first-packet
pattern was therefore **not demonstrated**; treat it as a plausible community
remedy, not a proven mechanism.

The state is **not** stored in `devinfo`. It survives:
- reboots,
- restoring both stock ABLs,
- restoring the stock FRP,
- the final KDZ reflash (mode instructed as Refurbish; selection not captured).

The working assumption is RPMB or a fuse-backed LG secure store. Flash reads
cannot see it.

## The FRP patch, and what it actually contains

`frp.img` from Unlock845 is an ext2 filesystem. Inside it:

```
/TWRP/BACKUPS/LMV3508ddd3823/2017-08-17--21-26-20_OPM1171019026
```

The directory is named after a **V35 prototype serial**, not this phone. LG
stores the unlock authorization under a serial-keyed path, and the patched
image carries someone else's key. That is why the patch works across supported
models, and why it is not device-specific.

`frp` is on LUN 6, 2 MB. The stock image was backed up (`3f6fd1d5…`) and
restored after the unlock. The patched image is `11ec9af9…`.

## The devinfo experiment

Qualcomm's `devinfo` layout puts `is_unlocked` at offset `0x10`. We wrote `01`
there (one byte, everything else identical) and read it back. The write was
verified, and the phone still booted to fastboot.

The original dump (`backups/devinfo.bin`, `state-sweeps/devinfo.bin`) is
byte-identical to the factory state: `ANDROID-BOOT!` plus zeros. The modified
image is kept as `state-sweeps/devinfo_unlocked.bin` and
`verification-readbacks/verify_devinfo_unlocked.bin`. **No revert write
appears in the session log.** The final KDZ reflash is the only later event that
could have rewritten the partition. Do not describe the phone's final `devinfo`
as "unchanged" unless you read it back first.

## The boot loop after unlock, and the fix

Symptom: every boot, including a clean manual power cycle, went LG logo or
orange warning → fastboot. The ABL never started the kernel.

`fastboot getvar all` exposed the state that best explains the loop:

```
current-slot:b
slot-unbootable:a:yes
slot-unbootable:b:yes
slot-successful:a:yes
slot-successful:b:yes
slot-retry-count:a:6
slot-retry-count:b:7
```

Both slots were marked unbootable in the GPT attributes. The engineering ABL's
unlock path is the likely writer, but this is inference. LG's stock fastboot
refused `set_active` ("does not support slots"). `--set-active=a` was accepted
on a fresh session; the phone still did not boot, and the flags were not
re-read. This is the leading explanation for the loop, not a proven cause.

Checks that came back clean during diagnosis (all captured in this repo):

- `misc`: contained the BCB `recovery --wipe_data --reason=MasterClearConfirm
  --locale=en_US`. Erasing it and restoring it did not change the boot result,
  so it was not the gate. The writer is unknown; the pre-unlock
  `bootreason: reboot,factory_reset` makes an earlier factory reset a plausible
  source.
- `devinfo`: original dump is `ANDROID-BOOT!`, version bytes `01 01`, then
  zeros. The one-byte `is_unlocked` write had no effect (see above).
- `limits`: 4 KiB with 16 nonzero bytes. The values look like counters; the
  structure is not decoded.
- `fsc` (512 KiB) is zero. `logfs` (8 MiB) is an empty FAT12 volume from 2016
  with 497 nonzero bytes of metadata and no files. `logdump` (64 MiB) is zero.
  No boot logs exist anywhere on this build.
- `mpt`, `oem_a/b`: ext4 data partitions, not boot-control stores.
- `sec`: 256 KiB with 179 nonzero bytes of LG security data.

The fix that finally restored booting: **LGUP**, with the stock KDZ
(`G710EMW30e_00_0916.kdz`) on Windows. The instructions specified **Refurbish**;
the user's exact GUI selection was not captured. LGUP rewrites the partition
layout, slot attributes, and firmware partitions, then reboots the phone. After
it, Android boots with the orange unlocked warning, and the unlock state
survives the reflash.

## Firmware version, and why it matters

The user reports **V30w-IND-XX** before the repair and **30e** after it. That is
a downgrade. The captured pre-unlock property dump complicates the record:

```
[ro.vendor.lge.swversion]: [G710EMW30e]
[ro.vendor.lge.swversion_short]: [V30e]
[persist.product.lge.radio.prevswversion]: [G710EMW30e]
```

The vendor field says 30e even before the flash. It may describe the vendor
image rather than the full system build, or the Settings value may have been
misread. The session did not capture the Settings screen. Record both: the
user's V30w → 30e account, and the vendor field's 30e.

If the downgrade is real, anti-rollback matters. The `limits` partition (4 KiB,
16 nonzero bytes) was read but not decoded. Treat it as an anti-rollback
candidate, not a confirmed one.

Before any cross-version flash:

1. Read `limits` and record it.
2. Compare the target firmware's anti-rollback index with the installed one.
3. Have the full partition backups on disk, verified.

The Linux-only alternative (extract the KDZ with `kdztools` and flash each
partition via `edl w`) was **not tested** in this session. The LUN mapping and
rawprogram XML come from the KDZ; verify both before writing. Treat the
"equivalent Linux path" as a plan, not a proven procedure.

## Verification limits

- `unlocked: yes` and `unlock_count: 1` were captured **before** the final KDZ
  reflash (`captures/getvar_now.txt`, 23:45). The post-reflash confirmation is
  the phone's Settings screen ("Bootloader is already unlocked"), reported by
  the user. No post-reflash `getvar` capture exists.
- The final flash mode was instructed as **Refurbish**, but the user's exact
  selection in the LGUP GUI was not captured. Do not treat the mode as
  instrumented.
- The phone boots; no system-level test beyond reaching the home screen and
  reading Settings was performed.

## LineageOS context (for the next step)

- Target build: `judyln` on LineageOS 22.2, supported models `LM-G710AWM`,
  `LM-G710EM`, `LM-G710EMW` (variant 1), and `LM-G710EAW` (variant 2, "G7+").
  Our `LM-G710EMW` is variant 1.
- Requirement: Android 10 stock firmware, ideally build `30d` or newer. We are
  on `30e`. Requirement met.
- Install method on the wiki is `dd` from a rooted system; with an unlocked
  bootloader the `fastboot flash boot <recovery boot.img>` route is the shorter
  equivalent once Magisk root exists.
- Known device quirk: no IMS support. VoLTE and VoWiFi do not work on LineageOS
  builds for this device. A Jio SIM (VoLTE-only) loses voice calls on that
  network; Airtel and Vi fall back to 2G/3G.
- Device integrity: Play Integrity fails; banking apps and tap-to-pay need
  DenyList-style tooling.

## Files to keep if archiving the session

In priority order:

1. `backups/` — the phone's own state, verified. This is the only thing you
   cannot re-download.
2. `firmware/G710EMW30e_00_0916.kdz` — the exact stock firmware that works.
3. `tools/linux/prog_ufs_firehose_Sdm845_lge.elf` — required for every EDL
   operation.
4. `images/eabl.img` and `images/frp-patched.img` — the unlock images.
5. `tools/windows/` — the Unlock845 release and the LGUP installers.
6. `MANIFEST.sha256` and `verify.sh` — proves all of the above intact.

---

## LineageOS 22.2 install — what actually worked (2026-10-23)

This section records the install path for judyln that succeeded on this phone.

### Do not flash the Lineage boot image to the boot slots

Direct writes of the Lineage `boot.img` to `boot_a`/`boot_b` (via EDL, verified
byte-exact, with Lineage's matching `vbmeta`/`dtbo` flashed too) made the LG
stock ABL refuse the OS. Each attempt produced the orange warning and then
fastboot. The slot attributes in the GPT degraded with each failed attempt
(boot_a `0x7f` -> `0x44`, boot_b `0x7b` -> `0x00`, i.e. priority and retry
counts burned down). Flashing the stock boot images back restored booting
immediately, so this is an ABL gate against the unverified boot image, not
damage.

### The install path that worked (the LineageOS wiki's `dd` method)

1. Restore full stock boot chain (`boot_a/b`, `dtbo_a/b`, `vbmeta_a/b`) from
   backups, zero `misc`, confirm stock Android boots.
2. Root stock Android with Magisk:
   - `adb install Magisk-v30.7.apk`
   - Push the stock boot image to `/sdcard/boot.img`
   - In the Magisk app: Install -> Select and Patch a File -> boot.img
     (keep "Preserve Force Encryption" and "Preserve AVB 2.0/dm-verity" on)
   - Pull `magisk_patched-*.img` and write it to `boot_a` and `boot_b` via
     EDL (read-back verified)
   - In Magisk Settings: Superuser access = "Apps and ADB". If a denied
     "Shell" entry exists under Superuser, delete it. Then `adb shell su -c id`
     returns `uid=0(root)`.
3. With root, write the Lineage recovery into both slots from the phone:
   ```sh
   adb push boot.img /sdcard/lineage-recovery.img          # Lineage boot.img
   adb shell su -c 'dd if=/sdcard/lineage-recovery.img of=/dev/block/bootdevice/by-name/boot_a'
   adb shell su -c 'dd if=/sdcard/lineage-recovery.img of=/dev/block/bootdevice/by-name/boot_b'
   adb reboot recovery
   ```
4. In Lineage recovery: `Advanced -> Enable ADB` (authorizes adb in recovery;
   the recovery exposes product `lineage_judyln`).
5. `Apply update -> Apply from ADB`, then on the host:
   ```sh
   adb sideload copy-partitions-20220613-signed.zip
   ```
   Then `Advanced -> Reboot to recovery`, then `Factory reset -> Format data`.
6. `Apply update -> Apply from ADB` again, then:
   ```sh
   adb sideload lineage-22.2-20261018-nightly-judyln-signed.zip
   ```
   The host may stop at about 47% with `adb: failed to read command: Success`.
   That is normal. The phone shows Step 1/2 and Step 2/2.
7. Answer **Yes** to "reboot to recovery now" so add-ons can install, then
   sideload MindTheGapps. Recovery reports
   `Signature verification failed` (error 21) because add-ons are not signed
   with LineageOS keys. Choose **install anyway**.
8. `Reboot system now`. First boot takes several minutes.

### Result

- `ro.lineage.version` = `22.2-20261018-NIGHTLY-judyln`, Android 15,
  security patch 2026-10-01, active slot `_b`, `verifiedbootstate` = orange.
- MindTheGapps 15.0.0 arm64 (20260915) installed.
- The Magisk root belongs to the stock installation and does not survive the
  LineageOS system replacement. Re-root Lineage separately if wanted.

### Recovery adb notes

- Recovery menu adbd is strict: the first connection shows `unauthorized` with
  no prompt. `Advanced -> Enable ADB` restarts adbd and authorizes the host.
- Sideload mode (`Apply from ADB`) accepts the transfer without the menu's
  authorization state.
