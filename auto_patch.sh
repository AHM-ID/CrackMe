#!/usr/bin/env bash
# find 'call strcmp' then patch the following 'jne' to NOPs
# Usage: ./auto_patch.sh <binary>
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <binary>"
  exit 1
fi

BIN="$1"
if [ ! -f "$BIN" ]; then
  echo "File not found: $BIN"
  exit 1
fi

BACKUP="${BIN}.$(date +%s).bak"
cp -- "$BIN" "$BACKUP"
echo "[+] backup saved as $BACKUP"

DIS=$(mktemp)
objdump -d "$BIN" > "$DIS"

CALL_LINE=$(grep -nE "call.*<strcmp@plt>" "$DIS" | head -n1 | cut -d: -f1 || true)
if [ -z "$CALL_LINE" ]; then
  echo "[-] Could not find 'call ... <strcmp@plt>' in disassembly."
  rm -f "$DIS"
  exit 2
fi

echo "[+] found call strcmp at disassembly line $CALL_LINE"

JNE_LINE=$(tail -n +$CALL_LINE "$DIS" | grep -nE "^[[:space:]]*[0-9a-f]+:.*\bjne\b" | head -n1 | cut -d: -f1)
if [ -z "$JNE_LINE" ]; then
  echo "[-] Could not find 'jne' after the strcmp call."
  rm -f "$DIS"
  exit 3
fi

JNE_LINE_ABS=$(( CALL_LINE + JNE_LINE - 1 ))
JNE_TEXT=$(sed -n "${JNE_LINE_ABS}p" "$DIS")
echo "[+] found JNE line: $JNE_LINE_ABS : $JNE_TEXT"

JNE_VA_HEX=$(echo "$JNE_TEXT" | awk '{print $1}' | tr -d ':')
JNE_VA=$((0x$JNE_VA_HEX))
echo "[+] JNE VA = 0x$(printf '%x' $JNE_VA) ($JNE_VA_HEX)"

TEXT_LINE=$(objdump -h "$BIN" | awk '/\.text/ {print; exit}')
if [ -z "$TEXT_LINE" ]; then
  echo "[-] Could not find .text section mapping"
  rm -f "$DIS"
  exit 4
fi

TEXT_VMA_HEX=$(echo "$TEXT_LINE" | awk '{print $4}')
TEXT_FOFF_HEX=$(echo "$TEXT_LINE" | awk '{print $6}')
TEXT_VMA=$((0x$TEXT_VMA_HEX))
TEXT_FOFF=$((0x$TEXT_FOFF_HEX))
echo "[+] .text VMA=0x$(printf '%x' $TEXT_VMA) fileoff=0x$(printf '%x' $TEXT_FOFF)"

FILE_OFF=$(( JNE_VA - TEXT_VMA + TEXT_FOFF ))
echo "[+] computed file offset = 0x$(printf '%x' $FILE_OFF) ($FILE_OFF)"

printf '\x90\x90' | dd of="$BIN" bs=1 seek=$FILE_OFF conv=notrunc status=none

echo "[+] wrote NOPs at file offset"

echo "[+] verification (hexdump around offset):"
xxd -s $FILE_OFF -l 16 "$BIN"

echo "[+] done. To revert: mv $BACKUP $BIN"
rm -f "$DIS"