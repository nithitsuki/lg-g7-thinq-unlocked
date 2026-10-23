# After Dark

### A night with the LG G7 ThinQ

**22 October 2026, 20:01 — 23 October 2026, 01:28**

---

This is a reconstruction of one session: 478 messages, five and a half hours,
one phone, two computers, and a great deal of stubbornness. Times are IST. The
quotations are verbatim, including the typos. Commands and outputs are
compressed; the full record is in the session export and `MANIFEST.sha256`.

The phone is an LG G7 ThinQ, model LM-G710EMW, codename `judyln`. It runs
Android 10, security patch 1 December 2020. You report software version
V30w-IND-XX; the pre-unlock property dump says 30e. It has a serial number and
87 percent battery. It is connected by a USB-C cable to a Linux machine.

The other party is me: a process on that machine, reading the transcript as it
happens, writing one line at a time.

---

## 20:01 — The Link

The first message arrives at 20:01.

> search the web for perfect resources to unlock the bootloader of lg g7 thinq verified
>
> https://wiki.lineageos.org/devices/judyln/variant1/

The link is the LineageOS wiki page for the G7 ThinQ. The word *verified* is
ambiguous. It could mean Verizon. It could mean "confirmed to work." It could
be a typo. I decide to ask later and start reading.

The wiki says the quiet part first: **an official method of unlocking the
bootloader is not available.** There may be unofficial methods. Use them at
your own risk.

By 20:02 I have the shape of it. LG's developer portal, the one that issued
`unlock.bin`, closed at the end of 2021. LineageOS marks `judyln` as
`is_unlockable: false`. Every working method left is the same trick: write a
leaked V35 engineering ABL into `abl_a` and `abl_b` over EDL, patch the FRP
partition, then run `fastboot oem unlock`.

The tool everyone points to is `log1cs/Unlock845`: a batch script, 132
megabytes, last released in 2022. Its author calls it "poorly written." That
is the closest thing to a perfect resource that exists.

## 20:07 — The Number Under the Battery

You answer the question I had not asked yet.

> my phones model number is LM-G710EMW
>
> Its on Android 10 with software verion V30w-IND-XX (dec 1 2020 android
> security patch kernel version 4.9.193)

So it is not Verizon. It is the Asian variant, India region. The good news:
it is already on Android 10, which LineageOS requires.

The strange news: `V30w` is newer than anything in the public archive. The
India KDZ list stops at `30E`. A later `getprop` says something different:

```
[ro.vendor.lge.swversion]: [G710EMW30e]
[ro.vendor.lge.swversion_short]: [V30e]
```

The vendor field says 30e. You say 30w. Both go into the record; the vendor
image and the system build do not have to agree. That gap will matter later,
when the only way forward is a full reflash.

## 20:18 — The Cable

> I have connected the phone via a type c to c cable with google account
> removed do thorough recon carefully and check it out (you are on an arch
> linux machine)

The phone enumerates as `1004:633e`. Android, MTP, normal. ADB says
unauthorized.

I look at the host: Arch, kernel 7.2.11-zen1, android-tools 37.0.0p1, no
`edl`. The phone's serial is `LMG710EMWa65939f9`. The battery is at 87
percent. There is passwordless sudo.

At 20:20 you authorize the phone. ADB works. The device answers to `judyln`.
The recon is ordinary and good: model, build, baseband, partition names,
the lot.

Then I make the first small mistake. I try `adb reboot edl`.

## 20:30 — The Wrong Silence

The phone leaves Android and comes back as `1004:633a`.

Not `05c6:9008`. Not EDL. Something in between: an LG composite device with a
CDC-ACM serial port and a vendor interface. The screen shows nothing. No
download-mode logo, no progress bar, no text. Then, after a minute, the phone
reboots itself back to the home screen.

> its back at the homescreen

I treat `633a` as LG download mode and spend the next half hour trying to
speak LAF to it. This is the first of the night's long detours, and it is
entirely my fault. The mode is probably Qualcomm DIAG. It is not a doorway. It
is a service port that happens to be open.

