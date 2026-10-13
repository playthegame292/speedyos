# Speedy Commands

`speedy` is SpeedyOS's command-line companion. Every command is a thin,
readable wrapper around a standard Arch tool, and it prints the exact
command it runs, so you can always do the same thing by hand.

```
speedy <command> [arguments]
```

| Command | What it does | Runs |
|---|---|---|
| `speedy help` | List commands | — |
| `speedy version` | speedy, SpeedyOS and kernel versions | — |
| `speedy info` | System overview: mode (live/installed), kernel, CPU, memory, disk, package count | — |
| `speedy update` | Full system upgrade, then AUR packages and Flatpak apps if there are any | `sudo pacman -Syu`, `yay -Sua`, `flatpak update` |
| `speedy install <pkg...>` | Install packages (skips ones already installed). Names not in the Arch repositories are looked up in the AUR; after a warning and confirmation they are built with yay | `sudo pacman -S --needed`, `yay -S --aur --needed` |
| `speedy remove <pkg...>` | Explain, ask for confirmation, then remove packages and dependencies nothing else needs | `sudo pacman -Rs` |
| `speedy search <term...>` | Search the repositories | `pacman -Ss` |
| `speedy clean` | Show how much the cache would shrink, ask, then keep the 2 newest versions of each package and drop uninstalled ones | `sudo paccache -rk2`, `sudo paccache -ruk0` |
| `speedy doctor` | Health check (see below) | read-only |
| `speedy apps` | Suggested applications by category | — |
| `speedy welcome` | Open the SpeedyOS Welcome Center | `speedyos-welcome` |
| `speedy installer` | Start Calamares (live session only) | `speedyos-installer` |
| `speedy drivers [install]` | Detect graphics hardware and show (or install) the recommended drivers. NVIDIA GTX 16xx/RTX and newer: `nvidia-open`; GTX 900/1000 era: the 580xx driver from the AUR | `lspci`, `sudo pacman -S --needed` |
| `speedy snapshots` | List Btrfs snapshots | `sudo snapper -c root list` |
| `speedy snapshot [text]` | Take a snapshot now | `sudo snapper -c root create` |
| `speedy undo <number>` | Put system files back as they were in a snapshot (takes a safety snapshot first; asks) | `sudo snapper -c root undochange N..0` |

| `speedy dance [seconds]` | Speedy, in glasses, dances in rainbow colors until you press a key (or for the given seconds) | — |
| `speedy tricks` | Other things Speedy can do (bark, sit, fetch, treat, ...) | — |

Aliases: `upgrade` = `update`, `uninstall` = `remove`, `rollback` = `undo`.

## Update notifications

`speedy-update-check.timer` (a systemd user timer, enabled for everyone by
the installer) runs `checkupdates` 15 minutes after login and every 6 hours.
When updates are waiting, a notification offers **Update now**, which runs
`speedy update` in Konsole. Turn it off with
`systemctl --user disable --now speedy-update-check.timer`.

There are also a few unlisted commands, and the Welcome Center has secrets
of its own. Spoilers are in the source.

## Safety rules

- Package names are checked against Arch's naming rules
  (`[a-z0-9@_+][a-z0-9@._+-]*`) before anything runs. Names starting with
  `-` are rejected, so arguments can never turn into pacman options.
- Arguments are passed to pacman as a list; nothing is evaluated by a shell.
- `remove` and `clean` always ask first and need a terminal to do so.
- `speedy installer` refuses to run on an installed system.
- SpeedyOS does **not** alias bare words like `install` or `info`; those
  are real commands (`install(1)`, `info(1)`).

## `speedy doctor`

Read-only checks. Each problem comes with a next step:

- package database consistency (`pacman -Dk`) and stale pacman locks
- failed systemd units
- root filesystem usage (warns at 90%)
- orphaned packages (informational)
- network: NetworkManager state and DNS resolution
- pending updates (installed systems, needs `pacman-contrib`)

Exit code is 0 when no issues are found, 1 otherwise.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | Error, invalid input, failed pacman run, or doctor found issues |
| 2 | Unknown command |

## Output

Colors are used only on a terminal and are disabled by `NO_COLOR=1`. The
paw and check-mark glyphs fall back to plain ASCII on the Linux console
(`TERM=linux`) and in non-UTF-8 locales.

## Plain Arch equivalents

`speedy` is optional. Everything is standard Arch Linux underneath; see the
[ArchWiki pacman page](https://wiki.archlinux.org/title/Pacman).
