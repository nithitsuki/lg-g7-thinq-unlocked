#!/bin/bash
# retry wrapper: keeps re-entering download mode until a LAF run succeeds
# usage: lafrun.sh [lglaf.py args...]
ATTEMPTS=${ATTEMPTS:-5}
for a in $(seq 1 $ATTEMPTS); do
  if ! lsusb | grep -q "1004:633a"; then
    adb devices >/dev/null
    adb reboot download >/dev/null 2>&1 || true
    sleep 6
  fi
  if lsusb | grep -q "1004:633a"; then
    echo "--- LAF attempt $a ---" >&2
    if sudo PYTHONPATH=/tmp/opencode/lglaf-nak3d-gh /tmp/opencode/venv/bin/python3 /tmp/opencode/lglaf-nak3d-gh/lglaf.py "$@"; then
      exit 0
    fi
  fi
  sleep 4
done
echo "could not get LAF session after $ATTEMPTS attempts" >&2
exit 1