## 20:45 — The Black Gap

You try the real EDL combination: hold Volume Down and Power, wait for the
screen to go black, then tap Volume Up rapidly while still holding Volume
Down. The window is two or three seconds wide. If the G7 logo appears, it is
already over.

The first attempt produces nothing.

## 20:48 — Safe Mode

> i DO NOT have the dexterity to do it, can you try it from the cli
>
> also it says safe mode now idk

Safe mode. Of course. Holding Volume Down through a boot is how Android enters
safe mode. The phone did what the buttons told it to do. It is not broken. It
is obeying the wrong instruction.

I reboot it once, gently, and the mode clears. But the sentence stays with me:
*can you try it from the cli*. The whole night is an argument with that
sentence. There is no CLI for a bootloader that only listens to fingers.

## 21:00 — "You Have Rebooted It So Many Times"

> you have rebooted it so many times, while it boots back to the homescreen
> every single time

You are right. Every failed LAF frame causes the phone to reset. I have been
rebooting your phone all evening, and each reboot has the same result: the
home screen, the wallpaper, the clock, as if nothing happened.

I stop. I read the LAF protocol instead of poking it. That is when I learn the
useful thing: on these LG phones, an invalid frame does not return an error.
It reboots the device. The mode is not a shell. It is a trap with a polite
face.

At 21:00 a passive read of `/dev/ttyACM0` catches this:

```
ate0
OK
```

An AT conversation. The modem channel is alive. The vendor interface with
`class ff / subclass ff / protocol 48` is almost certainly DIAG. None of it is
LAF. The download-mode dream is over before it began.

## 21:04 — A Door Called Fastboot

> not a single time has it gone to download mode I think, you are free to
> reverse engineer, dump code, ask me to do stuff, whatever
>
> Enable OEM unlock is turned on in the developer options btw

At 21:03 I had found one more idea: the hidden service menu,
`*#546368#*710#`, can enable the raw DIAG port and perhaps reboot to EDL. We
never test it.

The second line changes everything.

I run `adb reboot bootloader` and the phone enumerates as `18d1:d00d`.
Fastboot. Real fastboot, on stock Android 10, on a locked bootloader. The
screen shows a green START box and a menu. `fastboot getvar all` works. It
reports `unlocked: no`, `unlock_count: 0`, `current-slot: a`.

At 21:06 I run `fastboot oem unlock` and wait three minutes. Nothing happens.
No prompt, no error, no wipe. The command goes into the phone and does not
come out.

## 21:12 — "How Are You Taking So Many Risks"

> beware to not brick the device
>
> how are you taking so many risks if even fastboot getvar unlocked doesn't
> work

It is a fair question, and I answer it with a table. What I did: read
properties, read the partition map, try `getvar`, try `fastboot boot` with an
image that was not written anywhere. What I did not do: write a single byte to
the phone. The risk is real but it is bounded. I say that, and I mean it.

Then I do the arithmetic on `fastboot boot`. If the locked bootloader would
boot an arbitrary image from RAM, we could skip EDL entirely. It will not. The
attempt goes nowhere.

## 21:14 — unlock.bin

> even the fastboot screen suggests
> fastbook flash unlock unlock.bin, but its too late to get that officially
> isn't it

Yes. The screen is showing LG's official path, the one that used to end with a
personalized file signed for this phone's device ID and IMEI. The portal is
gone. Files from other phones will not work. Files from "unlock services" are
either dead or a way to lose money.

The only remaining path is the ugly one: replace the bootloader with a
prototype, use its unlock command, then put the stock bootloader back before
the phone notices.

## 21:19 — Two Hands

You try the combination again and describe exactly what happens:

> when i hold vol- and power, it says keep holding it to reboot
>
> while rebooting, it waits for me to leave the vol- to sure the lg bootloader
> screen
>
> while I hold vol- and spam vol+ nothing happens, it just sits at the g7
> thinq logo

The timing is the problem. The window is not the logo. The window is the dark
between the logo and the boot. By the time the logo is visible, the phone has
already chosen.

