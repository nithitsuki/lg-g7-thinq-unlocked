# Device — LG G7 ThinQ (LM-G710EMW)

| Field | Value |
|---|---|
| Model | LM-G710EMW (Asia, dual SIM) |
| Codename | judyln (`judyln_lao_com`) |
| Serial | redacted in this repository |
| Region / SKU | IND (India) / GLOBAL |
| SoC | Snapdragon 845 (SDM845), UFS storage |
| Screen | 6.1 in, 3120×1440 |

## Firmware before the unlock

| Field | Value |
|---|---|
| Android | 10 |
| Build | `lqe/judyln_lao_com/judyln:10/QKQ1.191222.002/2125922039237:user/release-keys` |
| Build date | 2021-09-16 |
| Security patch | 2020-12-01 |
| Software version (Settings) | V30w-IND-XX |
| Previous version on device | `G710EMW30e` |
| Baseband | MPSS.AT.4.0.c2.9-00110-SDM845_GEN_PACK-1.332992.1.337594.3 |

The exact `30w` KDZ is not in any public archive. The India archive stops at
`30e`, which this phone had previously run. All firmware flashes in this repo
use `30e`.

## Modes

| PID | Mode |
|---|---|
| `1004:633e` | Android, MTP/ADB |
| `1004:633a` | transient state after `adb reboot edl` / `adb reboot download`; no download-mode UI |
| `18d1:d00d` | fastboot (reachable with `adb reboot bootloader`) |
| `05c6:9008` | EDL; button combo only |

## Unlock state

| Field | Value |
|---|---|
| `fastboot getvar unlocked` | `yes` |
| `unlock_count` | 1 |
| `devinfo` | `ANDROID-BOOT!` + zeros; a one-byte `is_unlocked` test write had no effect and was left as is |
| Settings, while on stock | "Bootloader is already unlocked", OEM-unlock toggle greyed out |

The state survives both ABL slots being reflashed and a full KDZ Refurbish.

## After the install

| Field | Value |
|---|---|
| ROM | LineageOS `22.2-20261018-NIGHTLY-judyln` |
| Android | 15 (SDK 35) |
| Security patch | 2026-10-01 |
| Active slot | `_b` |
| `ro.boot.verifiedbootstate` | `orange` |
| Gapps | MindTheGapps 15.0.0 arm64 (20260915) |

`getprop-full.txt` is the complete property dump from before the unlock.
