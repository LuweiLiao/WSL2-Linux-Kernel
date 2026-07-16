# WSL2 + RTL8812AU USB WiFi

中文 | [English](#english)

本分支在微软 WSL2 内核标签 `linux-msft-wsl-6.6.87.2` 上，额外加入了 out-of-tree 驱动
[`out-of-tree/rtl8812au`](../out-of-tree/rtl8812au)（来源：[morrownr/8812au-20210820](https://github.com/morrownr/8812au-20210820)），
用于在 WSL2 内通过 [usbipd-win](https://github.com/dorssel/usbipd-win) 使用 **Realtek RTL8812AU** USB 无线网卡。

This branch is based on Microsoft WSL2 kernel tag `linux-msft-wsl-6.6.87.2` and vendors the out-of-tree driver under
[`out-of-tree/rtl8812au`](../out-of-tree/rtl8812au) (from [morrownr/8812au-20210820](https://github.com/morrownr/8812au-20210820))
so you can use a **Realtek RTL8812AU** USB WiFi adapter inside WSL2 via [usbipd-win](https://github.com/dorssel/usbipd-win).

---

## 中文

### 前置条件

- Windows 10/11 + WSL2（x86_64）
- 已安装 [usbipd-win](https://github.com/dorssel/usbipd-win)
- Ubuntu（或其它）WSL 发行版，具备编译环境
- USB 网卡芯片为 **RTL8812AU**（例如常见 0bda:8812）

### 1. 获取源码

```bash
git clone -b feature/rtl8812au-6.6.87.2 --depth 1 \
  git@github.com:LuweiLiao/WSL2-Linux-Kernel.git
cd WSL2-Linux-Kernel
```

### 2. 编译内核与驱动

依赖：

```bash
sudo apt-get update
sudo apt-get install -y build-essential flex bison libssl-dev libelf-dev \
  bc dwarves pahole cpio
```

一键脚本（推荐）：

```bash
./scripts/build-rtl8812au-wsl.sh
```

或手动：

```bash
cp Microsoft/config-wsl .config
./scripts/config --enable CONFIG_CFG80211
./scripts/config --enable CONFIG_MAC80211
./scripts/config --enable CONFIG_CFG80211_WEXT
./scripts/config --disable CONFIG_CFG80211_REQUIRE_SIGNED_REGDB || true
./scripts/config --enable CONFIG_WLAN
./scripts/config --enable CONFIG_RFKILL
./scripts/config --set-str CONFIG_LOCALVERSION "-microsoft-standard-WSL2-8812au"
make olddefconfig
make -j"$(nproc)"
make modules_prepare

KREL="$(make -s kernelrelease)"
make -C out-of-tree/rtl8812au KSRC="$PWD" KVER="$KREL" -j"$(nproc)"
```

产物：

- 内核镜像：`arch/x86/boot/bzImage`
- 驱动模块：`out-of-tree/rtl8812au/8812au.ko`

### 3. 安装自定义内核到 Windows

```bash
mkdir -p /mnt/c/Users/<Windows用户名>/wsl-kernels
cp arch/x86/boot/bzImage \
  /mnt/c/Users/<Windows用户名>/wsl-kernels/bzImage-6.6.87.2-8812au
```

编辑 `%UserProfile%\.wslconfig`：

```ini
[wsl2]
kernel=C:\\Users\\<Windows用户名>\\wsl-kernels\\bzImage-6.6.87.2-8812au
```

管理员 PowerShell：

```powershell
wsl --shutdown
```

重新打开 WSL，确认：

```bash
uname -r
# 应包含：6.6.87.2-microsoft-standard-WSL2-8812au
```

### 4. 安装并加载模块（WSL 内）

```bash
KREL="$(uname -r)"
sudo mkdir -p "/lib/modules/$KREL/updates"
sudo cp out-of-tree/rtl8812au/8812au.ko "/lib/modules/$KREL/updates/"
# 若内核把 USB/usbip 编成模块，还需一并安装对应 .ko 并 depmod
sudo depmod -a "$KREL"

# 加载（按依赖顺序）
sudo modprobe usb-common 2>/dev/null || true
sudo modprobe usbcore 2>/dev/null || true
sudo modprobe usbip-core 2>/dev/null || true
sudo modprobe vhci-hcd 2>/dev/null || true
sudo modprobe 8812au || sudo insmod out-of-tree/rtl8812au/8812au.ko
```

也可把 `8812au.ko` 放到 `/usr/local/lib/modules/`，写开机脚本自动 `insmod`。

### 5. 把 USB 网卡挂进 WSL

管理员 PowerShell：

```powershell
usbipd list
# 找到 8812AU 的 BUSID（每台电脑可能不同）
usbipd bind --busid <BUSID>
usbipd attach --wsl --busid <BUSID>
```

WSL 内检查：

```bash
lsusb          # 应能看到 Realtek 8812AU
ip link        # 应出现 wlan0 或 wlx...
```

### 6. 连接 WiFi

若使用 NetworkManager：

```bash
nmcli device wifi list
nmcli device wifi connect '你的SSID' password '密码'
ip -4 addr
```

### 日常注意

| 事项 | 说明 |
|------|------|
| 重启后 | 常需重新 `usbipd attach`，并再次加载模块 |
| BUSID | 换电脑/换 USB 口后会变，以 `usbipd list` 为准 |
| 内核配套 | `8812au.ko` 必须与当前自定义 `bzImage` 一起编译，勿混用库存内核 |
| 架构 | 仅验证 x86_64 WSL2 |

### 故障排查

1. `uname -r` 没有 `8812au` → `.wslconfig` 路径错误或未 `wsl --shutdown`
2. `lsusb` 没有网卡 → 未 `attach`，或 attach 到了错误发行版
3. 有 USB 设备但无 `wlan` 接口 → 模块未加载 / 与内核 vermagic 不匹配，需重编
4. 能扫到 WiFi 但连不上 → 检查 NetworkManager/wpa_supplicant，以及路由器侧设置

---

<a id="english"></a>

## English

### Prerequisites

- Windows 10/11 with WSL2 (x86_64)
- [usbipd-win](https://github.com/dorssel/usbipd-win) installed
- A WSL distro (e.g. Ubuntu) with a build toolchain
- USB adapter based on **RTL8812AU** (commonly `0bda:8812`)

### 1. Get the source

```bash
git clone -b feature/rtl8812au-6.6.87.2 --depth 1 \
  git@github.com:LuweiLiao/WSL2-Linux-Kernel.git
cd WSL2-Linux-Kernel
```

### 2. Build kernel and driver

Dependencies:

```bash
sudo apt-get update
sudo apt-get install -y build-essential flex bison libssl-dev libelf-dev \
  bc dwarves pahole cpio
```

One-shot script (recommended):

```bash
./scripts/build-rtl8812au-wsl.sh
```

Or manually:

```bash
cp Microsoft/config-wsl .config
./scripts/config --enable CONFIG_CFG80211
./scripts/config --enable CONFIG_MAC80211
./scripts/config --enable CONFIG_CFG80211_WEXT
./scripts/config --disable CONFIG_CFG80211_REQUIRE_SIGNED_REGDB || true
./scripts/config --enable CONFIG_WLAN
./scripts/config --enable CONFIG_RFKILL
./scripts/config --set-str CONFIG_LOCALVERSION "-microsoft-standard-WSL2-8812au"
make olddefconfig
make -j"$(nproc)"
make modules_prepare

KREL="$(make -s kernelrelease)"
make -C out-of-tree/rtl8812au KSRC="$PWD" KVER="$KREL" -j"$(nproc)"
```

Artifacts:

- Kernel image: `arch/x86/boot/bzImage`
- Driver module: `out-of-tree/rtl8812au/8812au.ko`

### 3. Install the custom kernel on Windows

```bash
mkdir -p /mnt/c/Users/<WindowsUser>/wsl-kernels
cp arch/x86/boot/bzImage \
  /mnt/c/Users/<WindowsUser>/wsl-kernels/bzImage-6.6.87.2-8812au
```

Edit `%UserProfile%\.wslconfig`:

```ini
[wsl2]
kernel=C:\\Users\\<WindowsUser>\\wsl-kernels\\bzImage-6.6.87.2-8812au
```

In an elevated PowerShell:

```powershell
wsl --shutdown
```

Re-open WSL and verify:

```bash
uname -r
# should contain: 6.6.87.2-microsoft-standard-WSL2-8812au
```

### 4. Install and load the module (inside WSL)

```bash
KREL="$(uname -r)"
sudo mkdir -p "/lib/modules/$KREL/updates"
sudo cp out-of-tree/rtl8812au/8812au.ko "/lib/modules/$KREL/updates/"
sudo depmod -a "$KREL"

sudo modprobe usb-common 2>/dev/null || true
sudo modprobe usbcore 2>/dev/null || true
sudo modprobe usbip-core 2>/dev/null || true
sudo modprobe vhci-hcd 2>/dev/null || true
sudo modprobe 8812au || sudo insmod out-of-tree/rtl8812au/8812au.ko
```

### 5. Attach the USB adapter to WSL

Elevated PowerShell:

```powershell
usbipd list
usbipd bind --busid <BUSID>
usbipd attach --wsl --busid <BUSID>
```

Inside WSL:

```bash
lsusb          # Realtek 8812AU should appear
ip link        # expect wlan0 or wlx...
```

### 6. Connect to WiFi

With NetworkManager:

```bash
nmcli device wifi list
nmcli device wifi connect 'YourSSID' password 'YourPassword'
ip -4 addr
```

### Notes

| Topic | Detail |
|------|--------|
| After reboot / sleep | You often need to `usbipd attach` again and reload modules |
| BUSID | Changes per machine / USB port; always check `usbipd list` |
| Matching build | `8812au.ko` must be built against this custom `bzImage` |
| Arch | Validated on x86_64 WSL2 only |

### Troubleshooting

1. `uname -r` has no `8812au` → wrong `.wslconfig` path or forgot `wsl --shutdown`
2. `lsusb` missing the dongle → not attached, or attached to the wrong distro
3. USB seen but no `wlan` iface → module not loaded / vermagic mismatch; rebuild
4. Can scan but cannot associate → check NetworkManager/wpa_supplicant and the AP

### License / credit

- Kernel: Microsoft [WSL2-Linux-Kernel](https://github.com/microsoft/WSL2-Linux-Kernel)
- WiFi driver: [morrownr/8812au-20210820](https://github.com/morrownr/8812au-20210820) (GPL, Realtek-based)
