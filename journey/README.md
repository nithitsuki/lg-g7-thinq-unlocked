# Chronology

Times in IST. The long version is `../TIMELINE.md`.

**22 Oct, evening.** Stock G7 on Android 10, locked. LG's unlock portal has
been closed since 2021, so the only route is the leaked firehose and the V35
engineering ABL.

**22 Oct, 21:00–23:00.** First EDL sessions. Partition map captured, all
boot-critical partitions backed up. Engineering ABL written to both slots.
`oem unlock` replied `unknown command`, then silence, then
`Set device unlocked! failed: 00000050`. Eventually `unlocked: yes` appeared
and stuck.

**22 Oct, 23:00–23:30.** Restored the stock ABL and FRP. The phone now booted
straight to fastboot every time. Searched for the cause: `misc` boot block,
`devinfo`, `fsc`, `limits`, `logfs`, `logdump`. None of them explained it.
`fastboot getvar` showed both slots marked unbootable.

**23 Oct, 00:30–01:30.** LGUP Refurbish with `G710EMW30e` on a Windows PC.
The phone booted stock Android again, unlocked, with the OEM-unlock toggle
greyed out.

**23 Oct, 07:20–08:20.** LineageOS.

- Downloaded the 22.2 nightly and its `boot.img`.
- Tried the direct route: `boot.img` plus matching `vbmeta`/`dtbo` written to
  both slots over EDL. Refused — orange warning, then fastboot, and the slot
  counters kept dropping. Restored the stock images to get Android back.
- Rooted stock with Magisk (patched boot image written over EDL).
- `dd`-ed the Lineage recovery into both boot slots from the rooted system,
  `adb reboot recovery`.
- Sideloaded `copy-partitions`, formatted data, sideloaded LineageOS and
  MindTheGapps.
- Booted LineageOS. Verified over ADB: `ro.lineage.version`
  `22.2-20261018-NIGHTLY-judyln`, slot `_b`, boot state `orange`.

The method and the traps are in `../NOTES.md`.
