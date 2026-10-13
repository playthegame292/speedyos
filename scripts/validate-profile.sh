#!/bin/bash
# SpeedyOS Profile Validation Script
# Fast, read-only checks of the archiso profile before a (slow) build.
# Needs no root and changes nothing.

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROFILE_DIR="$PROJECT_ROOT/iso/archiso-profile"
OVERLAY="$PROFILE_DIR/airootfs"
REPO_DIR="$PROJECT_ROOT/iso/custom-repo"

ERRORS=0
WARNINGS=0
ok()   { echo -e "${GREEN}✓ $*${NC}"; }
err()  { echo -e "${RED}✗ $*${NC}"; ERRORS=$((ERRORS + 1)); }
warn() { echo -e "${YELLOW}⚠ $*${NC}"; WARNINGS=$((WARNINGS + 1)); }
section() { echo ""; echo -e "${BLUE}$*${NC}"; }

echo -e "${BLUE}🐾 SpeedyOS Profile Validator${NC}"

[ -d "$PROFILE_DIR" ] || { err "Profile directory not found: $PROFILE_DIR"; exit 1; }

section "Required files"
for f in profiledef.sh packages.x86_64 pacman.conf; do
    [ -f "$PROFILE_DIR/$f" ] && ok "$f" || err "$f missing"
done

