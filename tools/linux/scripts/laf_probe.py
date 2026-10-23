#!/usr/bin/env python3
"""Probe LG Download Mode (LAF) on judyln: wait for device, try HELLO/OPEN, report."""
import sys, time, struct
sys.path.insert(0, "/tmp/opencode/lglaf")
import usb.core, usb.util
import lglaf

def wait(tries=30):
    for i in range(tries):
        d = usb.core.find(idVendor=0x1004, idProduct=0x633a)
        if d:
            return d
        time.sleep(2)
    raise SystemExit("LAF device never appeared")

d = wait()
print("device present")
comm = lglaf.USBCommunication()
print("attached")

def show(label, header):
    if header is None:
        print(f"{label}: NO RESPONSE")
        return
    cmd = header[0:4]
    print(f"{label}: cmd={cmd!r} args={tuple(lglaf.read_uint32(header, o) for o in (4,8,12))} len={lglaf.read_uint32(header,0x14)}")
    return lglaf.read_uint32(header, 4)

# 1) HELO
try:
    h, b = comm.call(lglaf.make_request(b'HELO', body=b'LGDOWNLOADMODE'))
    show("HELO", h)
except lglaf.USBError as e:
    print("HELO usb error:", e)
    raise SystemExit(1)

# 2) OPEN whole disk
try:
    h, b = comm.call(lglaf.make_request(b'OPEN', body=b'\0'))
    fd = show("OPEN", h)
except lglaf.USBError as e:
    print("OPEN usb error:", e)
    raise SystemExit(2)

# 3) READ first 512 bytes of the disk (MBR/GPT header region is at LBA1; READ LBA0 = MBR sig 55AA)
try:
    cmd = lglaf.make_request(b'READ', args=[fd, 0, 512])
    h2, b2 = comm.call(cmd)
    show("READ", h2)
    print("body len:", len(b2))
    print("first 16 bytes:", b2[:16].hex())
except lglaf.USBError as e:
    print("READ usb error:", e)

print("ORIGINAL", sep="")
