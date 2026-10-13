# SpeedyOS CLI Utility

The `speedy` command provides friendly, beagle-themed shortcuts for common system administration tasks on SpeedyOS.

## Installation

```bash
cd packages/speedy-cli
makepkg -si
```

## Usage

```bash
speedy help              # Show all commands
speedy update            # Update system packages
speedy install firefox   # Install packages
speedy remove firefox    # Remove packages
speedy search browser    # Search for packages
speedy info              # Show system information
speedy doctor            # Check system health
speedy clean             # Clean package cache
speedy apps              # Show useful applications
speedy welcome           # Open welcome center
speedy installer         # Launch installer (live session)
```

## Commands

### Package Management

- `speedy update` - Update all system packages (wrapper for `pacman -Syu`)
- `speedy install <pkg>` - Install one or more packages
- `speedy remove <pkg>` - Remove packages with confirmation
- `speedy search <term>` - Search for packages in repositories

### System Information

- `speedy info` - Display comprehensive system information
- `speedy version` - Show SpeedyOS version

### System Maintenance

- `speedy doctor` - Run system diagnostics and health checks
- `speedy clean` - Clean package cache (keeps 3 versions)

### Applications

- `speedy apps` - List useful applications by category
- `speedy welcome` - Open SpeedyOS Welcome Center (GUI)
- `speedy installer` - Launch Calamares installer (live session only)

## Features

- 🐾 Beagle-themed output with paw prints
- ✅ User-friendly confirmation prompts
- 🎨 Color-coded output (success/warning/error)
- 🔒 Automatic sudo elevation when needed
- 🚀 Fast and lightweight (pure Bash)

## Standard Commands Still Work

SpeedyOS commands supplement, not replace, standard Arch Linux commands:

```bash
# Both of these work:
speedy update
sudo pacman -Syu

# Both of these work:
speedy install firefox
sudo pacman -S firefox
```

---

🐾 Fast Paws. Arch Power.
