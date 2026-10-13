# Installing SpeedyOS

> ⚠️ SpeedyOS is in early development. It has been installed successfully
> in virtual machines (UEFI), but **not yet on real hardware**. Back up your
> data and try it in a VM or on a spare disk first. Installing can erase
> disks; the installer always shows exactly what it will change and asks
> before writing anything.

## Requirements

| | Minimum | Recommended |
|---|---|---|
| CPU | x86_64 | 4 cores |
| RAM | 2 GB (installer check) | 4 GB+ |
| Disk | 15 GB (installer check) | 30 GB+ |
| Firmware | UEFI or BIOS | UEFI (Secure Boot must be off) |

## 1. Create the boot medium

Build the ISO (see [BUILDING.md](BUILDING.md)) or use a released one, and
verify it:

```bash
sha256sum -c speedyos-*.iso.sha256
```

Write it to a USB stick. **Double-check the device name: everything on it
is erased.**

```bash
lsblk                                    # find the USB stick, e.g. /dev/sdX
sudo dd if=speedyos-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Tools such as Ventoy or GNOME Disks work as well.

## 2. Boot the live session

Boot from the stick (often F12, F11, Esc or F8 at power-on). Choose
**SpeedyOS live**. You are logged in automatically as `speedyuser` (no
password) on a KDE Plasma desktop, and a full-screen welcome asks what you
want to do:

- **Try SpeedyOS** (or Esc) closes it and leaves you on the live desktop.
  Nothing is saved to disk in the live session.
- **Install SpeedyOS** starts the installer right away.

Connect to a network with the network icon in the panel if you want time
zone detection; the installation itself works offline.

## 3. Run the installer

Choose **Install SpeedyOS** on the welcome screen. If you chose to try it
first, double-click **Install SpeedyOS** on the desktop, use the button in
the Welcome Center, or run `speedy installer` in a terminal.

1. **Welcome** — language. Requirements (RAM, disk space) are checked here.
2. **Location** — region and time zone.
3. **Keyboard** — layout; type in the test field to check it.
4. **Partitions** — pick the disk, then explicitly choose one action.
   Nothing is preselected:
   - *Erase disk*: deletes everything on that disk. Optional encryption
     (LUKS) and swap size are set here. The default file system is
     **Btrfs**, which gives you automatic snapshots (see below); ext4 and
     XFS are available too, without snapshots.
   - *Install alongside*: shrinks an existing partition (keep backups!).
   - *Replace a partition*.
   - *Manual partitioning*: you need an EFI system partition mounted at
     `/boot/efi` on UEFI systems.
5. **Users** — your name, login, computer name and password. Your account
   gets administrator rights (`sudo`, with your password). The same
   password is used for `root` unless you untick that box.
6. **Summary** — every disk change is listed here. Nothing has been written
   yet. **Install** asks once more before starting.
7. **Install** — copies the system, configures it, installs GRUB.
8. **Finish** — restart, and remove the USB stick when the screen goes dark.

## 4. First boot

The SpeedyOS boot menu appears, then Speedy's paw prints while the system
starts, then the login screen. Log in with the account you created. The
Welcome Center opens (untick *Show at login* to stop that).

First steps:

```bash
speedy update        # full upgrade: Arch packages, AUR packages, Flatpak apps
speedy drivers       # recommended graphics drivers (NVIDIA, AMD, Intel)
speedy doctor        # health check
```

When updates are available, a notification offers to install them.

### Snapshots (Btrfs installs)

A snapshot of the system is taken right after installation and before and
after every package change (`snapper` + `snap-pac`; your home folder is not
included). If an update breaks something:

- Choose **SpeedyOS snapshots** in the boot menu to start the system as it
  was at an earlier snapshot (read-only, changes are discarded at shutdown).
- Or put system files back from a snapshot: `speedy snapshots` lists them,
  `speedy undo <number>` restores one (it takes a safety snapshot first).
- `speedy snapshot "before trying X"` takes one by hand.

### More software

`speedy install <name>` installs from the Arch repositories and, when a
package is only in the [AUR](https://aur.archlinux.org/) (community
packages, not checked by Arch), offers to build it with `yay` after a
warning. Flatpak apps from Flathub are available in Discover or with
`flatpak install`.

SpeedyOS is Arch Linux underneath: everything on the
[ArchWiki](https://wiki.archlinux.org/) applies.

## What the installer changes compared to the live session

The installed system is a copy of the live image with the live-only parts
removed (`/usr/local/lib/speedyos/finalize-install`): the live user and its
passwordless `sudo`, automatic login, the root console autologin, the
archiso initramfs hooks and the installer itself. The kernel is placed in
`/boot`, a normal initramfs (with fallback) is built, and the pacman keyring
is initialized. It also selects the SpeedyOS boot splash, enables the update
notifier, and on Btrfs sets up snapper, snap-pac and grub-btrfs (on other
file systems those three packages are removed).

## Troubleshooting

| Problem | What to do |
|---|---|
| Installer says "Installation Failed" | The full log is `/root/.cache/calamares/session.log` in the live session (`sudo less ...`). Please include it in bug reports. |
| Installer window too tall for the screen | Maximize it (double-click the title bar). |
| Firmware doesn't offer the USB stick | Disable Secure Boot; try the other USB port; check UEFI vs legacy mode. |
| Installed system doesn't boot (UEFI) | Some firmware ignores new boot entries; the installer also writes the fallback `\EFI\BOOT\BOOTX64.EFI`. Choose the disk itself in the boot menu. |
| No network after install | Use the panel network icon or `nmtui`; `systemctl status NetworkManager`. |