I explain this. I also realize I have been asking you to do something that
requires three hands and a metronome.

## 21:24 — The Watchdog

> can you make a watchdog to poll and tell me when to stop btw

At 21:24 I write `edl_watch.sh`. It polls `lsusb` every 50 milliseconds for
`05c6:9008`. When it sees the device, it puts a notification on the desktop,
plays the freedesktop alarm sound, and prints a line with a timestamp.

It is a small program. It is also the first thing all night that works
exactly as intended.

## 21:26 — Too Quick

I put the phone in fastboot and fire `fastboot reboot` without waiting for
your hands.

> you rebooted too quick, put me in fastboot again, I'll reboot it myself

So we do it your way. I put the phone in fastboot, arm a fresh watchdog, and
step back. The next move is yours.

## 21:28 — "I Just Don't Think It's Possible"

> man, I just dont think its possible
>
> i did exactly what you had asked, this does not seem to work at all

There is a particular silence after a message like that. The watchdog is still
running. The terminal is still scrolling. Nothing on the phone is moving.

I stop defending the plan. I look at the evidence again and notice the thing I
should have noticed an hour earlier: `633a` has been a DIAG port all along, and
the only reason we are stuck on buttons is that I kept trying to make a service
port into a door.

I do not have a better idea. I say so. Then I go back to the one thing still
unexplained: the `633a` device. If it is DIAG, a version request will prove it.
I write a probe and send it. The probe does not answer before the mode exits.
The idea dies there, quietly, at 21:30.

## 21:31 — Pause

> lemme try the combo again, pause for a bit

I arm a ten-minute watchdog and stop typing. The phone is on the desk. You are
somewhere with your hands. The alarm is armed.

## 21:32 — The Beep

> yoooo i heard a beep

At 21:32:23 the phone is in EDL. `05c6:9008`. Qualcomm QDL mode. The screen is
black and has nothing to say.

It took an hour and a half, three protocol dead ends, one safe-mode accident,
and a small shell script with an alarm sound.

Nobody celebrates yet. I ask you not to touch the cable.

## 21:33 — Twelve Partitions

The firehose loader is `prog_ufs_firehose_Sdm845_lge.elf`, about 651 KiB,
extracted from Unlock845. It speaks to the phone immediately.

`edl printgpt` returns the map: seven LUNs. LUN 4 holds the bootloader and the
boot images. LUN 6 holds `frp`. LUN 0 holds the enormous `userdata`.

Then the read-only minute begins. `abl_a`, `abl_b`, `laf_a`, `laf_b`, `boot_a`,
`boot_b`, `dtbo_a`, `dtbo_b`, `frp`, `vbmeta_a`, `vbmeta_b`, `devinfo`. Twelve
files. Each one read twice: once to disk, once to hash.

At 21:34 the checksums come back 12 out of 12. Nothing has been written to the
phone.

## 21:39 — The First Write

> works, you can go ahead
>
> I dont mind keeping the engineering abl, but if you think the oem ones good,
> that works too

The first write is `eabl.img` to `abl_a`, 1 megabyte into a 1 megabyte
partition. The read-back matches byte for byte: `c2b20241…`.

The plan is simple. The engineering ABL lives on slot A. Slot B keeps the
stock bootloader as a parachute. Reboot, land in the prototype's fastboot, run
`oem unlock`, then restore both slots.

The phone reboots. It does not land in the prototype's fastboot.

## 21:41 — Slot B

Android comes up. Slot `_b`. Boot reason `reboot,ota`. The phone has chosen the
untouched slot and the stock bootloader, which means the engineering ABL on
slot A is not active.

I try to switch slots. `fastboot set_active a` says:

```
Device does not support slots
```

The bootloader reports `slot-count: 2` but refuses to switch. That is not a
bug in the phone. It is LG's fastboot being a narrow, strange thing.

So the parachute becomes the plan: write the engineering ABL to `abl_b` as
well.

## 21:52 — "Did You Not Write It?"

> did you not write engineering ABL the last time we were on ebl

