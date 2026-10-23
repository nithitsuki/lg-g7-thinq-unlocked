# Preservation and mirrors

The method in this repo is reproducible only while these files exist:

| File | Why it matters | Mirror |
|------|----------------|--------|
| `G710EMW30e_00_0916.kdz` | The stock Android 10 firmware that makes the phone bootable again. Not archived by LG any more; the community mirror sites may vanish. | archive.org item (see below); original mirror: `lg-firmwares.com/downloads-file/25952` |
| `prog_ufs_firehose_Sdm845_lge.elf` | The leaked LG SDM845 UFS firehose loader. Every EDL read and write needs it. | in this repo (`tools/linux/`) and archive.org |
| `eabl.img` | The unsigned V35 engineering ABL that unlocks the phone. | in this repo (`images/`) and archive.org |
| `frp-patched.img` | The patched FRP image that enables the OEM-unlock bit. | in this repo (`images/`) and archive.org |
| `Unlock845.zip` | The toolkit that bundles the above and scripts the Windows path. | archive.org and the GitHub release; upstream: `github.com/log1cs/Unlock845` |
| LGUP installers | Needed for the Refurbish reflash that repairs the boot state. | archive.org and the GitHub release |
| Firmware partition dumps | Byte-exact copies of `abl`, `boot`, `dtbo`, `laf`, `vbmeta` from this phone, all SHA256-verified. Useful if the KDZ vanishes. | archive.org |
| LineageOS 22.2 ROM, Gapps | Regenerated upstream; re-downloadable. Only the hashes matter here. | `download.lineageos.org/devices/judyln`, `github.com/MindTheGapps` |

## Privacy note

The archive.org bundle contains **firmware partitions only**. It excludes
`frp.bin`, `mpt.bin`, `oem_a.bin`, `oem_b.bin`, and the `devinfo` variants,
because those carry device-specific and account-adjacent state. They stay
local, or in a private repository. Their hashes are still recorded in
`MANIFEST.sha256`.

## archive.org item

Identifier: `lg-g7-thinq-emw-unlock-archive-2026`

```
https://archive.org/details/lg-g7-thinq-emw-unlock-archive-2026
```

Upload it once with the script in `tools/linux/scripts/upload-to-archive-org.sh`.
The script needs the `ia` CLI and an archive.org account (free):

```bash
uv tool install internetarchive
ia configure          # username + password, or S3 keys
tools/linux/scripts/upload-to-archive-org.sh
```

## GitHub release

The repository release `v1.0` carries the Windows payloads that are too large
for a lean clone: `Unlock845.zip` and the two LGUP installers. The three small
crown-jewel images are committed directly, so a plain clone is enough to
reproduce the unlock.

## Integrity

`MANIFEST.sha256` covers every file in the git tree. `SHA256SUMS.txt` in
`backups/` covers the raw dumps. The archive.org item carries the same files as
the dumps tarball plus the KDZ; compare its extracted contents against
`MANIFEST.sha256` and `backups/SHA256SUMS.txt`.
