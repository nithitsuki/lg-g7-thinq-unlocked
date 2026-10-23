#!/usr/bin/env python3
"""Qualcomm DIAG probe over vendor interface (ff/ff/48).
Passive, read-only: version request (byte 0x00) and echo of responses."""
import sys, time
sys.path.insert(0, "/tmp/opencode/lglaf-nak3d-gh")
import usb.core, usb.util

def wait(tries=30):
    import sys, time
    for i in range(tries):
        d = usb.core.find(idVendor=0x1004)
        if d is not None and d.idProduct == 0x633a:
            return d
        time.sleep(2)
    raise SystemExit("0x633a never appeared - phone not in that mode")

dev = wait()
print("0x633a present")

cfg = None
intf = None
for c in dev:
    for i in c:
        if i.bInterfaceClass == 255 and i.bInterfaceProtocol == 48:
            intf = i
            break
if intf is None:
    raise SystemExit("no ff/ff/48 interface")
print("if", intf.bInterfaceNumber, "class", hex(intf.bInterfaceClass), "proto", intf.bInterfaceProtocol)
for ep in intf:
    if usb.util.endpoint_direction(ep.bEndpointAddress) == usb.util.ENDPOINT_IN:
        ep_in = ep.bEndpointAddress
    else:
        ep_out = ep.bEndpointAddress
print("endpoints in=%s out=%s" % (hex(ep_in), hex(ep_out)))
try:
    if dev.is_kernel_driver_active(intf.bInterfaceNumber):
        dev.detach_kernel_driver(intf.bInterfaceNumber)
        print("detached kernel driver")
except Exception as e:
    print("detach note:", e)
usb.util.claim_interface(dev, intf.bInterfaceNumber)

def xfer(payload, rlen=64, timeout=3000):
    try:
        n = dev.write(ep_out, payload, timeout=timeout)
        print("wrote %d bytes: %s" % (n, payload.hex()))
    except usb.core.USBError as e:
        print("write error:", e); return
    try:
        data = dev.read(ep_in, rlen, timeout=timeout)
        print("read  %d bytes: %r" % (len(data), bytes(data)))
    except usb.core.USBError as e:
        print("read error:", e)

print("== passive read first (see if device pushes anything) ==")
try:
    data = dev.read(ep_in, 64, timeout=3000)
    print("passive read:", bytes(data))
except usb.core.USBError as e:
    print("passive read error:", e)

print("== DIAG_VERNO (single byte 0x00) ==")
xfer(b"\x00")

print("== DIAG 'hook' (0x73) ==")
xfer(b"\x73")

print("== subsys preamble style: 0x4B 0x03 0x00 (menu item) ==")
xfer(bytes([0x4B, 0x03, 0x00]))
print("done")