Yes. Slot A. Verified. But the phone is booting from slot B, and slot B is
still stock. I explain the difference between *written* and *active*. You
accept it. The watchdog has been running since 21:45.

At 21:55 it times out after ten minutes. At 21:57 you type:

> is it in edl rn

It is, now. When the watchdog expired the phone was still in the transient
`633a` state. The EDL window opened a minute or two later.

## 21:57 — The V35 in the Room

`abl_b` gets the same image, verified byte for byte. Then `edl reset`.

The phone comes up in fastboot with a different serial:

```
LMV350EMWa65939f9
```

The V35 prototype bootloader is identifying itself with our serial number
appended. The serial is the tell. The screen details arrive at 22:03.

For the first time, the phone is running the thing we chose, not the thing LG
shipped.

## 22:00 — 0x00000050

`fastboot oem unlock` returns:

```
FAILED (remote: 'unknown command')
```

Then `getvar unlocked` returns something stranger:

```
Set device unlocked! failed: 00000050
```

The error surfaces from `getvar unlocked`, after a sequence of unlock verbs.
It is consistent with a failure inside the set-unlocked routine. What that
routine writes, and where, is not visible from here. The community history is
three states, repeating in no fixed order — `unknown command`, `00000050`, and
eventually `unlocked: yes`.

The screen still says locked.

## 22:03 — Red Case

You send a description of the screen. It is the one nobody wants to see. The
text, in fragments:

> "Your device has failed a routine safety check and will not boot."

> "This may be a temporary problem. If this message occurs repeatedly, visit
> this link on another device and refer to the Red case:"

> "Your device will power off automatically after a while."

> g.co/ABH

Under it, the fastboot screen: `LM-V350EMW`, `judyp_lao_com`, `Secure Boot:
yes`, `Device State: locked`, `Active A/B Slot: _b`.

I tell you it is expected. It is. The Unlock845 README describes exactly this:
an unsigned Oreo prototype ABL on a production phone will fail the safety
check and fall back to the bootloader. It is not a brick. It is the prototype
refusing to lie.

You do not sound convinced. I am not sure I would be either.

## 22:07 — Restart Bootloader

The next attempt to reach EDL runs into a physical fact:

> from fastboot i cant do Vol- + Power
>
> I have the options to
> START
> Restart bootloader
> Recovery Mode
> Power off

The menu is the way in. Select **Restart bootloader**, hold Volume Down, and
tap Volume Up the moment the screen goes dark. The phone reboots the
bootloader, the black gap opens, and the watchdog catches it.

It works. At 22:09 you are in EDL again.

## 22:09 — FRP

The patched FRP image is written to LUN 6, 2 megabytes, verified:
`11ec9af9…`. The original is safe at `3f6fd1d5…`.

The FRP patch is the part nobody explains well. Inside the image is an ext2
filesystem, and inside that:

```
/TWRP/BACKUPS/LMV3508ddd3823
```

A backup directory named after a *different* phone. The V35 prototype's serial.
LG stores unlock authorization in this partition under a path keyed by serial
number, and the image carries someone else's key. We are borrowing it.

At 22:11 the unlock is attempted again. The ABL answers `unknown command`,
then stops answering for a while. The channel is inconsistent rather than dead:
a later `reboot-bootloader` returns OKAY.

## 22:20 — Doubt

> are we sure that this engineering ABL supports `fastboot oem unlock`?
>
> also it looked like fastboot getvar all worked but fastboot getvar all did
> not work the last time

A precise question. The answer is: yes, the Unlock845 script uses exactly this
verb on exactly this image. The behavior is inconsistent because the ABL keeps
two kinds of state: what it knows at boot, and what survives a wedge.

At 22:22 you add the detail that settles it:

> I did not see any prompt to accept a bootloader unlock tho

No prompt. No wipe. No visible change. Just a command that goes in and does
not come out.

## 22:26 — The Thread

I search the exact error string. A 2021 thread on forum.earlybird.club has the
same phone, the same `00000050`, and a remedy: start the fastboot client
*before* the phone enumerates, so that `oem unlock` is the first packet the
fresh ABL sees.

