# Testing SpeedyOS

All testing happens in QEMU/KVM virtual machines. The only disk a test VM
can see is a qcow2 **file** in `vm/`; the scripts never attach host block
devices. Do not test the installer on your real machine.

## Requirements

`qemu-desktop` and `edk2-ovmf` (UEFI firmware). `/dev/kvm` should be
accessible, otherwise QEMU falls back to (very slow) software emulation.

## Quick reference

```bash
./scripts/run-vm.sh live                 # boot the newest ISO, no disk
./scripts/run-vm.sh install              # ISO + disposable 40G test disk
./scripts/run-vm.sh installed            # boot the test disk after installing
./scripts/run-vm.sh install --bios       # same, legacy BIOS (separate disk)
./scripts/run-vm.sh reset-disk           # delete test disks + UEFI variables
```

Add `--headless` for automation: no window, VNC on `127.0.0.1:5905`, and
control sockets in `vm/`. `scripts/vmctl.py` drives a headless VM:

```bash
./scripts/vmctl.py wait-agent 300        # wait for the QEMU guest agent
./scripts/vmctl.py shot screen.png       # screenshot
./scripts/vmctl.py click 640 400         # click (screen pixels)
./scripts/vmctl.py type 'hello'          # type text (US layout)
./scripts/vmctl.py exec 'systemctl --failed'   # run a command as root in the VM
./scripts/vmctl.py quit                  # power off
```

`exec` uses `qemu-guest-agent`, which is part of the live image and the
installed system.

Plasma uses software rendering in the VM, so the desktop takes 30-60 s to
appear after login. That is a VM limitation, not a SpeedyOS problem.

## Test checklist

### Live session

- [ ] UEFI boot menu shows "SpeedyOS live"; BIOS (syslinux) menu too (`--bios`)
- [ ] SDDM logs in `speedyuser` automatically into Plasma (Wayland)
- [ ] SpeedyOS wallpaper, colors, and Konsole theme are applied
- [ ] Full-screen "Try or Install" screen appears; KDE's own welcome app
      and the SpeedyOS Welcome Center do not open by themselves
- [ ] "Try SpeedyOS" (and Esc) closes it; "Install SpeedyOS" starts Calamares
- [ ] Desktop icons "Install SpeedyOS" and "Welcome" launch without a trust warning
- [ ] `systemctl --failed` is empty; `systemctl is-system-running` is `running`
- [ ] Network works (`nmcli general`, `speedy doctor`)
- [ ] `speedy help/info/version/doctor/search` work
- [ ] `speedy dance` animates and restores the terminal on a key or Ctrl+C
- [ ] `/etc/shadow` is mode 400 (`ls -l /etc/shadow`)

### Installation (`run-vm.sh install`, UEFI and BIOS)

- [ ] Installer starts from the desktop icon and the Welcome Center
- [ ] Welcome, Location, Keyboard, Partitions, Users, Summary pages work
- [ ] Partitions page preselects nothing; the summary lists every change
- [ ] "Erase disk" install completes without errors
- [ ] Log: `/root/.cache/calamares/session.log` in the live VM

### Installed system (`run-vm.sh installed`)

- [ ] GRUB menu says SpeedyOS and boots
- [ ] SDDM asks for the user created in the installer (no autologin)
- [ ] `speedyuser` does not exist; no `/etc/sudoers.d/10-speedyos-live`
- [ ] `sudo` asks for the user's password
- [ ] No live-only units (`choose-mirror`, `pacman-init`) and no root autologin on tty1
- [ ] `/etc/shadow` mode 600; `pacman-key --list-keys` shows Arch keys
- [ ] `calamares` is not installed; the Welcome Center has no install button
- [ ] `speedy update` works with network
