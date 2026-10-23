# Fixes left

Status as of 23 Oct 2026, 02:30 IST. The repository is **not committed**; the
working tree holds the narrative and the corrections.

## Landed

- `TIMELINE.md` — 46 time-marked chapters, 20:01 to 01:28, with quotes checked
  against all 57 user messages.
- All 36 reviewer findings addressed: chronology, SW_PATH chain, `gpt_full`
  mislabel, 0x50 attribution, devinfo wording, slot causation, misc
  attribution, first-packet claim, sizes, current-slot, write order, KDZ
  provenance, clock times, Refurbish caveat, and the manifest.
- `MANIFEST.sha256` regenerated over 284 files, excluding every `.git/`
  directory and itself. `./verify.sh` passes.

## Still open (none blocking)

1. **Version record.** The user reports V30w → 30e. The captured
   `ro.vendor.lge.swversion` says 30e. Both are now recorded; no capture of the
   Settings value exists. Do not resolve this without a fresh read.
2. **Post-flash proof.** The unlock after the KDZ is confirmed by Settings, not
   by a `getvar` capture. `getvar_now.txt` is pre-flash (23:45).
3. **Refurbish mode.** Instructed, not instrumented. The GUI selection was not
   captured.
4. **The `misc` writer.** Unknown. The BCB was not the boot gate; an earlier
   factory reset is the plausible source.
5. **`limits` decoding.** 4 KiB, 16 nonzero bytes. Called an anti-rollback
   candidate, not a decoded structure.
6. **Independent re-review.** The 36 findings were fixed by hand after the
   reviewer finished. No second reviewer pass has run on the corrected tree.
7. **Commit.** Nothing is staged or committed. Review `git diff` first.

## Verify

```bash
cd ~/Projects/lg-g7-thinq-unlocked
./verify.sh        # prints "manifest OK"
git status --short
```