Not the second. Not after a `getvar`. The first.

We try it. The first attempt fails at the host side — `fastboot
reboot-bootloader` cannot write to the device — and the phone never reboots.
You reboot it by hand.

At 22:29 the fresh session answers `unknown command`, then goes silent for
five attempts in a row.

## 22:33 — The State Was Already There

> I can reboot manually if you want me to

Yes. I arm a background loop: wait for `18d1:d00d`, then fire `oem unlock` the
instant it appears. You hold the buttons. The phone goes dark, comes back, and
the loop fires.

The watcher fires, but the command does not reach the device: it fails with a
host-side write error. The read-back, one line later, says:

```
unlocked: yes
```

No wipe. No confirmation. No ceremony. One of the earlier attempts had already
landed the state, and the phone had been carrying it quietly across reboots.
The watcher did not prove the first-packet theory. It only arrived after the
fact.
The screen still said `locked`, because the screen is drawn by a different part
of the bootloader than the one that answers `getvar`.

## 22:37 — Proof

I do not trust it. I ask for EDL one more time and read the partitions.

`abl_a` is still the engineering ABL. `devinfo` is byte-identical to the
locked-state backup: the `ANDROID-BOOT!` magic, version bytes `01 01`, then
zeros. The `unlocked: yes` is not in
`devinfo`. It is somewhere else — RPMB, a fuse, a place flash reads cannot see.

Then the restore: stock `abl_a`, stock `abl_b`, stock `frp`. All three
verified against the originals.

At 22:42 the phone reboots into fastboot with the stock serial and answers:

```
unlocked: yes
```

It is real. The unlock survived the removal of the thing that performed it.

## 22:45 — The Loop

The phone does not boot Android. It goes to fastboot. Every time.

I try the standard post-unlock wipe. `fastboot erase userdata`. The session
dies between commands. I queue the erase before the device exists. It fails
too.

This is the pattern that will define the next two hours: a fresh fastboot
session accepts exactly one command, then the USB link disappears. The phone is
not broken. It is just extremely bad at conversation.

## 22:47 — One Command Per Session

You photograph the fastboot screen. It is the stock LG text:

> Welcome to Fastboot Mode:
>
> 1. How to flash a partition
> :fastboot flash <partition> <filename>
> 2. How to erase a partition
> :fastboot erase <partition>
> 3. How to reboot
> :fastboot reboot

The stock bootloader is back. The unlock is real. The phone still will not
boot.

## 22:57 — TRIM

Fastboot cannot erase 46.66 GiB of userdata in one session. EDL can. `edl e
userdata` sends a UFS TRIM command, and the partition is empty in seconds. Not
zeroed. Released.

The phone reboots. Fastboot again.

## 23:05 — The Manual Power Cycle

> its only restarting to fastboot
>
> even when turned off and on again, it just goes to fastboot

So it is not a boot-reason artifact. It is not the counter. It is not the cable.
The bootloader is deciding, every time, not to attempt the OS.

## 23:07 — A Note in misc

I read `misc`, the partition where Android keeps its boot command block.

It is not empty. It contains:

```
recovery
--wipe_data
--reason=MasterClearConfirm
--locale=en_US
```

A live instruction to boot recovery and wipe data. It looks like the missing
step. It is not; erasing it does not change the boot result. The writer is not
established. Your earlier factory reset (`bootreason: reboot,factory_reset`) is
a plausible source.

I erase it anyway. The read-back is 1,048,576 zero bytes. The phone still goes
to fastboot.

## 23:09 — The Wrong Kind of Clean

> nope, still just rebooting into fastboot

For a while I am sure I have made a mistake. The note in `misc` was not
garbage, I tell myself. It was the *last step of the unlock*, waiting to be
honored. I wiped it because it looked like junk.

I spend the next twenty minutes proving that restoring it does not help. It
does not. The mistake is mine, but it is not the reason the phone will not
boot.

## 23:12 — The Sweep

The phone is still in EDL from the last attempt. I read the hidden partitions,
one after another: `mpt`, `sec`, `oem_a`, `oem_b`, `devinfo`, `limits`, `fsc`.

