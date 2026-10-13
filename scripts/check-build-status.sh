#!/bin/bash
# Show whether an ISO build is running, its current step, and the newest ISO.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WORK_DIR="$PROJECT_ROOT/build/work"
LOG="$PROJECT_ROOT/build/logs/latest.log"
OUT_DIR="$PROJECT_ROOT/out"

echo "🐾 SpeedyOS Build Status"
echo ""

if pgrep -u "$USER" -f mkarchiso >/dev/null; then
    echo "✓ Build is running"
    [ -d "$WORK_DIR" ] && echo "  Work directory: $(du -sh "$WORK_DIR" 2>/dev/null | cut -f1)"
    if [ -f "$LOG" ]; then
        step=$(grep -a 'INFO:' "$LOG" | tail -n1 | sed 's/.*INFO: //')
        echo "  Current step:   ${step:-starting}"
    fi
    sfs="$WORK_DIR/iso/speedyos/x86_64/airootfs.sfs"
    [ -f "$sfs" ] && echo "  Root image:     $(du -h "$sfs" | cut -f1) written so far"
else
    echo "✗ No build running"
    [ -f "$LOG" ] && echo "  Last log: $LOG"
fi

echo ""
newest=$(ls -t "$OUT_DIR"/*.iso 2>/dev/null | head -n1)
if [ -n "$newest" ]; then
    echo "Newest ISO: $newest ($(du -h "$newest" | cut -f1), $(date -r "$newest" '+%Y-%m-%d %H:%M'))"
else
    echo "No ISO in $OUT_DIR yet"
fi
