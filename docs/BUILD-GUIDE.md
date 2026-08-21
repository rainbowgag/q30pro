# Q30 PRO 定制 OpenWrt 固件 — 编译指南（写给未来的 Codex / 维护者）

> 本文件是「如何从零、一次性编译出可用固件」的完整操作手册，包含本次项目中踩过的所有坑与经验总结。
> 目标：换一台 VPS、拿到本仓库链接，就能按本文档重新编译出 Q30 PRO 固件；并能快速迁移到其它设备（如 Redmi AX6）。

---

## 0. 一句话原理

本项目的「源码」其实是 **Kwrt 编排层 + 本仓库的定制层（configs/ + scripts/）**。真正的编译在远程 VPS 上完成：

```
本仓库(q30pro)  →  scripts/build-kwrt.sh
                  ├─ 拉取 Kwrt 仓库(25.12，提供 devices/ 编排层)
                  ├─ 拉取 openwrt/openwrt 源码(openwrt-25.12)
                  ├─ 执行 Kwrt 的 diy.sh + patches
                  ├─ 应用本仓库 configs/apply-custom.sh（.config + files 覆盖）
                  └─ make defconfig && make
                         └─ bin/targets/mediatek/filogic/*jcg_q30-pro*.bin
```

本仓库不保存 openwrt 源码，只保存「定制产物」，保证可复现。

---

## 1. 目录结构

```
q30pro/
├── AGENTS.md              # 项目规则（硬性需求）
├── HANDOFF.md             # 交接记录（当前进度）
├── README.md
├── docs/
│   ├── ARCHITECTURE.md    # 架构说明
│   └── BUILD-GUIDE.md     # 本文件
├── configs/
│   ├── custom.config      # 追加到 .config 的包/单 profile
│   ├── apply-custom.sh    # VPS 端定制脚本（核心）
│   ├── files/             # OpenWrt files/ 覆盖（见 §4）
│   ├── diffconfig/        # .config 快照（参考）
│   └── reference/         # 参考机采集结果
└── scripts/
    ├── build-kwrt.sh      # ★ 主构建脚本
    ├── build-full.sh      # 在已有源码树上重编译完整版（迭代用）
    ├── build-minimal.sh   # 二分定位用（无 openclash/files）
    ├── build-b1.sh        # 二分定位用（完整包无 files）
    ├── vps.py             # 远程 VPS 执行命令
    ├── vps-put.py         # 上传文件到 VPS
    ├── vps-get.py         # 从 VPS 下载文件
    └── diag-bootloop.py   # 反复 SSH 抓崩溃日志（备用）
```

---

## 2. 构建前置条件（VPS）

- Linux（推荐 Ubuntu 24.04 x86_64）
- 磁盘 ≥ 80G（全量编译需要约 50~75G）
- 内存 ≥ 6G + 建议 8G swap（编译大包时内存吃紧）
- 已安装 OpenWrt 编译依赖（gcc/clang/llvm/qemu-utils/python 等）

依赖安装参考：

```bash
apt update && apt install -y build-essential clang flex bison g++ gawk \
  gcc-multilib g++-multilib gettext git libncurses-dev libssl-dev \
  python3 python3-dev python3-pip python3-setuptools rsync swig unzip \
  zlib1g-dev file wget cpio curl jq qemu-utils
```

建 swap（内存不足时）：

```bash
fallocate -l 8G /swapfile && chmod 600 /swapfile \
  && mkswap /swapfile && swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

---

## 3. 一键构建流程（新 VPS）

### 3.1 克隆本仓库

```bash
git clone https://github.com/rainbowgag/q30pro.git /root/q30-build
cd /root/q30-build
```

> 注意：本仓库必须放在 `/root/q30-build`（或设置 `BUILD_ROOT` 环境变量指向它），因为 `build-kwrt.sh` 默认以它为构建根。

### 3.2 运行主构建脚本

```bash
# 只准备环境不编译（可选，用于首次验证 feeds/依赖）
# BUILD_ROOT=/root/q30-build PREPARE_ONLY=1 bash scripts/build-kwrt.sh