- `mpt` is a mounted filesystem: LG's database, EULA files, SELinux contexts.
- `oem_a` and `oem_b` are ext4 operator partitions. Identical. Not boot flags.
- `sec` is a 256 KiB partition with 179 nonzero bytes of LG security data.
- `devinfo` is untouched.
- `limits` is 4 KiB with 16 nonzero bytes. The values look like counters; the
  structure is not decoded.
- `fsc` is 512 KiB of zeros.

Nothing says "boot to fastboot." The flag is not in the places I can read.

## 23:22 — Empty Logs

LG writes boot logs to `logfs` and `logdump`. I read both at 23:22.

`logdump` is 64 MiB of zeros. `logfs` is an empty FAT12 filesystem from 2016,
with 497 nonzero bytes of filesystem metadata and no files. Not a single line.
The bootloader on this build does not record why it refuses to boot.

## 23:23 — Sending boot.img

The decisive experiment: boot the phone's own stock kernel from RAM, bypassing
the partition table.

`fastboot boot backup/boot_a.bin` starts. The host prints:

```
Sending 'boot.img' (65536 KB)
```

Then nothing. The transfer stalls. The phone stays in fastboot.

## 23:29 — The Mistake

I come back to `misc`. The BCB was the unlock's pending wipe. If I restore it,
the phone might finish the wipe and boot.

At 23:31 I restore it, byte for byte, `a0cb5511…`. `edl reset`.

Fastboot.

The note is not honored. The decision happens before Android ever reads it.

## 23:38 — Encrypted

You tell me two things: the stock fastboot has no Recovery Mode option, and
the phone shows the LG logo for about a second before fastboot.

That second matters. The ABL is *trying*. It is failing before the kernel.

I try to read the bootloader itself. At 22:24 I already found a valid ARM ELF
header, a 204 KiB code segment, and 385 strings, mostly certificate fields.
There is no `unlock` string anywhere. At 23:38 I scan for compressed streams.
There are none. The body is encrypted, not compressed.

Static analysis is closed.

## 23:41 — One Byte

The next experiment is small enough to be reversible: set the Qualcomm
`devinfo` unlock flag at offset `0x10`, from `00` to `01`, and see if the stock
ABL changes its mind.

The write goes in. It reads back correct. The phone reboots.

> also when it boots I think I still see orange bootloader warning, too bad it
> goes straight to fastboot after that tho

The orange warning is new information. The ABL is attempting the boot chain,
showing the sanctioned-unlock warning, and then bailing. It is not refusing at
the first gate. It is failing at the second.

## 23:43 — The Flag Did Nothing

> idts the bit flag did anything, i put it back in edl

It did nothing. The one-byte change is inert on this firmware. We leave the
modified image on disk as evidence and move on.

## 23:45 — The Slot

I ask for a full `getvar all`. It works, 221 lines. Most of it is partition
sizes. The interesting part is six lines:

```
current-slot:b
slot-retry-count:b:7
slot-unbootable:b:yes
slot-successful:b:yes
slot-retry-count:a:6
slot-unbootable:a:yes
```

Both slots are marked unbootable. The ABL has no bootable slot to try. That is
the leading explanation for the fastboot loop, not a proven one: the flags were
read once, at 23:45, and never re-read.

I try `fastboot set_active a`. It says the device does not support slots.

I try `fastboot --set-active=a` on a fresh session. It is accepted, with no
error. The phone still does not boot. The flags are not re-read, so we do not
know whether the command did anything at all.

## 23:58 — So What Now

> so what now

The honest answer: the chosen fix is a full firmware reflash. The KDZ should
rewrite the partition table, the slot attributes, and every boot-critical
partition in one pass. A manual GPT repair was proposed at 23:54 but never
attempted.

The only problem is that the KDZ flash needs LGUP, and LGUP runs on Windows.

## 00:07 — The Offer

> if I gave you access to ssh into my windows pc with the phone connected,
> would it help
>
> or do you wanna try another way?

