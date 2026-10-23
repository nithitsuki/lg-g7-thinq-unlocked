# Preservation

LineageOS will keep existing. The LG files may not. These are the files this
method depends on:

| File | Why it matters | Where |
|---|---|---|
| `G710EMW30e_00_0916.kdz` | Stock Android 10 firmware that makes the phone bootable again. The community mirrors may disappear. | archive.org `lg-g7-thinq-emw-unlock-archive-2026` |
| `prog_ufs_firehose_Sdm845_lge.elf` | Leaked LG SDM845 UFS loader. Required for every EDL read/write. | this repo; archive.org |
| `eabl.img` | Unsigned V35 engineering ABL that unlocks the phone. | this repo; archive.org |
| `frp-patched.img` | Patched FRP with the OEM-unlock bit. | this repo; archive.org |
| `Unlock845.zip` | Toolkit that bundles the files above plus the Windows scripts. | release `v1.0`; archive.org |
| LGUP installers | Needed for the Refurbish reflash. | release `v1.0`; archive.org |
| Firmware dumps | `abl`, `boot`, `dtbo`, `laf`, `vbmeta` from this phone. Fallback if the KDZ is lost. | archive.org |
| LineageOS, Gapps | Rebuilt upstream. Only the hashes matter. | `download.lineageos.org`, `github.com/MindTheGapps` |

## Not published

`frp.bin`, `mpt.bin`, `oem_a.bin`, `oem_b.bin`, and the `devinfo` dumps carry
device-specific state and stay local. Their hashes are in
`MANIFEST.local.sha256`.

## Upload

```bash
uv tool install internetarchive
ia configure
tools/linux/scripts/upload-to-archive-org.sh
```

The script uploads the KDZ, the Unlock845 zip, both LGUP installers, a tarball
of the firmware-only dumps, and a docs tarball. About 4.2 GB total.

## Check

```bash
./verify.sh                # git tree
./verify.sh --with-local   # plus the local payloads
```