# 完整编译（后台运行）
cd /root/q30-build
setsid bash scripts/build-kwrt.sh > build.log 2>&1 < /dev/null &
```

监控进度：

```bash
tail -30 /root/q30-build/build.log
ps aux | grep make | grep -v grep
```

### 3.3 产物

```
/root/q30-build/openwrt/bin/targets/mediatek/filogic/
├── kwrt-mediatek-filogic-jcg_q30-pro-squashfs-sysupgrade.bin   # LuCI 页面升级
├── kwrt-mediatek-filogic-jcg_q30-pro-squashfs-factory.bin     # uboot 刷入
└── kwrt-mediatek-filogic-jcg_q30-pro-initramfs-kernel.bin     # 救援/调试
```

下载回本地并校验 SHA256（`cat .../sha256sums`）。

---

## 4. 定制产物说明（configs/）

### 4.1 custom.config —— 单 profile + 包

```
CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_jcg_q30-pro=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_ruby-psych=y
```

- 单 profile：只编译 `jcg_q30-pro`，`ALL_PROFILES=n`（apply-custom.sh 里 sed）。
- `ruby-psych`：openclash-editor 需要 Ruby YAML 支持。

### 4.2 apply-custom.sh —— 定制脚本（核心）

按顺序做了这些事（每一条都是踩坑后固化的）：

1. **补建 kiddin9 feed 软链接**：Kwrt 的 `feeds install` 会漏建 `package/feeds/kiddin9`，导致包不进 Kconfig。手动 `ln -sfn`，并排除 `zabbix-ssl`/`zabbix-extra-mac80211`（user id 53 冲突）。
2. **修 platform.sh**：`sed -i '/jcg,q30-pro/d' target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh`，让 jcg_q30-pro 走 `nand_do_upgrade`（与参考机一致）。
3. **追加 custom.config + 单 profile**：`sed ALL_PROFILES=n`。
4. **拷贝 files/ 覆盖** + 给脚本加执行权限。

### 4.3 files/ 覆盖

| 路径 | 作用 |
|---|---|
| `etc/uci-defaults/99-jcg-q30-defaults` | 首次启动：LAN、关 IPv6、双频 WiFi、openclash 锁定 |
| `etc/uci-defaults/zz-openclash-editor` | 启用 openclash-editor 门户服务 |
| `etc/hotplug.d/ieee80211/30-jcg-wifi` | 在 Kwrt 重新生成无线配置后，强制启用双频并设 SSID |
| `etc/openclash/core/clash_meta` | Meta 内核（aarch64 静态二进制，约 10MB，已纳入 git） |
| `etc/openclash/config/config.yaml` | 默认 openclash 配置（fake-ip） |
| `etc/init.d/openclash-editor-portal` + `etc/hotplug.d/iface/99-openclash-editor-portal` | openclash-editor 门户服务 |
| `usr/lib/lua/luci/...` + `usr/share/openclash-editor/...` + `www/...` | openclash-editor 前端/后端 |

---

## 5. 编译中遇到的问题与经验总结（★ 重要）

### 5.1 【必看】LAN IP 设置必须用 list 语法

OpenWrt 25.12 的 `config_generate` 生成的是 **`list ipaddr '10.0.0.1/24'`（列表 + /24 前缀）**。

❌ 错误写法（固件会一直停在默认 IP，后台进不去，容易被误判成 bootloop）：
```sh
uci set network.lan.ipaddr='192.168.100.1'
```

✅ 正确写法：
```sh
uci -q del network.lan.ipaddr
uci add_list network.lan.ipaddr='192.168.100.1/24'
```

### 5.2 【必看】无线默认禁用的两个坑

OpenWrt 25.12 的 `lib/wifi/mac80211.uc` 里，`disabled` 是设置在 **wifi-iface（default_radio0/default_radio1）** 上，而不是 radio 设备上：

```js
set ${si}.disabled='${defaults ? 0 : 1}'   // si = wifi-iface
```

所以启用无线要设置：
```sh
uci set wireless.default_radio0.disabled='0'
uci set wireless.default_radio1.disabled='0'
```
（同时设 radio 设备的 `radio0.disabled='0'` 也没坏处）

另外，Kwrt 的 `my-default-settings` 里有个 `10-wifi-detect` 热插拔脚本，**每次启动都会用 `wifi config` 重新生成无线配置并覆盖掉 uci-defaults 的设置**。所以要在 `etc/hotplug.d/ieee80211/` 下加一个编号更大的脚本（如 `30-jcg-wifi`），在它之后重新应用无线设置，并 `wifi up`。

### 5.3 【必看】25-platform.patch 的 hunk 冲突

Kwrt 的 `25-platform.patch` 对 `openwrt-25.12` HEAD 有 3 处 hunk 被拒。其中 jcg_q30-pro 那处用 sed 删掉即可（走默认 `nand_do_upgrade`）；其余 hunk 与 jcg 无关，不影响。

### 5.4 【必看】root 身份编译需要 FORCE_UNSAFE_CONFIGURE

```bash
export FORCE_UNSAFE_CONFIGURE=1
make -j$(($(nproc)+1))
```
否则 root 下 `tools/tar` 等 configure 会直接拒绝。

### 5.5 【必看】MULTI_PROFILE 不要改成 n

Kwrt 默认 `CONFIG_TARGET_MULTI_PROFILE=y`。把它改成 `n` 会导致设备选择失效、变成全设备构建。**保持 =y，只把 `CONFIG_TARGET_ALL_PROFILES=n`。**

### 5.6 后台编译中断后 opkg host 报错

```
ERROR: package/system/opkg [host] failed to build.
```
修复：`make package/system/opkg/host/clean` 后重跑 `make`。

### 5.7 构建耗时 & 最慢阶段

- 全量冷编译：约 1~2 小时（tools → toolchain → kernel → packages → image）。
- 增量重编译（只改 files/.config）：约 15~25 分钟。
- **最慢的是 `target/imagebuilder install` 阶段**：即使单 profile，Kwrt 默认 `CONFIG_IB=y` 会为 imagebuilder 压缩 filogic 所有设备的 kernel（lzma）。这是正常现象，不是卡死。可用 `ps -eo pid,pcpu,args | grep lzma` 确认仍在工作。

### 5.8 bootloop 排查经验

现象「内核起来（蓝灯 + ARP 能解析到目标 IP）但 ping/SSH/HTTP 不通」时，**优先怀疑网络配置没生效，而不是内核崩溃**。

排查顺序：
1. 看 LED：蓝 = 启动成功；红/闪 = 真 bootloop。
2. ping 默认 IP（如 10.0.0.1）和自定义 IP（如 192.168.100.1），确定设备实际在哪个 IP。
3. 检查 uci 配置是否用对了语法（§5.1 的 list ipaddr 坑）。

### 5.9 TUN 代理会劫持内网网段

电脑如果开了 TUN 模式代理（singbox 等），可能劫持 `192.168.100.x` 这类网段，导致「后台进不去、ping 时通时断」的假象。**测试时退出代理，或给测试网段加直连路由。**

### 5.10 刷机方式

- MT7981 NAND 设备：`sysupgrade.bin` 是 tar（kernel + root），走 OpenWrt 页面升级；`factory.bin` 是 UBI（fit 卷），走 uboot 刷入。
- 升级时**不要保留配置**，否则旧配置可能覆盖 uci-defaults 的首启设置。

---

## 6. 适配其它设备（如 Redmi AX6）

### 6.1 通用流程

1. **查设备在哪个 target/subtarget**：Redmi AX6 是 Qualcomm IPQ807x（`ipq807x`），不是 mediatek。用 Kwrt 仓库的 `devices/` 目录确认。
2. **改 `configs/custom.config`**：把 `CONFIG_TARGET_DEVICE_<subtarget>_DEVICE_<device>=y` 换成目标设备；`apply-custom.sh` 里的 `TARGET`/`DEVICE` 相应修改。
3. **改 files/ 覆盖**：LAN IP、WiFi、IPv6 等按目标设备调整。
4. **确认分区/刷机方式**：NAND / NOR / eMMC 不同，factory/sysupgrade 格式不同。
5. **确认升级路径**：不同设备在 `platform.sh` 里的分支不同（nand / emmc / dualboot）。
6. **注意 openclash-editor 的架构**：aarch64 用 `linux-arm64` 内核；其它架构改 `core_version` 和 `clash_meta` 二进制。

### 6.2 Redmi AX6 特别注意

- target：`ipq807x`，subtarget 需在 Kwrt `devices/ipq807x/` 下找设备名。
- 分区是 eMMC（不是 SPI NAND），升级路径与 MT7981 不同。
- WiFi 驱动是 QCA（ath11k），不是 MTK mt76。
- 后台默认 IP / WiFi 默认行为可能与 MTK 设备不同，需重新采集参考机。

> 通用方法论：先用「最小化镜像（不加 openclash/files）」验证能否启动，再逐个加功能二分定位，是最快的排错方式（本项目就是用这个办法定位到 LAN IP 语法问题的）。

---

## 7. Q30 PRO 验收标准（硬性需求）

- 后台地址：`192.168.100.1`（root / root）
- 默认关闭 IPv6
- WiFi：5G `AA_5G` / `asd12345`，2.4G `AA_2.4G` / `asd12345`，双频默认启用
- 预装 argon 主题 + passwall + openclash（内置 Meta 内核）
- openclash 默认 `fake-ip-mix` 混合模式，`core_version=linux-arm64`，`auto_update=0`、`update=0`（不可自更新）
- 预装 openclash-editor（当前 2.4.0）
- 110M 分区，可在 uboot 与 sysupgrade 升级