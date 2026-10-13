#!/bin/bash
# SpeedyOS package builder
# Builds the SpeedyOS packages with makepkg (as your normal user, no root)
# and refreshes the local [speedyos] repository used by the ISO build.
#
# Calamares is NOT rebuilt here: the prebuilt calamares-*.pkg.tar.zst already
# in iso/custom-repo is reused. Drop a newer one there and rerun this script
# to refresh the repository database.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPO_DIR="$PROJECT_ROOT/iso/custom-repo"
REPO_DB="$REPO_DIR/speedyos.db.tar.zst"
PACKAGES=(speedy-branding speedy-cli speedy-welcome)

echo -e "${BLUE}🐾 SpeedyOS Package Builder${NC}"
echo ""

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}✗ Do not run as root (makepkg refuses to).${NC}"
    exit 1
fi

for tool in makepkg repo-add; do
    command -v "$tool" >/dev/null || { echo -e "${RED}✗ $tool not found (pacman package)${NC}"; exit 1; }
done

mkdir -p "$REPO_DIR"

for pkg in "${PACKAGES[@]}"; do
    dir="$PROJECT_ROOT/packages/$pkg"
    echo -e "${BLUE}Building $pkg...${NC}"
    (
        cd "$dir"
        rm -f -- "$pkg"-*.pkg.tar.zst
        # --nodeps: runtime deps are resolved inside the ISO, not on the host.
        makepkg --force --cleanbuild --nodeps --noconfirm >/dev/null
    )
    built=("$dir/$pkg"-*.pkg.tar.zst)
    [ -f "${built[0]}" ] || { echo -e "${RED}✗ $pkg did not produce a package${NC}"; exit 1; }
    # Drop older versions of this package from the repo directory.
    find "$REPO_DIR" -maxdepth 1 -name "$pkg-[0-9]*.pkg.tar.zst" -delete
    cp -- "${built[@]}" "$REPO_DIR/"
    echo -e "${GREEN}✓ $(basename "${built[0]}")${NC}"
done

echo ""
echo -e "${BLUE}Refreshing repository database...${NC}"
rm -f "$REPO_DIR"/speedyos.{db,files}{,.tar.zst}{,.old}
mapfile -t repo_pkgs < <(find "$REPO_DIR" -maxdepth 1 -name '*.pkg.tar.zst' ! -name '*-debug-*' | sort)
repo-add --quiet "$REPO_DB" "${repo_pkgs[@]}"

echo ""
echo -e "${GREEN}✓ [speedyos] repository contents:${NC}"
tar -tf "$REPO_DB" | grep '/$' | sed 's|/$||; s/^/  /'