section "profiledef.sh"
if bash -n "$PROFILE_DIR/profiledef.sh"; then
    ok "syntax valid"
    # mkarchiso sources profiledef.sh inside a function: any "declare" there
    # makes a local variable that mkarchiso never sees (permissions silently
    # not applied, e.g. a world-readable /etc/shadow).
    if grep -qE '^[[:space:]]*(declare|local|typeset)[[:space:]]' "$PROFILE_DIR/profiledef.sh"; then
        err "profiledef.sh uses declare/local; variables would be function-local in mkarchiso"
    fi
    # shellcheck disable=SC1091
    # Mirror mkarchiso: it declares the associative array globally before
    # sourcing the profile.
    ( declare -A file_permissions=()
      . "$PROFILE_DIR/profiledef.sh" 2>&1 | sed 's/^/profiledef.sh: /'
      . "$PROFILE_DIR/profiledef.sh" 2>/dev/null
      [ ${#file_permissions[@]} -gt 0 ] || echo "file_permissions is empty"
      for v in iso_name iso_label install_dir; do
          [ -n "${!v:-}" ] || { echo "missing $v"; exit 1; }
      done
      # Every file_permissions entry should point at something in the overlay.
      for path in "${!file_permissions[@]}"; do
          [ -e "$OVERLAY$path" ] || echo "file_permissions: $path not in airootfs"
      done ) | while read -r line; do echo "$line"; done > "$PROJECT_ROOT/.validate.tmp"
    if [ -s "$PROJECT_ROOT/.validate.tmp" ]; then
        while read -r line; do err "$line"; done < "$PROJECT_ROOT/.validate.tmp"
    else
        ok "required variables set; file_permissions targets exist"
    fi
    rm -f "$PROJECT_ROOT/.validate.tmp"
else
    err "profiledef.sh has syntax errors"
fi

section "pacman.conf"
if grep -q '@SPEEDYOS_REPO@' "$PROFILE_DIR/pacman.conf"; then
    ok "[speedyos] repo path placeholder present (filled in by build-iso.sh)"
else
    warn "no @SPEEDYOS_REPO@ placeholder; repo path is hardcoded"
fi
if [ -f "$REPO_DIR/speedyos.db.tar.zst" ]; then
    mapfile -t REPO_PKGS < <(tar -tf "$REPO_DIR/speedyos.db.tar.zst" | sed -n 's|^\(.*\)-[^-]*-[^-]*/$|\1|p')
    ok "local repo: ${REPO_PKGS[*]}"
else
    REPO_PKGS=()
    err "local repo database missing (run scripts/build-packages.sh)"
fi

section "Package list"
mapfile -t PKGS < <(sed 's/#.*//; s/[[:space:]]//g; /^$/d' "$PROFILE_DIR/packages.x86_64")
ok "${#PKGS[@]} packages listed"
dups=$(printf '%s\n' "${PKGS[@]}" | sort | uniq -d)
[ -z "$dups" ] || err "duplicate entries: $dups"
for p in base linux mkinitcpio mkinitcpio-archiso syslinux grub calamares sddm plasma-meta; do
    printf '%s\n' "${PKGS[@]}" | grep -qx "$p" || err "essential package missing from list: $p"
done
# Resolve against the host's sync databases (may be slightly stale) plus the
# local repo. Unknown names make pacstrap fail late, so catch them here.
mapfile -t KNOWN < <(pacman -Slq 2>/dev/null)
if [ ${#KNOWN[@]} -eq 0 ]; then
    warn "host sync databases unavailable; skipped package name check"
else
    unknown=$(comm -23 <(printf '%s\n' "${PKGS[@]}" | sort -u) \
                       <(printf '%s\n' "${KNOWN[@]}" "${REPO_PKGS[@]}" | sort -u))
    if [ -n "$unknown" ]; then
        for p in $unknown; do
            # Could be a provide/group name; let pacman try to resolve it.
            pacman -Sp --print-format %n "$p" >/dev/null 2>&1 \
                && warn "$p is not a package name (resolved as provide/group)" \
                || err "$p not found in Arch repos or [speedyos]"
        done
    else
        ok "all package names exist"
    fi
fi

section "airootfs overlay"
# pacstrap runs after the overlay is copied, so a non-backup file owned by a
# package makes pacman abort with "exists in filesystem".
conflicts=0
if [ -f "$REPO_DIR/speedyos.files.tar.zst" ]; then
    mapfile -t REPO_FILES < <(tar -xOf "$REPO_DIR/speedyos.files.tar.zst" --wildcards '*/files' | grep -v '^%FILES%$' | grep -v '/$')
else
    REPO_FILES=()
fi
while IFS= read -r -d '' f; do
    rel="${f#"$OVERLAY"}"
    if printf '%s\n' "${REPO_FILES[@]}" | grep -qxF "${rel#/}"; then
        err "overlay file $rel is owned by a [speedyos] package"
        conflicts=$((conflicts + 1)); continue
    fi
    owner=$(pacman -Qqo "$rel" 2>/dev/null) || continue
    # Files in the package's backup array are fine (pacman writes .pacnew).
    pacman -Qii "$owner" | sed -n '/^Backup Files/,/^$/p' | grep -qE "(^Backup Files *: *|^ +)$rel " && continue
    [ -L "$f" ] && continue
    err "overlay file $rel is owned by package $owner (pacman conflict)"
    conflicts=$((conflicts + 1))
done < <(find "$OVERLAY" \( -type f -o -type l \) -print0)
[ $conflicts -eq 0 ] && ok "no overlay files collide with package files (checked against host + [speedyos])"

bad_sh=0
while IFS= read -r -d '' f; do
    head -c 64 "$f" | grep -q '^#!.*\(bash\|sh\)' || continue
    bash -n "$f" 2>/dev/null || { err "shell syntax error: ${f#"$PROFILE_DIR/"}"; bad_sh=$((bad_sh + 1)); }
done < <(find "$OVERLAY" -type f -print0)
[ $bad_sh -eq 0 ] && ok "overlay shell scripts parse"

[ -f "$OVERLAY/etc/group" ] && warn "airootfs/etc/group overrides Arch's group database; prefer sysusers.d"

section "Calamares configuration"
if command -v python3 >/dev/null && python3 -c 'import yaml' 2>/dev/null; then
    bad_yaml=0
    while IFS= read -r -d '' f; do
        python3 -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1]))' "$f" 2>/dev/null \
            || { err "invalid YAML: ${f#"$OVERLAY"}"; bad_yaml=$((bad_yaml + 1)); }
    done < <(find "$OVERLAY/etc/calamares" \( -name '*.conf' -o -name '*.desc' \) -print0)
    [ $bad_yaml -eq 0 ] && ok "all Calamares YAML parses"
    # Every module in the exec/show sequence that has a local config must parse,
    # and instances must point at existing files.
    python3 - "$OVERLAY/etc/calamares" <<'EOF' || ERRORS=$((ERRORS + 1))
import sys, yaml, os
base = sys.argv[1]
s = yaml.safe_load(open(os.path.join(base, "settings.conf")))
missing = [i["config"] for i in s.get("instances", [])
           if not os.path.exists(os.path.join(base, "modules", i["config"]))]
brand = os.path.join(base, "branding", s["branding"], "branding.desc")
if missing or not os.path.exists(brand):
    print("\033[0;31m✗ missing:", missing or brand, "\033[0m"); sys.exit(1)
seq = [m for step in s["sequence"] for mods in step.values() for m in mods]
print("\033[0;32m✓ sequence:", " ".join(seq), "\033[0m")
EOF
else
    warn "python3-yaml not available; skipped Calamares checks"
fi

echo ""
echo "================================"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Profile validation passed${NC} ($WARNINGS warning(s))"
    exit 0
else
    echo -e "${RED}✗ Profile validation failed: $ERRORS error(s), $WARNINGS warning(s)${NC}"
    exit 1
fi
