# Journey — the unlock session, in order

Times are IST on 2026-10-22 and 2026-10-23. This is the short technical
chronology. The full story, with quotes and the human cost, is in
`../TIMELINE.md`.

The goal: unlock the bootloader of an LG G7 ThinQ LM-G710EMW on stock Android
10, from an Arch Linux machine, without LG's discontinued official service.

## 1. Research (20:01–20:07)

- No official unlock remains. LG's `unlock.bin` portal closed at the end of
  2021. LineageOS marks `judyln` as `is_unlockable: false`.
- The working method is the leaked LG SDM845 firehose loader plus an unsigned
  Oreo engineering ABL from a V35. The maintained tool is `log1cs/Unlock845`.
- The phone is LM-G710EMW, Android 10, V30w-IND-XX. The India archive stops at
  `30e`, which the phone previously ran (`persist.product.lge.radio.prevswversion`).

## 2. Linux first contact (20:18–21:04)

- ADB authorized. Full getprop captured (`captures/g7_props.txt`).
- `adb reboot edl` did **not** reach EDL. It produced PID `1004:633a`, a
  transient composite device with an AT serial port and a vendor interface
  `ff/ff/48` — most likely Qualcomm DIAG, not LAF and not EDL.
- `adb reboot download` produced the same state. The phone left it on its own
  after about a minute.
- Three `lglaf` implementations were tried. The interface matcher was relaxed,
  the KILO challenge-response path was enabled, `pycryptodome` was installed.
  No LAF read or write succeeded. An invalid frame reboots this phone, which is
  why the early attempts kept returning to the home screen.
- `adb reboot bootloader` did work: genuine fastboot, PID `18d1:d00d`, on a
  locked stock Android 10 build.

## 3. The stock fastboot gate (21:04–21:28)

- `fastboot getvar all` worked and reported `unlocked:no`, `unlock_count:0`,
  `current-slot:a`.
- `fastboot oem unlock` hung with no reply. The engineering ABL later returned
  `unknown command` or `GetVar Variable Not found`; those are not stock-ABL
  behaviors.
- `fastboot boot` and all flashing verbs failed or hung.
- LG's official path (`fastboot flash unlock unlock.bin`) is dead: the file is
  per-device, signed, and no longer issued.

## 4. EDL, at last (21:32)

- The working entry is a timing trick: hold Vol- and Power until the screen
  goes black, then keep Vol- held and tap Vol+ rapidly during the black gap.
  From the fastboot menu, select **Restart bootloader** first; Vol- + Power
  does nothing on that screen.
- `tools/linux/scripts/edl_watch.sh` polls `lsusb` every 50 ms for `05c6:9008`
  and fires a desktop notification plus an alarm. It caught the first EDL
  session at 21:32:23.
- `edl printgpt` mapped seven LUNs. `frp` is on LUN 6. `abl`, `boot`, `dtbo`,
  `laf`, `vbmeta`, `devinfo`, `misc`, `logfs`, `logdump` are on LUN 4.
  `captures/gpt_full.txt` is the full GPT dump.
- Twelve partitions were read and hashed before any write. All 12 verified.

## 5. Writes performed

Every EDL partition write used `prog_ufs_firehose_Sdm845_lge.elf` with
`--memory=ufs`, and every one was followed by a read-back and a SHA-256
comparison. The `edl e` erases were checked by reading zeros. The final LGUP
KDZ flash was not instrumented.

In chronological order:

1. 21:39 — `eabl.img` → `abl_a` (LUN 4), verified `c2b20241…`. The phone booted
   slot B, so the stock bootloader stayed active.
2. 21:57 — `eabl.img` → `abl_b` (LUN 4), verified. Both slots then ran the
   engineering ABL.
3. 22:09 — `frp-patched.img` → `frp` (LUN 6), verified `11ec9af9…`.
4. 22:37–22:40 — `abl_a`, `abl_b`, `frp` restored from the pre-write backups,
   all verified against the originals.
5. 22:57 — `userdata` erased with `edl e` (UFS TRIM, 46.66 GiB, seconds). The
   phone still booted to fastboot.
6. 23:07 — `misc` erased (LUN 4) to clear a boot control block. No change.
7. 23:31 — the captured `misc` BCB restored byte-for-byte (`a0cb5511…`). No
   change.
8. 23:41 — `devinfo_unlocked.bin` → `devinfo` (LUN 4): one byte at `0x10`,
   `00`→`01`. Read-back matched. No effect on boot. No revert write appears in
   the session.

## 6. What the engineering ABL did

- It identifies as product `LM-V350EMW`, carrier `judyp_lao_com`, with this
  phone's serial appended (`LMV350EMWa65939f9`).
