# SpeedyOS

**Fast Paws. Arch Power.**

<img src="artwork/branding/speedyos-badge.png" alt="SpeedyOS badge" width="160">

SpeedyOS is a fast, friendly, and polished Arch Linux-based distribution inspired by bundle223's beagle. Built on the solid foundation of Arch Linux with KDE Plasma 6, SpeedyOS delivers a welcoming desktop experience with beagle-themed branding and intuitive command-line tools.

## Features

- **Arch Linux Foundation**: Rolling release with access to official Arch repositories
- **KDE Plasma 6 Desktop**: Modern, responsive, and beautiful
- **Beagle-Inspired Design**: Warm, playful branding throughout
- **Speedy Commands**: Memorable, themed CLI tools for common tasks
- **Calamares Installer**: Graphical installation experience
- **Wayland by Default**: Modern display server with X11 fallback
- **Live Environment**: Try before you install

## Quick Start

### Building the ISO (no root needed)

```bash
./scripts/check-dependencies.sh
./scripts/build-packages.sh        # speedy-* packages -> iso/custom-repo
./scripts/build-iso.sh             # release build; add --fast while developing
```

The ISO and its `.sha256` land in `out/`. Details: [docs/BUILDING.md](docs/BUILDING.md).

### Trying it

```bash
./scripts/run-vm.sh live           # boot the ISO in QEMU (UEFI)
./scripts/run-vm.sh install        # ISO + a disposable virtual disk to install to
./scripts/run-vm.sh installed      # boot the installed test disk
```

On the live desktop, use **Install SpeedyOS** (desktop icon or Welcome
Center) to start the Calamares installer. See [docs/TESTING.md](docs/TESTING.md).

## Speedy Commands

SpeedyOS includes intuitive command-line tools:

```bash
speedy help          # Show all commands
speedy update        # Update system packages
speedy install pkg   # Install packages
speedy remove pkg    # Remove packages
speedy search term   # Search for packages
speedy info          # Show system information
speedy doctor        # Check system health
speedy clean         # Clean package cache
speedy apps          # Suggested applications
speedy welcome       # Open the Welcome Center
speedy installer     # Start the installer (live session only)
speedy version       # Version information
speedy drivers       # Recommended graphics drivers
speedy snapshots     # System snapshots (Btrfs); speedy undo <n> restores one
speedy dance         # Very important
```

See [SPEEDY_COMMANDS.md](docs/SPEEDY_COMMANDS.md) for complete documentation.

## Documentation

- [Building the ISO](docs/BUILDING.md)
- [Installing SpeedyOS](docs/INSTALLING.md)
- [Speedy Commands Reference](docs/SPEEDY_COMMANDS.md)
- [Testing Guide](docs/TESTING.md)

## Project Structure

```
SpeedyOS/
├── iso/
│   ├── archiso-profile/  # Archiso profile (live overlay, Calamares config)
│   └── custom-repo/      # Local [speedyos] pacman repository
├── packages/             # SpeedyOS-specific packages
│   ├── speedy-cli/      # Command-line utility
│   ├── speedy-welcome/  # Welcome application
│   └── speedy-branding/ # Wallpapers, icons, Plasma look-and-feel, Konsole theme
├── artwork/             # Logos, wallpapers, icons
├── scripts/             # Build and validation scripts
├── vm/                  # Disposable VM disks (created by run-vm.sh, git-ignored)
└── docs/                # Documentation
```

## System Requirements

- **Architecture**: x86_64
- **RAM**: 2GB minimum, 4GB recommended
- **Storage**: 20GB minimum
- **Graphics**: Any modern GPU with KMS support
- **Firmware**: UEFI recommended, BIOS supported

## Development Status

🚧 **Early development.** See [CHANGELOG.md](CHANGELOG.md) for what has
been built and tested so far, and what has not.

## License

SpeedyOS is free and open source software. See [LICENSE](LICENSE) for details.

## Contributing

SpeedyOS is a personal project by bundle223. Contributions, suggestions, and feedback are welcome!

---

🐾 Made with love and inspired by a happy beagle
