#!/bin/bash
# SpeedyOS Build Dependency Checker
# Verifies all required packages and tools are available

set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐾 SpeedyOS Dependency Checker${NC}"
echo ""

MISSING_DEPS=()
MISSING_AUR=()
ALL_OK=true

# Check if running on Arch Linux
check_arch_linux() {
    if [ ! -f /etc/arch-release ]; then
        echo -e "${RED}✗ Not running on Arch Linux${NC}"
        echo "  SpeedyOS must be built on Arch Linux"
        exit 1
    fi
    echo -e "${GREEN}✓ Running on Arch Linux${NC}"
}

# Check for required official packages
check_package() {
    local pkg=$1
    if pacman -Qi "$pkg" &> /dev/null; then
        echo -e "${GREEN}✓ $pkg${NC}"
        return 0
    else
        echo -e "${RED}✗ $pkg${NC}"
        MISSING_DEPS+=("$pkg")
        ALL_OK=false
        return 1
    fi
}

# Check for AUR packages
check_aur_package() {
    local pkg=$1
    if pacman -Qi "$pkg" &> /dev/null; then
        echo -e "${GREEN}✓ $pkg (AUR)${NC}"
        return 0
    else
        echo -e "${YELLOW}✗ $pkg (AUR - will be needed)${NC}"
        MISSING_AUR+=("$pkg")
        return 1
    fi
}

# Check for commands/tools
check_command() {
    local cmd=$1
    local pkg=$2
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓ $cmd${NC}"
        return 0
    else
        echo -e "${RED}✗ $cmd (from $pkg)${NC}"
        MISSING_DEPS+=("$pkg")
        ALL_OK=false
        return 1
    fi
}

echo "Checking system compatibility..."
check_arch_linux
echo ""

echo "Checking core build tools..."
check_package "archiso"
check_package "arch-install-scripts"
check_package "squashfs-tools"
check_package "libisoburn"
check_package "dosfstools"
check_package "e2fsprogs"
check_package "mtools"
check_package "libarchive"
check_package "erofs-utils"
echo ""

echo "Checking optional but recommended packages..."
check_package "qemu-desktop" || echo "  (Recommended for testing with run_archiso)"
check_package "edk2-ovmf" || echo "  (Recommended for UEFI emulation testing)"
check_package "grub" || echo "  (Recommended for GRUB support)"
echo ""

echo "Checking development tools..."
check_command "git" "git"
check_command "make" "make"
check_command "bash" "bash"
echo ""

echo "Checking rootless build support..."
if grep -q "^$USER:" /etc/subuid 2>/dev/null && grep -q "^$USER:" /etc/subgid 2>/dev/null \
        && unshare --map-auto --map-root-user true 2>/dev/null; then
    echo -e "${GREEN}✓ user namespaces with subordinate IDs${NC}"
else
    echo -e "${RED}✗ no working /etc/subuid + /etc/subgid entry for $USER${NC}"
    echo "  Fix: sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $USER"
    ALL_OK=false
fi
echo ""

echo "Checking artwork/validation helpers..."
check_package "python-pillow" || true
check_package "python-yaml" || true
echo ""

echo "Checking prebuilt Calamares package (not installed on the host)..."
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/iso/custom-repo"
if ls "$REPO_DIR"/calamares-[0-9]*.pkg.tar.zst >/dev/null 2>&1; then
    echo -e "${GREEN}✓ $(basename "$(ls "$REPO_DIR"/calamares-[0-9]*.pkg.tar.zst | head -n1)")${NC}"
else
    echo -e "${YELLOW}⚠ no calamares package in iso/custom-repo (see docs/BUILDING.md)${NC}"
    MISSING_AUR+=("calamares")
fi
echo ""

# Summary
echo "================================"
if [ "$ALL_OK" = true ] && [ ${#MISSING_AUR[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ All dependencies satisfied!${NC}"
    echo ""
    echo "You're ready to build SpeedyOS!"
    echo "Run: ./scripts/build-iso.sh"
    exit 0
elif [ "$ALL_OK" = true ]; then
    echo -e "${YELLOW}⚠ Core dependencies satisfied${NC}"
    echo ""
    echo "Missing prebuilt packages (needed for the installer):"
    for pkg in "${MISSING_AUR[@]}"; do
        echo "  - $pkg"
    done
    echo ""
    echo "Build them with makepkg from the AUR PKGBUILD and copy the"
    echo "package into iso/custom-repo/ (see docs/BUILDING.md)."
    exit 0
else
    echo -e "${RED}✗ Missing dependencies${NC}"
    echo ""
    if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
        echo "Install missing packages:"
        echo "  sudo pacman -S ${MISSING_DEPS[*]}"
        echo ""
    fi
    exit 1
fi