I say yes. It is the known-good path: LG's own flashing tool, on a machine that
is already sitting next to the phone.

## 00:16 — Windows

At 00:16 I have SSH on `Nithil@192.168.0.125`. Windows 10, build 19044. The
phone is plugged in there, in fastboot, with a driver error. The LG driver and
the Qualcomm driver go in. The fastboot device still shows as "Android" with a
yellow mark.

At 00:16:43 I read `FastbootFix.bat` from the Unlock845 zip. Three registry keys:
`osvc`, `SkipContainerIdQuery`, `SkipBOSDescriptorQuery`. The standard Windows
enumeration fix. We do not need it for the plan, because the plan needs
download mode, not fastboot.

## 00:22 — The Captcha

The KDZ is on lgrom.com behind a reCAPTCHA. I read the page, find the POST,
extract the CSRF token, and try without a browser:

```json
{"code":604}
```

Captcha failed. `firmwaredrive.com` wants a login. `lg-firmwares.com` hides the
file behind the same kind of gate.

You open Firefox and click the green button yourself. The download starts on
the Linux machine: 3.65 GB.

## 00:34 — 3.7 Gigabytes

> /home/nithilan/Downloads/G710EMW30e_00_0916.kdz has completed downloading
>
> also its in download mode, saying firmware update: Do not unplug the usb
> connection until the process is complete

The file is on the Linux machine, not the Windows one. That is fine. The hash
matches the one in the archive: `575e07fc…`. I push 3.7 GB over the LAN with
`scp`, and try not to think about the transfer time.

The phone is in download mode on the Windows PC. `LGE AndroidNet USB Serial
Port (COM6)`. Status OK.

## 00:41 — COM6

The first `LGUP_Cmd` attempt fails before it starts:

```
Free space(0.80 GBytes) of your LGUP installation drive['C:\'] is not enough
(more than 2.00 GBytes).
```

The Windows machine has 800 MB free on C:. It also has an E: drive with
plenty of room. I move the tools and the KDZ to `E:\g7work` and run from
there.

## 00:43 — SW_PATH

```
Error!!! [SW_PATH] is null
```

Every argument order fails the same way. `LGUP_Cmd.exe com6 <dll> <kdz>`,
`com6 <kdz>`, relative paths, absolute paths. The usage text says
`[COM Port Number] [DLL_PATH(Optional)] [SW_PATH]`, and we are passing a
`SW_PATH`. It does not care.

