#!/bin/bash
# SpeedyOS VM runner (QEMU/KVM). Safe by construction: the only disk a VM
# ever sees is a qcow2 *file* under vm/, never a host block device.
#
# Usage:
#   scripts/run-vm.sh live       [options]   boot the ISO, no disk attached
#   scripts/run-vm.sh install    [options]   boot the ISO + disposable test disk
#   scripts/run-vm.sh installed  [options]   boot the test disk (after install)
#   scripts/run-vm.sh reset-disk             delete the test disk and UEFI vars
#
# Options:
#   --bios          legacy BIOS instead of UEFI (uses a separate test disk)
#   --iso PATH      ISO to boot (default: newest out/*.iso)
#   --headless      no window; VNC on 127.0.0.1:5905, QMP + guest agent sockets
#                   in vm/ (used for automated testing)
#   --mem MB        RAM (default 4096)
#   --disk-size N   size of a newly created test disk (default 40G)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VM_DIR="$PROJECT_ROOT/vm"
OVMF_CODE=/usr/share/edk2/x64/OVMF_CODE.4m.fd
OVMF_VARS_TEMPLATE=/usr/share/edk2/x64/OVMF_VARS.4m.fd

usage() { sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
fail() { echo "✗ $*" >&2; exit 1; }

mode=${1:-}; [ -n "$mode" ] || usage 1; shift
case $mode in -h|--help|help) usage ;; esac
firmware=uefi iso='' headless=0 mem=4096 disk_size=40G
while [ $# -gt 0 ]; do
    case $1 in
        --bios) firmware=bios ;;
        --iso) iso=$2; shift ;;
        --headless) headless=1 ;;
        --mem) mem=$2; shift ;;
        --disk-size) disk_size=$2; shift ;;
        -h|--help) usage ;;
        *) fail "unknown option: $1" ;;
    esac
    shift
done

mkdir -p "$VM_DIR"
DISK="$VM_DIR/speedyos-test-$firmware.qcow2"
VARS="$VM_DIR/OVMF_VARS-$firmware.4m.fd"

if [ "$mode" = reset-disk ]; then
    rm -fv -- "$VM_DIR"/speedyos-test-*.qcow2 "$VM_DIR"/OVMF_VARS-*.fd
    exit 0
fi

command -v qemu-system-x86_64 >/dev/null || fail "qemu-system-x86_64 not found (install qemu-desktop)"

if [ "$mode" != installed ] && [ -z "$iso" ]; then
    iso=$(ls -t "$PROJECT_ROOT"/out/*.iso 2>/dev/null | head -n1 || true)
    [ -n "$iso" ] || fail "no ISO in out/. Build one with scripts/build-iso.sh"
fi

args=(
    -name "SpeedyOS-test-$mode-$firmware"
    -machine q35 -m "$mem" -smp "$(( $(nproc) > 4 ? 4 : $(nproc) ))"
    -device virtio-vga -device qemu-xhci -device usb-tablet
    -nic user,model=virtio-net-pci
    -audiodev none,id=snd0 -device ich9-intel-hda -device hda-output,audiodev=snd0
    -device virtio-serial
    -rtc base=utc
)
if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    args+=(-enable-kvm -cpu host)
else
    echo "⚠ /dev/kvm not usable; falling back to slow software emulation"
fi

if [ "$firmware" = uefi ]; then
    [ -f "$OVMF_CODE" ] || fail "UEFI firmware missing (install edk2-ovmf)"
    [ -f "$VARS" ] || cp -- "$OVMF_VARS_TEMPLATE" "$VARS"
    args+=(-drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE"
           -drive "if=pflash,format=raw,file=$VARS")
fi

# Boot order is set per device (bootindex). OVMF keeps its own boot order in
# the VARS file and ignores "-boot", so after booting the disk once it would
# never boot the ISO again.
cdrom=(-drive "if=none,id=cd0,media=cdrom,readonly=on,file=$iso"
       -device "ide-cd,drive=cd0,bootindex=BOOTINDEX")
disk=(-drive "if=none,id=hd0,format=qcow2,file=$DISK"
      -device "virtio-blk-pci,drive=hd0,bootindex=BOOTINDEX")

case $mode in
    live)
        args+=("${cdrom[@]/BOOTINDEX/0}") ;;
    install)
        if [ ! -e "$DISK" ]; then
            qemu-img create -q -f qcow2 "$DISK" "$disk_size"
            echo "Created disposable test disk $DISK ($disk_size)"
        fi
        [ -f "$DISK" ] && [ ! -L "$DISK" ] || fail "$DISK must be a regular file"
        args+=("${cdrom[@]/BOOTINDEX/0}" "${disk[@]/BOOTINDEX/1}") ;;
    installed)
        [ -f "$DISK" ] || fail "no test disk yet; run '$0 install' first"
        # A fresh qcow2 is a few hundred KB; an installed system is gigabytes.
        used=$(qemu-img info --output=json "$DISK" | sed -n 's/.*"actual-size": *\([0-9]*\).*/\1/p' | head -n1)
        [ "${used:-0}" -gt 100000000 ] || fail "nothing is installed on the test disk yet.
  Run '$0 install', choose \"Install SpeedyOS\" and finish the installer first."
        args+=("${disk[@]/BOOTINDEX/0}") ;;
    *) usage 1 ;;
esac

if [ "$headless" = 1 ]; then
    rm -f "$VM_DIR/qmp.sock" "$VM_DIR/qga.sock"
    args+=(-display none -vnc 127.0.0.1:5
           -qmp "unix:$VM_DIR/qmp.sock,server=on,wait=off"
           -chardev "socket,path=$VM_DIR/qga.sock,server=on,wait=off,id=qga0"
           -device virtserialport,chardev=qga0,name=org.qemu.guest_agent.0
           -serial "file:$VM_DIR/serial.log")
    echo "Headless: VNC 127.0.0.1:5905, QMP $VM_DIR/qmp.sock, guest agent $VM_DIR/qga.sock"
else
    args+=(-display gtk,zoom-to-fit=on)
fi

echo "Booting SpeedyOS ($mode, $firmware)${iso:+ from $(basename "$iso")}"
exec qemu-system-x86_64 "${args[@]}"
