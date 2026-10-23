#!/bin/bash
# EDL watchdog: polls lsusb at high frequency for 05c6:9008 (Qualcomm QDL/Sahara mode)
usage="Usage: edl_watch.sh [timeout_seconds]  (default 120)"
TIMEOUT=${1:-120}
START=$(date +%s)
FLAG=0

notify-stop() {
  command -v notify-send >/dev/null && notify-send -u critical "EDL DETECTED" "Phone entered 05c6:9008.\nSTOP tapping Vol+ now!\nDo not touch the phone or cable." 2>/dev/null
}
notify-lost() {
  command -v notify-send >/dev/null && notify-send -u critical "EDL MODE LOST" "Device disappeared — phone left EDL mode." 2>/dev/null
}
notify-end() {
  command -v notify-send >/dev/null && notify-send -u normal "Watchdog ended" "No EDL mode detected within ${TIMEOUT}s." 2>/dev/null
}

beep() {
  command -v paplay >/dev/null && paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga 2>/dev/null \
    || command -v losetup >/dev/null && command -v paplay >/dev/null
}

echo "[$(date +%T.%3N)] watchdog started — polling lsusb every 50ms for 05c6:9008, timeout ${TIMEOUT}s"
while :; do
  NOW=$(date +%s)
  ELAPSED=$((NOW - START))
  [ "$ELAPSED" -ge "$TIMEOUT" ] && break
  # re-check: have we seen 05c6:9008 in the last 200ms?
  FOUND=$(lsusb 2>/dev/null | grep -c "05c6:9008")
  if [ "$FOUND" -ge 1 ] && [ "$FLAG" -eq 0 ]; then
    FLAG=1
    echo "[$(date +%T.%3N)] *** EDL MODE DETECTED (05c6:9008) — STOP TAPPING Vol+ ***"
    echo "[$(date +%T.%3N)] *** Phone looks dead right now. That is success. ***"
    notify-stop
    beep
    # keep watching: has the device stayed in EDL?
    STABLE_START=$NOW
    while :; do
      sleep 2
      CNT=$(lsusb 2>/dev/null | grep -c "05c6:9008")
      if [ "$CNT" -eq 0 ]; then
        echo "[$(date +%T.%3N)] !!! EDL mode LOST — phone left the mode, retry later"
        notify-lost
        exit 1
      fi
      echo "[$(date +%T.%3N)] EDL still present - stable for $(( $(date +%s) - STABLE_START ))s"
    done
  fi
  sleep 0.05
done

if [ "$FLAG" -eq 0 ]; then
  echo "[$(date +%T.%3N)] watchdog timed out after ${TIMEOUT}s, no 05c6:9008 detected"
  notify-end
  exit 1
fi