I decide the portable binary needs an installed LGUP. I download both MSIs —
Store Frame 1.14.3 and Lab Frame 1.16 — install them over SSH, and copy
`LGUP_Common.dll` into `model\common\`.

Then I discover the installed LGUP has no `LGUP_Cmd.exe` at all. I copy it in.

```
Free space(0.71 GBytes) of your LGUP installation drive['C:\'] is not enough
```

The duplicate KDZ on C: is eating the space. I verify both copies have the same
hash, delete the C: copy, and try again.

```
Error!!! [SW_PATH] is null
```

## 00:50 — The Fourth Wall

At 00:50 I read the strings inside `LGUP_Cmd.exe`. I try to infer what `SW_PATH` means
from its own usage text and error messages. It is a framework binary expecting
a particular installation layout, and the layout it wants is not the one we
have.

This is the least dramatic failure of the night. It is also the funniest: the
official tool, run the official way, refuses to accept the official file.

## 00:53 — "I Can Operate LGUP"

> I can operate LGUP for you

The GUI. Of course. You are sitting at the Windows machine. I am not.

I check the phone one more time: download mode, COM6, status OK. Then I give
you five instructions. Run `LGUP.exe`. Pick COM6. Choose
`E:\g7work\G710EMW30e_00_0916.kdz`. Select **Refurbish**. Press Start. Do not
unplug.

## 01:04 — 77%

> something scary
>
> the download manager climed up to a 100%
>
> and the LGUP was at 77% and said rebooting [40s]
>
> LGUP says complete, but the phone just says LG G7 ThinQ, its been more than
> 40s
>
> NEVERMINDDD, after sittinf for a while iti rebooted (with orange unlocked
> bootloader warning)
>
> and then i saw an erasing screen
>
> and now its back to android, LG Stock android but still, yipee!!!
>
> also in the settings, "Enable OEM unlock" is greyed out
>
> because right under it, it says "Bootloader is already unlocked"

There it is. The phone boots. The orange warning appears. The erase screen
runs. Android comes up. The Developer options screen says the sentence we have
been trying to earn all night.

The reflash is expected to have rewritten the slot attributes; no post-flash
`getvar` was taken. The unlock survived the reflash. The phone is stock,
booting, and open.

## 01:15 — The Archive

> lets save our progress for now
>
> by that I mean a new repo at ~/Projects/lg-g7-thinq-unlocked
>
> where we store ALL lg g7 related files till now, organised neatly of course
>
> do not leave a single file out however small, even if its exes that can be
> reinstalled
>
> make sure to document the inventory thoroughly

We copy everything. Twelve partition dumps. The state sweep. The read-backs.
The firehose loader. The LGUP installers. Three lglaf clones. The four scripts
written during the night. The KDZ, 3.7 GB. The saved lgrom page.
The session cookies. The getprop dump. The partition map.

Then the documents: README, NOTES, INVENTORY, journey, device facts. The
manifest. The first commit at 01:26. The cookies at 01:27.

## 01:28 — After Dark

The last message in the session is an idle event. The phone is booting Android
on its own. The terminal is quiet. The watchdog is not running anymore.

In the morning, the archive will need tidying. That is tomorrow's problem.

Tonight, the phone is unlocked.

---

## Appendix — the cast

| Thing | What it was |
|---|---|
| Phone | LG G7 ThinQ, LM-G710EMW, `judyln`, Android 10 (V30w reported; 30e in getprop) |
| Serial | `LMG710EMWa65939f9` |
| Host | Arch Linux, kernel 7.2.11-zen1, android-tools 37.0.0p1 |
| Windows host | Windows 10 19044, `192.168.0.125`, LGUP on COM6 |
| Loader | `prog_ufs_firehose_Sdm845_lge.elf` (651 KiB / 667 kB) |
| Firmware | `G710EMW30e_00_0916.kdz`, 3.7 GB, SHA-256 `575e07fc…` |
| Backups | 12 partitions, verified 12/12 |
| Unlock | `unlocked: yes`, `unlock_count: 1`, orange warning on boot |
| Duration | 5 hours 27 minutes |

### A note on sources

Every time, quotation, command, error string and hash in this file comes from
the exported session `ses_e9adaec6bffebFGjSo2gZhSuze` (478 messages). The
technical record is in `NOTES.md`; the file inventory is in `INVENTORY.md`; the
checksums are in `MANIFEST.sha256`. Where the record and the story disagree,
the record wins.

---

## Epilogue — the next morning

**23 October 2026, 07:22 — 08:20**

The phone came back to the Linux machine after a reboot of that host, and the
LineageOS work began.

- 07:22 — the 949 MB LineageOS 22.2 nightly and its `boot.img` were downloaded
  and matched against the published SHA256 values.
- 07:29 — the Lineage `boot.img` was written to both boot slots over EDL and
  read back byte-exact. The phone refused it: orange warning, then fastboot,
  every boot. The slot attributes were degrading each time.
- 07:52 — the stock boot chain was restored from the backups. Android booted
  again. The direct-flash route was dead.
- 07:55 — Magisk v30.7 was installed, the stock boot image was patched on the
  phone, and the patched image was written to both slots over EDL.
- 08:00 — root confirmed. The Lineage recovery was written to both boot slots
  with `dd` from the rooted system, then `adb reboot recovery`.
- 08:05 — Lineage recovery. `copy-partitions` sideloaded, data formatted,
  the ROM sideloaded, then MindTheGapps.
- 08:20 — LineageOS 22.2 booted. The install was verified over ADB.

The full method, with the exact commands and the traps, is in the
"LineageOS 22.2 install" section of `NOTES.md`.
