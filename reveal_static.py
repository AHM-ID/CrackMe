#!/usr/bin/env python3
# Extract all printable strings obtained by XORing file bytes with 0xAA.
# Usage: ./reveal_static.py <binary>
# Output: unique decoded strings (printable), sorted by length (desc), with offsets and VA if available.

import sys
import subprocess
import string

if len(sys.argv) != 2:
    print("Usage: reveal_all_decoded.py <binary>")
    sys.exit(1)

BIN = sys.argv[1]
KEY = 0xAA
MIN_LEN = 4      # minimum length to report
MAX_LEN = 1024   # safety cap per sequence

# read file
try:
    with open(BIN, "rb") as f:
        data = f.read()
except Exception as e:
    print(f"[-] Error reading {BIN}: {e}")
    sys.exit(1)

n = len(data)
print(f"[+] Scanning {BIN} ({n} bytes) for XOR-0x{KEY:02x} printable sequences...")

# get .text vma and fileoff for VA reporting
def get_text_mapping(binfile):
    try:
        out = subprocess.check_output(["objdump", "-h", binfile], text=True, stderr=subprocess.DEVNULL)
    except Exception:
        return None, None
    for line in out.splitlines():
        parts = line.split()
        if len(parts) >= 6 and parts[1] == ".text":
            try:
                vma = int(parts[3], 16)
                foff = int(parts[5], 16)
                return vma, foff
            except Exception:
                return None, None
    return None, None

vma, foff = get_text_mapping(BIN)
if vma and foff:
    print(f"[+] .text mapping found: VMA=0x{vma:x} fileoff=0x{foff:x}")
else:
    print("[+] .text mapping not found (VA reporting will be N/A)")

printable = set(bytes(string.printable, "ascii"))

# decode at an offset until non-printable or null or max len
def decode_from(off):
    out = bytearray()
    for i in range(min(MAX_LEN, n - off)):
        b = data[off + i] ^ KEY
        if b == 0:     # stop at null terminator
            break
        if b < 32 or b > 126:  # non-printable ASCII
            break
        out.append(b)
    if len(out) >= MIN_LEN:
        return out.decode("latin1")
    return None

# collect longest decoded starting at each offset
candidates = {}
for off in range(0, n):
    s = decode_from(off)
    if s:
        # keep only if it's the longest seen for this start
        prev = candidates.get(off)
        if prev is None or len(s) > len(prev):
            candidates[off] = s

if not candidates:
    print("[-] No decoded printable sequences found.")
    sys.exit(1)

# remove duplicates and substrings: keep the longest occurrence of identical strings
unique_map = {}
for off, s in candidates.items():
    # if same string already exists, keep one with smallest offset (or keep first)
    if s not in unique_map or off < unique_map[s]:
        unique_map[s] = off

# build list of (offset, string) and sort by length desc, then offset asc
result = [(off, s) for s, off in unique_map.items()]
result.sort(key=lambda x: (-len(x[1]), x[0]))

# print results
print("\nFound decoded sequences (sorted by length):")
print(f"{'Len':>4}  {'FileOff':>10}  {'VA':>12}  {'String'}")
print("-" * 80)
for off, s in result:
    va_str = "N/A"
    if vma and foff and off >= foff:
        va = vma + (off - foff)
        va_str = f"0x{va:x}"
    print(f"{len(s):4}  0x{off:08x}  {va_str:12}  {s}")
print("-" * 80)
print(f"[+] {len(result)} unique decoded sequences found.")
