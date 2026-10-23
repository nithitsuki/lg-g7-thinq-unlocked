# Device facts — LG G7 ThinQ LM-G710EMW

## Identity

| Field | Value |
|-------|-------|
| Model | LM-G710EMW (Asia variant, dual SIM) |
| Codename | judyln (LineageOS codename; `product.judyln_lao_com` in getprop) |
| Serial number | LMG710EMWa65939f9 |
| Region | IND (India) |
| Carrier SKU | GLOBAL (`ro.boot.vendor.lge.sku_carrier`) |
| SoC | Qualcomm SDM845 (Snapdragon 845), UFS storage (SK Hynix `H28S7Q302BMR`) |
| Hardware SKU | `dfgn` (`ro.boot.product.hardware.sku`) |

## Firmware state seen before the unlock session

| Field | Value |
|-------|-------|
| OS | Android 10 (QKQ1.191222.002) |
| Build | `lge/judyln_lao_com/judyln:10/QKQ1.191222.002/2125922039237:user/release-keys` |
| Build date | Thu Sep 16 18:32:45 IST 2021 |
| Security patch | 2020-12-01 |
| Reported SW version | V30w-IND-XX (as seen in Settings) |
| Previously installed SW | `G710EMW30e` (`persist.product.lge.radio.prevswversion`) |
| Baseband | MPSS.AT.4.0.c2.9-00110-SDM845_GEN_PACK-1.332992.1.337594.3 |

Note: no public archive holds the exact `30w` KDZ for this model and region.
The India archive tops out at `G710EMW30e`. This machine backs up that gap:
its flashes used `G710EMW30e`, a build the phone had previously run.

## Boot and mode-entry behavior observed

- `adb reboot bootloader` (from stock Android, bootloader locked)
  lands in genuine fastboot mode, PID `18d1:d00d`. getvar works; all
  mutating commands hang or fail. Documented in NOTES.md.
- `adb reboot edl` and `adb reboot download` do not reach EDL on this unit;
  they land in the transient PID `1004:633a` state, with no on-screen
  download-mode UI.
- EDL (PID `05c6:9008`) entry works with the button combo:
  power off, then hold Volume Down and Power, and tap Volume Up rapidly in
  the black gap between "off" and "LG logo". The window lasts only a few
  seconds.

## Unlock state after the session

| Field | Value |
|-------|-------|
| `fastboot getvar unlocked` | yes (persistent across reboots and ABL restores) |
| `unlock_count` | 1 |
| `lock_count` | 0 |
| `devinfo` | original dump is `ANDROID-BOOT!`, version bytes `01 01`, then zeros. A one-byte `is_unlocked=1` write was made and verified; it had no boot effect and **no revert write exists in the log**. The post-reflash state was not read back. |
| Settings view | Developer options shows "Bootloader is already unlocked"; the OEM-unlock toggle is greyed out |
| Boot visual | orange (unlocked) boot warning every boot |

The unlock state survives restoring both `abl` slots and the stock FRP. It also
survived the final KDZ reflash (mode instructed as Refurbish; selection not captured): the phone's Settings screen reports
"Bootloader is already unlocked" afterwards. That post-reflash state was
confirmed on the device, not by a new `fastboot getvar` capture. The state is
therefore outside the ABL partitions (most likely the RPMB or a fuse-backed
secure store).

The final reflash used `30e` while the phone was running `V30w`, per the user.
This is a downgrade. The captured `ro.vendor.lge.swversion` says 30e, so the
vendor field may not reflect the full build; the Settings value is the user's
evidence. It worked here; LG anti-rollback state makes it a risk on another
unit. See the firmware section of `NOTES.md`.

## Full property dump

`getprop-full.txt` in this directory is the complete `adb shell getprop`
capture taken before the unlock session (45 KB). `captures/g7_props.txt`
holds the identical copy.

## Final state — LineageOS 22.2 (23 October 2026)

| Field | Value |
|-------|-------|
| `ro.lineage.version` | 22.2-20261018-NIGHTLY-judyln |
| `ro.lineage.device` | judyln |
| Android version | 15 (SDK 35) |
| Security patch | 2026-10-01 |
| Active slot | `_b` |
| `ro.boot.verifiedbootstate` | orange (unlocked) |
| Google apps | MindTheGapps 15.0.0 arm64, 20260915 |

The bootloader unlock is unchanged. Magisk root belonged to the stock
installation and does not carry over to the LineageOS system.
