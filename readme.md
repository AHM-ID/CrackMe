# CrackMe — IUST

## Overview

A compact reverse-engineering challenge. The binary expects one command-line argument and compares it against a hidden password stored in the program, obfuscated by XOR with `0xAA`.

Goals: static analysis, runtime inspection, and safe binary patching (NOP the conditional jump).

---

## Prerequisites

* Linux (RHEL-based recommended but not required)
* Tools: `gcc`, `objdump`, `xxd`, `readelf`, `make`, `dd`, `python3`, `bash`
* Optional: `radare2` / `r2`, `gdb`, `flatpak` (for Cutter), `ghidra` (jar)

---

## Clone repository

```bash
# clone the repo
git clone https://github.com/AHM-ID/crackme-iust.git
cd crackme-iust
```

---

## Install dependencies

### Rocky / RHEL / CentOS (dnf)

```bash
sudo dnf update -y
sudo dnf install -y gcc binutils gdb python3 xxd readelf coreutils
# optional tools
sudo dnf install -y radare2
# for Cutter/Ghidra you may need flatpak or Java
sudo dnf install -y flatpak java-17-openjdk
```

### Debian / Ubuntu (apt)

```bash
sudo apt update
sudo apt install -y build-essential binutils gdb python3 xxd elfutils
# optional tools
sudo apt install -y radare2
sudo apt install -y openjdk-17-jdk
```

> Note: `xxd` is part of `vim-common` on some distros. Use your package manager to install if missing.

---

## Build & Usage with Makefile

### Build the binary
```bash
make build
```
This compiles with optimizations, strips symbols, and makes the binary executable.

### Clean build artifacts
```bash
make clean
```

### Run with correct password
```bash
make run
```

### Patch the binary (NOP the jump)
```bash
make patch
```
This automatically creates a backup and patches the binary.

---

## Quick workflow for students

1. **Build**: `make build`
2. **Inspect (static)**: `./reveal_static.py ./crackme` — find decoded candidate strings
3. **Test known password**: `make run` or `./crackme IUST-CE-1404`
4. **Patch**: `make patch` → run patched binary with any password

---

## Manual Tools Usage

```bash
# Make tools executable
chmod +x reveal_static.py auto_patch.sh

# Static scan to reveal candidate strings (XOR 0xAA)
./reveal_static.py ./crackme

# Auto patch the binary (creates backup)
./auto_patch.sh ./crackme

# Test patched binary
./crackme anypassword
```

---

## Security & Ethics

Use this repository only for educational purposes. Do not reverse-engineer or patch binaries you do not own or do not have explicit permission to analyze.