# Ubuntu 22.04 BBRv2 Kernel Builder

A specialized Bash script to compile and install Google's **TCP BBRv2 Alpha** kernel on **Ubuntu 22.04 (Jammy Jellyfish)**.

## 🛑 The Problem
Ubuntu 22.04 ships with `pahole` v1.24+. Google's BBRv2 alpha branch is based on Linux Kernel 5.13. 
Compiling Kernel 5.13 with `pahole` v1.24+ results in `FAILED: load BTF from vmlinux: Invalid argument` due to new BTF `ENUM64` tags that the older kernel cannot parse.

## ✅ The Solution
This script automates the entire process:
1.  **Dependencies:** Installs build tools (`build-essential`, `bison`, `flex`, etc.).
2.  **Downgrade:** Manually fetches and installs `pahole` v1.22 (and `dwarves`) to ensure BTF compatibility.
3.  **Clone:** Pulls the specific `v2alpha` branch from Google.
4.  **Config:** Copies your existing system config, disables signing keys (to prevent build errors), and enables BBRv2 modules.
5.  **Build:** Uses `bindeb-pkg` to create clean `.deb` packages (image, headers, libc-dev).
6.  **Install:** Automatically installs the generated packages.

## 🚀 Usage

Note: You should be a sudoer first.

``` shell
./local-install.sh
```
