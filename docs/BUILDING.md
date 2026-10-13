# Building SpeedyOS

This guide explains how to build the SpeedyOS ISO from source. The whole
build runs as your normal user: no `sudo`, and nothing on the host system
is changed.

## Prerequisites

- **Host**: Arch Linux, x86_64
- **Disk**: about 15 GB free (work directory ~9 GB, ISO ~2.5 GB)
- **RAM**: 8 GB recommended (squashfs compression uses ~5 GB)
- **Subordinate IDs**: your user needs entries in `/etc/subuid` and
  `/etc/subgid` (Arch creates these for users added with `useradd`).
  Check with `grep "$USER" /etc/subuid /etc/subgid`.

Install the build tools (once):

```bash
sudo pacman -S --needed archiso arch-install-scripts squashfs-tools \
    libisoburn dosfstools e2fsprogs mtools erofs-utils grub \
    qemu-desktop edk2-ovmf python-pillow python-yaml
```

`./scripts/check-dependencies.sh` reports anything missing.

## Build steps

```bash
./scripts/build-packages.sh     # build speedy-* and yay-bin (AUR) into iso/custom-repo
./scripts/validate-profile.sh   # fast checks, ~10 s (build-iso.sh runs it too)
./scripts/build-iso.sh          # release build (xz), 30-60 min
./scripts/build-iso.sh --fast   # development build (zstd), much faster
```

The result is `out/speedyos-YYYY.MM.DD-x86_64.iso` plus a `.sha256` file.
The build log is `build/logs/latest.log`. If an ISO with the same name
already exists, it is moved to `out/previous/` instead of being overwritten.

### How the rootless build works

archiso supports building without root: `mkarchiso` runs `pacstrap` and the
image tools inside a user namespace (`unshare --map-auto`). Files in
`build/work/` are therefore owned by your subordinate IDs (e.g. 100000+).
To delete the work directory by hand, do it from a namespace too:

```bash
unshare --map-auto --map-root-user rm -rf build/work
```

(`build-iso.sh` does this automatically before each build.)

> An older `work/` directory owned by **root** may exist from earlier
> `sudo mkarchiso` builds. It is no longer used; remove it with
> `sudo rm -rf work` to free ~8 GB.

## What goes into the ISO

| Piece | Where | Notes |
|---|---|---|
| Archiso profile | `iso/archiso-profile/` | Based on Arch's `releng` profile |
| Package list | `iso/archiso-profile/packages.x86_64` | Official Arch packages + `[speedyos]` |
| Live overlay | `iso/archiso-profile/airootfs/` | Live user, SDDM autologin, Calamares config |
| Local repo `[speedyos]` | `iso/custom-repo/` | `calamares`, `speedy-cli`, `speedy-welcome`, `speedy-branding`, `yay-bin` |
| Artwork | `artwork/` | Regenerate with `python3 artwork/generate-wallpapers.py`; boot splash and GRUB theme with `python3 artwork/generate-boot-art.py` (needs `grub-mkfont`) |

The profile's `pacman.conf` contains `@SPEEDYOS_REPO@`; `build-iso.sh`
replaces it with the absolute path of `iso/custom-repo` in a copy under
`build/`, so the project can live anywhere.

### Calamares

Calamares 3.4.2 is not in the official repositories. A prebuilt package
(`calamares-3.4.2-2-x86_64.pkg.tar.zst`, built from the AUR PKGBUILD) is kept in
`iso/custom-repo/`. `build-packages.sh` does **not** rebuild it; it only
refreshes the repository database. To update Calamares, build the new
version from the AUR with `makepkg`, copy the package into
`iso/custom-repo/`, delete the old one, and rerun `build-packages.sh`.

### Rules for the overlay (`airootfs/`)

archiso copies the overlay into the image **before** installing packages.
A file in the overlay that a package also installs makes pacman abort with
"exists in filesystem". `validate-profile.sh` checks for this. So:

- Ship SpeedyOS files that belong on the installed system in a package
  (`packages/`), not in the overlay.
- Use the overlay only for live-session configuration. Everything live-only
  is removed on the installed system by
  `airootfs/usr/local/lib/speedyos/finalize-install`; keep that list in sync.
- Do not add `/etc/group` or `/etc/gshadow`; groups for the live user come
  from `airootfs/etc/sysusers.d/speedyos-live.conf`.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `unshare: write failed /proc/self/uid_map` | No `/etc/subuid`/`/etc/subgid` entry for your user: `sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $USER` |
| `error: failed to commit transaction (conflicting files)` / `exists in filesystem` | An overlay file is also owned by a package. Run `validate-profile.sh`, move the file into a package. |
| `error: target not found: <pkg>` | Package renamed or dropped upstream (e.g. `p7zip` → `7zip`). Fix `packages.x86_64`. |
| `speedyos` repo errors | Run `./scripts/build-packages.sh` to recreate `iso/custom-repo/speedyos.db`. |
| Build very slow at "Creating ... airootfs.sfs" | Normal for xz; use `--fast` while developing. |
| `Permission denied` deleting `build/work` | Use the `unshare` command above. |

The full log is always at `build/logs/latest.log`.
