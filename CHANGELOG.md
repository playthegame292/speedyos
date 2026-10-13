# SpeedyOS Changelog

All notable changes to SpeedyOS are documented here.

## [Unreleased] — 2026.10 "Beagle Run"

### Try or Install, Speedy's tricks (2026-10-13)
- Live session opens a full-screen "Try or Install" screen
  (`speedyos-try-install`); the installer's finalize step removes it from
  installed systems. The Welcome Center no longer autostarts in the live
  session, only on installed systems.
- `speedy dance`: a rainbow, animated beagle in glasses. `speedy tricks`
  lists bark, sit, stay, roll, fetch, treat, zoomies and wisdom; a few more
  commands are hidden. Special messages on some dates in `speedy help`.
- Welcome Center easter eggs: pet the logo; the Konami code.

### Phase A — Project initialization (2026-10-13)
- Project structure, archiso profile based on releng, wallpaper generator,
  `speedy` CLI and Welcome Center prototypes, Calamares 3.4.2 package.

### Phases B–F — Bootable, installable foundation (2026-10-13)

**Build**
- Rootless ISO build (`scripts/build-iso.sh`, archiso user namespaces; no sudo).
  `--fast` option for zstd development builds.
- `scripts/build-packages.sh` builds `speedy-*` into the local `[speedyos]`
  repo; the prebuilt Calamares package is reused, not rebuilt.
- `scripts/validate-profile.sh` catches overlay/package file conflicts,
  unknown packages, invalid Calamares YAML and `declare` in profiledef.sh.
- Project-local pacman cache for builds; the repo path in `pacman.conf` is no
  longer hardcoded.
- `scripts/run-vm.sh` (QEMU live/install/installed, UEFI or BIOS, disposable
  qcow2 disks only) and `scripts/vmctl.py` (headless VM automation).

**Fixed**
- `file_permissions` were silently ignored (`declare -A` inside profiledef.sh
  made the array function-local in mkarchiso): `/etc/shadow` was
  world-readable and live scripts were not executable.
- Overlay files that packages also own (would abort pacstrap):
  `usr/bin/speedy`, `usr/bin/speedyos-welcome`, icons, `calamares.desktop`,
  wallpapers.
- Hand-written `/etc/group` with wrong/duplicate GIDs replaced by a
  `sysusers.d` drop-in.
- Only NetworkManager manages the network (systemd-networkd and iwd were
  also enabled); dangling units for packages not in the image removed;
  sshd with root login disabled in the live session.
- Shell aliases that shadowed real commands (`install`, `info`) removed;
  ASCII prompt on the Linux console.
- Calamares: added the missing `users`, `removeuser`, `initcpiocfg`,
  `initcpio`, `grubcfg` and LUKS exec modules; updated configs to the 3.4
  schemas; `unpackfs` copies from the mounted root image (works with
  copytoram); kernel restored to `/boot` on the target; live-only
  configuration (passwordless sudo, root autologin, archiso hooks, live user)
  removed from installed systems; pacman keyring initialized.
- KDE's own welcome app disabled in favour of the SpeedyOS Welcome Center.

**Added**
- `speedy` 0.2.0: input validation, no shell evaluation, shows the exact
  command it runs, confirmation for destructive actions, working `doctor`.
- Welcome Center 0.2.0: Troubleshooting page, Documentation link, real system
  info, "Show at login" toggle, installed vs live mode.
- `speedy-branding`: Plasma look-and-feel `org.speedyos.desktop`, SpeedyOS
  color scheme, wallpapers, badge icon set, Konsole theme, SDDM and lock
  screen backgrounds.
- `speedyos-installer` launcher and `/etc/speedyos-release`.

### Tested (QEMU/KVM, UEFI, 2026-10-13)
- Live ISO boots to Plasma (Wayland) with autologin; no failed units;
  network up; `speedy` commands work.
- Calamares: full guided install ("Erase disk", ext4 + swap) on a disposable
  40 GB virtual disk completed.
- Installed system boots via GRUB (UEFI NVRAM entry "SpeedyOS"); SDDM asks
  for the new user's password; live user and live-only files are gone;
  `sudo` requires a password; `/etc/shadow` 600; Calamares removed; pacman
  keyring populated; network up; `speedy doctor` clean.

### Not yet tested
- Legacy BIOS boot and install; LUKS-encrypted install; btrfs; "alongside"
  and manual partitioning; real hardware; Wi-Fi; Secure Boot (unsupported).
- `speedy update` / `install` / `clean` against live repositories in the VM.

### Known issues
- The Calamares keyboard preview shows unlabeled keys (`ckbcomp` is not
  available in the Arch repositories).
