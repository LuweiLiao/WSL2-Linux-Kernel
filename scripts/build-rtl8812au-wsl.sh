#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
JOBS="$(nproc)"
if [ ! -f .config ]; then
  cp Microsoft/config-wsl .config
fi
./scripts/config --enable CONFIG_CFG80211
./scripts/config --enable CONFIG_MAC80211
./scripts/config --enable CONFIG_CFG80211_WEXT
./scripts/config --disable CONFIG_CFG80211_REQUIRE_SIGNED_REGDB || true
./scripts/config --enable CONFIG_WLAN
./scripts/config --enable CONFIG_RFKILL
./scripts/config --set-str CONFIG_LOCALVERSION "-microsoft-standard-WSL2-8812au"
make olddefconfig
make -j"${JOBS}"
make modules_prepare
KREL="$(make -s kernelrelease)"
make -C out-of-tree/rtl8812au KSRC="$ROOT" KVER="$KREL" -j"${JOBS}"
echo "kernelrelease: $KREL"
echo "bzImage: $ROOT/arch/x86/boot/bzImage"
echo "module:  $(find out-of-tree/rtl8812au -name 8812au.ko | head -n1)"
