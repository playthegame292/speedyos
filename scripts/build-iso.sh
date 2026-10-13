#!/bin/bash
# SpeedyOS ISO Build Script
# Builds the bootable ISO with mkarchiso, WITHOUT root.
#
# archiso >= 80 supports rootless builds: mkarchiso runs pacstrap and the
# image tools inside a user namespace (unshare --map-auto), using the
# subordinate IDs from /etc/subuid and /etc/subgid. Nothing on the host
# system is modified; everything happens under build/ and out/.
#
# Usage: scripts/build-iso.sh [--fast]
#   --fast   zstd-compressed root image: builds several times faster, ISO is
#            ~20% larger. For development; release ISOs use the profile's xz.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROFILE_DIR="$PROJECT_ROOT/iso/archiso-profile"
REPO_DIR="$PROJECT_ROOT/iso/custom-repo"
BUILD_DIR="$PROJECT_ROOT/build"
WORK_DIR="$BUILD_DIR/work"
LOG_DIR="$BUILD_DIR/logs"
OUT_DIR="$PROJECT_ROOT/out"

fail() { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }

FAST=0
for arg in "$@"; do
    case $arg in
        --fast) FAST=1 ;;
        -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) fail "unknown option: $arg" ;;
    esac
done

echo -e "${BLUE}🐾 SpeedyOS ISO Builder${NC}"
echo ""

[ "$EUID" -ne 0 ] || fail "Do not run as root. This build is rootless (user namespaces)."
command -v mkarchiso >/dev/null || fail "mkarchiso not found. Run scripts/check-dependencies.sh"
unshare --map-auto --map-root-user true 2>/dev/null \
    || fail "User namespaces with --map-auto do not work. Check that $USER has entries in /etc/subuid and /etc/subgid."

# Validate first; it is fast and catches the common mistakes.
"$SCRIPT_DIR/validate-profile.sh" || fail "Profile validation failed; fix the errors above first."
echo ""

# Files created inside the namespace belong to subordinate IDs, so the old
# work dir has to be removed from inside a namespace as well.
if [ -d "$WORK_DIR" ]; then
    echo -e "${YELLOW}⚠ Removing previous work directory...${NC}"
    unshare --map-auto --map-root-user rm -rf -- "$WORK_DIR"
fi
mkdir -p "$WORK_DIR" "$LOG_DIR" "$OUT_DIR"

# The profile's pacman.conf has a placeholder for the local repo path, so the
# project can live anywhere.
PACMAN_CONF="$BUILD_DIR/pacman.conf"
# Package cache: a writable project-local cache first (rootless pacstrap
# can't write the host's root-owned cache), then the host cache read-only.
PKG_CACHE="$BUILD_DIR/pkgcache"
mkdir -p "$PKG_CACHE"
# Local packages are often rebuilt without a version bump; never reuse them.
rm -f "$PKG_CACHE"/speedy-*.pkg.tar.zst
sed -e "s|@SPEEDYOS_REPO@|$REPO_DIR|" \
    -e "/^\[options\]/a CacheDir = $PKG_CACHE/\nCacheDir = /var/cache/pacman/pkg/" \
    "$PROFILE_DIR/pacman.conf" > "$PACMAN_CONF"
[ -f "$REPO_DIR/speedyos.db" ] || fail "Local repo database missing. Run scripts/build-packages.sh"

if [ "$FAST" = 1 ]; then
    # Build from a staged copy so the real profile keeps release settings.
    STAGED="$BUILD_DIR/profile"
    rm -rf "$STAGED"
    cp -a "$PROFILE_DIR" "$STAGED"
    sed -i "s/^airootfs_image_tool_options=.*/airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '6' '-b' '1M')/" "$STAGED/profiledef.sh"
    PROFILE_DIR="$STAGED"
    echo -e "${YELLOW}⚠ Fast build: zstd root image (development only)${NC}"
fi

# Keep (don't overwrite) an earlier ISO that has the same name.
# shellcheck disable=SC1091
iso_name=$(declare -A file_permissions=(); . "$PROFILE_DIR/profiledef.sh"; echo "${iso_name}-${iso_version}-x86_64.iso")
if [ -e "$OUT_DIR/$iso_name" ]; then
    mkdir -p "$OUT_DIR/previous"
    stamp=$(date -r "$OUT_DIR/$iso_name" +%H%M%S)
    echo -e "${YELLOW}⚠ Moving existing $iso_name to out/previous/ (suffix $stamp)${NC}"
    mv -- "$OUT_DIR/$iso_name" "$OUT_DIR/previous/${iso_name%.iso}-$stamp.iso"
    [ -e "$OUT_DIR/$iso_name.sha256" ] && mv -- "$OUT_DIR/$iso_name.sha256" "$OUT_DIR/previous/${iso_name%.iso}-$stamp.iso.sha256"
fi

LOG_FILE="$LOG_DIR/build-$(date +%Y%m%d-%H%M%S).log"
ln -sfn "$(basename "$LOG_FILE")" "$LOG_DIR/latest.log"

echo -e "${BLUE}Building SpeedyOS ISO...${NC}"
echo "  Profile: $PROFILE_DIR"
echo "  Work:    $WORK_DIR"
echo "  Output:  $OUT_DIR"
echo "  Log:     $LOG_FILE"
echo ""
echo "This downloads ~1.5 GB of packages and usually takes 15-40 minutes."
echo ""

start=$(date +%s)
if ! mkarchiso -v -C "$PACMAN_CONF" -w "$WORK_DIR" -o "$OUT_DIR" "$PROFILE_DIR" 2>&1 | tee "$LOG_FILE"; then
    echo ""
    echo -e "${RED}✗ mkarchiso failed. Last errors:${NC}"
    grep -iE 'error|failed|conflict' "$LOG_FILE" | tail -n 15 || true
    echo ""
    echo "Full log: $LOG_FILE   (see docs/BUILDING.md, 'Troubleshooting')"
    exit 1
fi

ISO_FILE="$OUT_DIR/$iso_name"
[ -f "$ISO_FILE" ] || fail "mkarchiso finished but $ISO_FILE was not created."

(cd "$OUT_DIR" && sha256sum "$iso_name" > "$iso_name.sha256")
(cd "$OUT_DIR" && sha256sum --quiet -c "$iso_name.sha256") || fail "Checksum verification failed."

elapsed=$(( $(date +%s) - start ))
echo ""
echo -e "${GREEN}✓ ISO built in $((elapsed / 60))m $((elapsed % 60))s${NC}"
echo "  File:   $ISO_FILE"
echo "  Size:   $(du -h "$ISO_FILE" | cut -f1)"
echo "  SHA256: $(cut -d' ' -f1 "$ISO_FILE.sha256")"
echo ""
echo "Test it in a VM:  scripts/run-vm.sh live"
echo -e "${GREEN}🐾 Fast Paws. Arch Power.${NC}"