- The OS boot shows the Red Case (`g.co/ABH`) and falls back to fastboot. This
  is Unlock845's documented behavior for an unsigned prototype ABL.
- `fastboot oem unlock` cycles through three observed states:
  `unknown command`, silent hang then `Set device unlocked! failed: 00000050`,
  and finally `unlocked: yes` on a later fresh session.
- The command leaves the ABL's fastboot channel answering inconsistently:
  `getvar` may go silent, then a later `reboot-bootloader` returns OKAY.
- `fastboot flash` hangs on this ABL, including for `frp`. All writes were
  therefore done over EDL.

## 7. How the unlock actually landed

We tried the community remedy: have `oem unlock` be the **first packet** of a
fresh ABL session. A background watcher waited for `18d1:d00d`, then fired the
command while the phone rebooted manually. The watcher's command did not reach
the device (host-side write error). The following `getvar` reported
`unlocked: yes`. The state had already landed from an earlier attempt, so the
first-packet pattern was **not demonstrated**.

That state survived restoring both stock ABLs and the stock FRP. It was then
confirmed on the stock bootloader (`LMG710EMWa65939f9`): `unlocked: yes`.

## 8. The boot loop (22:45–23:58)

- After the restore, every boot went: LG logo or orange warning → fastboot.
  Android never started.
- `userdata` and `misc` were cleaned. The BCB was erased, then restored. No
  change. The writer of the BCB is unknown; the pre-unlock
  `bootreason: reboot,factory_reset` makes an earlier factory reset plausible.
- `mpt`, `sec`, `oem_a/b`, `limits`, `fsc`, `logfs`, `logdump` were read. The
  data partitions held filesystems; the logs were empty (64 MiB of zeros, an
  empty FAT12 volume from 2016). No boot flag was found.
- The `devinfo` unlock byte did nothing.
- A full `getvar all` (221 lines) exposed the cause:
  `slot-unbootable:a:yes` and `slot-unbootable:b:yes`, with
  `slot-retry-count:a:6`, `slot-retry-count:b:7`, `current-slot:b`.
- `fastboot set_active` was refused ("Device does not support slots").
  `fastboot --set-active=a` was accepted on a fresh session but did not fix the
  boot.
- `fastboot boot backup/boot_a.bin` stalled at `Sending 'boot.img'`.
- The bootloader body is encrypted, so static analysis could not explain the
  decision.

## 9. Windows and LGUP (00:16–01:04)

- SSH to a Windows 10 machine (`192.168.0.125`). The phone enumerated in
  fastboot with a missing driver; the LG and Qualcomm drivers were installed.
- The KDZ (`G710EMW30e_00_0916.kdz`, 3.7 GB) was behind a reCAPTCHA on
  lgrom.com. The direct POST returned `{"code":604}`. The user downloaded it in
  Firefox, then it was copied to Windows over `scp`.
- `LGUP_Cmd.exe` never worked. Failures, in order: `Error!!! [SW_PATH] is
  null` with every argument shape; the MSI install added the LGUP framework but
  no `LGUP_Cmd.exe`; after copying the binary in, the check failed on
  `C:\` free space; after deleting the duplicate KDZ, `SW_PATH is null`
  returned.
- The fix was the LGUP **GUI**, operated by the user: COM6, the KDZ on
  `E:\g7work`, Start. The instructions specified **Refurbish**; the exact GUI
  selection was not captured.
- The flash completed. The phone rebooted with the orange unlocked warning, ran
  an erase screen, and booted stock Android 10.

## 10. Final state

- Boots stock Android 10 (`G710EMW30e`, India).
- Bootloader unlocked: `unlocked: yes` and `unlock_count: 1` before the
  reflash; "Bootloader is already unlocked" in Settings after it.
- The final reflash was a **downgrade** from V30w to 30e, as reported by the
  user. The captured `ro.vendor.lge.swversion` says 30e, so the vendor image
  may not reflect the full build. It succeeded, but LG anti-rollback counters
  exist and this is not guaranteed on another unit.
- All 12 original partition backups are preserved and verified. Every EDL
  write has a read-back in `verification-readbacks/`. The final KDZ flash does
  not.

## 11. If repeating this

1. Back up all 12 partitions first. Verify the hashes.
2. Do not trust fastboot for anything except `getvar` and `reboot`. Often it
   accepts one command per session; the behavior varies.
3. Prefer EDL for every write.
4. Expect the engineering ABL to answer inconsistently after `oem unlock`.
5. Read `NOTES.md` before you start. It records the details the public guides
   omit.
