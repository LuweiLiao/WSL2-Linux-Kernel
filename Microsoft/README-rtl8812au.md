# Building WSL2 kernel with RTL8812AU

Base tag: `linux-msft-wsl-6.6.87.2`

Driver path: `out-of-tree/rtl8812au` (morrownr 8812au-20210820)

## Build on Ubuntu (inside WSL)

```bash
sudo apt-get update
sudo apt-get install -y build-essential flex bison libssl-dev libelf-dev bc dwarves pahole

cd /path/to/WSL2-Linux-Kernel
cp Microsoft/config-wsl .config
# enable wireless stack (cfg80211/mac80211) if building 8812au as module
./scripts/config --enable CONFIG_CFG80211
./scripts/config --enable CONFIG_MAC80211
./scripts/config --enable CONFIG_CFG80211_WEXT
./scripts/config --set-str CONFIG_LOCALVERSION "-microsoft-standard-WSL2-8812au"
make olddefconfig
make -j"$(nproc)"
make modules_prepare

# build driver against this tree
make -C out-of-tree/rtl8812au KSRC="$PWD" KVER="$(make -s kernelrelease)" -j"$(nproc)"

# install kernel image for WSL
mkdir -p /mnt/c/Users/$USER/wsl-kernels
cp arch/x86/boot/bzImage /mnt/c/Users/$USER/wsl-kernels/bzImage-6.6.87.2-8812au
```

Point `%UserProfile%\.wslconfig` at that `bzImage`, then `wsl --shutdown`.

Load modules / attach USB with `usbipd` as usual.
