# HANDOFF.md — 交接记录

> **Stopped here**：阶段AX6 完成：Redmi AX6 定制固件编译成功，产物已下载到本地（firmware/ax6-20260822-1731/）。
> **Next**：刷写到 AX6 验证（sysupgrade 或 factory/uboot）；或继续其它设备适配。
> **Blocker**：无。

---

## 构建机 VPS（凭据备忘）
- IP：154.36.168.118
- 用户：root
- 密码：MF6CiJ6IY6
- 端口：22
- 系统：Ubuntu 24.04.1 / x86_64 / 8 核 / 7.8G 内存（无 swap）/ 114G 可用磁盘

## 旧 VPS（154.12.50.97，本次 AX9000 构建机）
- IP：154.12.50.97（root / mlspFSJF7535 / 22；阶段AX6 已在此机编译 Redmi AX6）
- 系统：Ubuntu 22.04 / x86_64 / 8 核 / 7.8G 内存 / 117G 磁盘（已重装，原 /root/ax6-build 数据已不存在）
- 本次用于编译 Xiaomi AX9000（构建根 /root/q30-build，源码树 /root/q30-build/openwrt）

## 阶段1 结论（新 VPS 154.36.168.118）
- 依赖已装（gcc 13.3 / clang-18 / llvm-18 / qemu-utils 等）；已建 8G swap 文件并写入 /etc/fstab。
- 构建根：/root/q30-build（Kwrt 检出，含 devices/）；源码树 /root/q30-build/openwrt。
- 已跑通 feeds：packages / luci / routing / video / kiddin9（814 包）。
- 构建脚本已上传：/root/q30-build/build-kwrt.sh（支持 PREPARE_ONLY=1 只准备不编译）。

## 编译监控（阶段4/5）
- 启动：cd /root/q30-build/openwrt && export FORCE_UNSAFE_CONFIGURE=1 && setsid make -j8 > /root/q30-build/build.log 2>&1 < /dev/null &
- 查看进度：tail -30 /root/q30-build/build.log
- 产物目录：/root/q30-build/openwrt/bin/targets/mediatek/filogic/
- 注意：必须以 FORCE_UNSAFE_CONFIGURE=1 编译；后台编译被中断后若报 `opkg [host] failed to build`，先 `make package/system/opkg/host/clean` 再继续。

## 固件产物
- 完整版（本次，待验证）：本地 firmware/full-20260820-1114/
  - sysupgrade 52.9MB / factory 55.7MB / initramfs 47.4MB
  - SHA256：sysupgrade=c71709d2…532f，factory=611bae7c…002d，initramfs=4ae4276b…6ec2
- 最小化版（已确认能启动）：本地 firmware/minimal-20260820-094048/
- 官方 stock 0715（内核 6.12.94，可用作恢复）：本地 firmware/kwrt-07.15.2026-*.bin
- 首次完整版（bootloop，已废弃）：firmware/kwrt-mediatek-filogic-*.bin（52.9/55.6/47.4MB）

## 阶段5 根因定位结论（2026-08-20）
- 设备状态：当前运行最小化镜像（内核 6.12.103，后台 10.0.0.1，passwall+argon，无 openclash），SSH 曾 root/root 可用。
- 两版（stock 0715 vs 首次完整版）kernel FIT 的 DTB 完全相同，启动链路一致（uboot 读 kernel 卷 → ubiblock0_1(rootfs) → squashfs → rootfs_data overlay）。
- 差异：内核 6.12.94→6.12.103 + rootfs 新增（openclash / luci-app-argon-config / files 覆盖）。
- 已确认最小化镜像能启动 → bootloop 根因在本项目新增定制（openclash / argon-config / files 之一）。
- 已排查：openclash 默认 enable=0（boot 时 start_service 直接退出）、argon-config 的 uci-defaults 无害、clash_meta 为有效 aarch64 静态 ELF、uci-defaults 在 wifi config 生成之后执行（顺序正确）。
- 疑点仍待二分：files 覆盖 vs openclash（或 kmod-tun）。

## 完整版（阶段5 新需求，已编译）
- 新增功能：
  1) argon 主题 + luci-app-argon-config
  2) passwall + openclash（内置 clash_meta Meta 内核；uci-defaults 设 core_version=linux-arm64、auto_update=0、update=0、enable=0 锁定）
  3) 默认关 IPv6（删 wan6/ip6assign/ula，禁 dhcpv6/ra/ndp）
  4) 5G SSID=AA_5G / key=asd12345，2.4G 关闭
  5) 后台 192.168.100.1
  6) openclash-editor（Visual Editor + 门户服务，来自 rainbowgag/openclash-editor）
  7) 默认 openclash 配置 /etc/openclash/config/config.yaml（来自 rainbowgag/clash-）
- 落地文件：configs/custom.config、configs/apply-custom.sh、configs/files/（新增 editor + config.yaml + zz-openclash-editor uci-defaults）、scripts/build-full.sh。
- 注意：openclash 默认 enable=0（不启动），需在 LuCI 手动开启；自更新已锁。

## 已解决的构建问题
- 25-platform.patch 对 openwrt-25.12 HEAD 的 3 处 hunk 冲突：已用 sed 删除 platform.sh 中的 jcg,q30-pro（走 nand_do_upgrade）。
- Kwrt feeds install 漏建 package/feeds/kiddin9 软链接：apply-custom.sh 手动补建并排除 zabbix 两个包。
- 后台编译中断导致 opkg host 失败：make package/system/opkg/host/clean 后重跑。
- build-minimal.sh 曾误改 MULTI_PROFILE=n 导致全设备构建：已修正为只移除 openclash/argon-config/files。

## 硬性需求备忘
- 固件后台地址：192.168.100.1
- WiFi：5G SSID=AA_5G / 密码=asd12345；2.4G 默认禁用
- 默认关闭 IPv6
- 预装 argon 主题 + passwall + openclash（内置 Meta 内核）
- 锁定 openclash 内核/插件自更新
- 110M 分区，可在 uboot 与 sysupgrade 升级

## 阶段计划（小步推进，每阶段一个会话）
0 初始化（完成）→ 1 VPS 环境（完成）→ 2 设备采集/分区确认（完成）→ 3 定制配置（完成）
→ 4 首次编译（完成）→ 5 刷写验证（进行中）→ 6 锁定更新 → 7 收尾交付

## 阶段9 AX9000 修复（2026-08-22）
- 有线不通：DTS 缺 ethernet-phy-package(qcom,qca8075-package)，qca807x PHY probe -EINVAL → scripts/patch-ax9000-dts.py 包裹 4 个 QCA8075 PHY。
- 三频缺失：QCN9074 PCIe bdf_search 读不到 variant，board-2.bin 条目带 variant 名不匹配 → 去掉 variant 名（configs/ax9000/files/lib/firmware/.../board-2.bin，.gitignore 例外）。
- SSID 错位/无 160M：改为按 band+path 识别（2.4G=AA_2.4G/5G主频=AA_5G HE160/5G游戏=AA_5G_Game HE160）。
- opkg 报错：distfeeds 的 kwrt_core(6.12.103) 在 dl.openwrt.ai 不存在 → zz-fix-distfeeds 去掉该 feed。
- USB3.0：custom.config 加 kmod-usb-storage/uas、kmod-fs-vfat/exfat/ntfs3、usbutils。
- 遗留：QCA9887(168c:0050, ath10k PCIe) 仍缺 caldata（非三频必需，未处理）。

## 阶段9b 深挖结论（2026-08-22）
- 有线根因：Kwrt 的 devices/qualcommax_ipq807x/diy 自定义 DTS 覆盖上游 DTS，且缺 ethernet-phy-package+qcom,package-mode；而 switch_mac_mode=0xb=MAC_MODE_QSGMII，qca807x 驱动默认 PSGMII 不匹配 → 只发不收。补丁加 qcom,package-mode="qsgmii"。
- QCN9074 根因：files/ 覆盖在 ipq-wifi 包的 install-overlay 之前被覆盖，board-2.bin 没生效；改为 /etc/ax9000/qcn9074-board-2.bin + uci-defaults 首启覆盖并 rmmod/modprobe ath11k_pci。
- 160MHz 根因：CN 法规域 5.2G(36-144) 全 NO_IR、5.8G(149-165) 仅 80MHz，160MHz 在 CN 不可用；改用 country=US + HE160 channel 100(DFS)。

## 阶段AX6 Redmi AX6 定制（2026-08-22 完成）
- 构建机：154.12.50.97（root/mlspFSJF7535/22，Ubuntu 24.04，8核/7.8G+8G swap，已装依赖），构建根 /root/q30-build。
- 使用 configs/ax6/ 骨架 + docs/BUILD-GUIDE.md；目标 qualcommax/ipq807x，设备 redmi_ax6。
- 需求落地：argon 主题、passwall、openclash（内置 clash_meta、core_version=linux-arm64、auto_update/update=0 锁定）、默认关 IPv6、5G AA_5G/asd12345（2.4G 禁用）、后台 192.168.100.1、openclash-editor（Visual Editor 2.4.0）、默认 config.yaml（rainbowgag/clash-）。
- 关键修复（已落盘）：
  1) configs/ax6/apply-custom.sh 修正共享 files 复制（补 mkdir -p）并选择性复制（不含 nginx/jcg-wifi）。
  2) 04-stock.patch 的 platform.sh hunk 因上游新增 CI_DATA_UBIPART 冲突 → scripts/patch-ax6-platformsh.py 幂等修复为 A/B 双分区；build-ax6.sh 步骤7容忍该 hunk 失败。
  3) qosify 在 25.12 编译失败（本项目不需要）→ apply-custom.sh 禁用。
  4) ruby 的 RUBY_ENABLE_YJIT=y 会触发 rust/host 的 LLVM/rustc 超长构建（编辑器只需纯 ruby）→ apply-custom.sh 禁用 YJIT。
- 产物（firmware/ax6-20260822-1731/）：
  - sysupgrade 56.8MB：kwrt-qualcommax-ipq807x-redmi_ax6-squashfs-sysupgrade.bin
  - factory 58.9MB：kwrt-qualcommax-ipq807x-redmi_ax6-squashfs-factory.ubi
  - initramfs：kwrt-qualcommax-ipq807x-redmi_ax6-initramfs-factory.ubi / -initramfs-uImage.itb
  - SHA256：sysupgrade=649037e2…db8b，factory=c2d5fe1d…c5df（完整见 sha256sums）
- 参考机（192.168.100.1，root/root）实测：radio0=5G(QCN5054,HE160)、radio1=2.4G(QCA9887,HE40)；mtd8=art；rootfs 双分区(A/B)。
## 最近完成
- [2026-08-22] 阶段9b：有线改 QSGMII(switch_mac_mode=0xb)、QCN9074 board 改 uci-defaults 覆盖+重载、5G 160MHz 改 US 国家码，产物 firmware/ax9000-20260822-1413/。
- [2026-08-22] 阶段9：AX9000 修复六项问题并重编译（有线QCA8075 PHY package、QCN9074 board去variant、三频SSID/160MHz按band+path、opkg去kwrt_core、USB存储包），产物 firmware/ax9000-20260822-1224/。
- [2026-08-22] 阶段8：Xiaomi AX9000 固件编译成功（qualcommax/ipq807x，无 openclash，argon+passwall+luci-nginx），产物本地 firmware/ax9000-20260822-0301/。
- [2026-08-20] 阶段5：按新需求重编译完整版（+openclash-editor +config.yaml +锁定），已校验 rootfs 内容并下载到本地。
- [2026-08-20] 阶段5：完成保守重建，最小化镜像确认能启动（用户刷写成功）。
- [2026-08-20] 阶段5：拆包对比定位 bootloop 差异（DTB 相同，差异在内核版本与 rootfs 新增定制）。
- [2026-08-20] 阶段5：发现刷入后 bootloop（内核起、userland 挂），定位中。
- [2026-08-20] 阶段4：编译成功，产出 sysupgrade/factory/initramfs 三镜像并校验 SHA256。
- [2026-08-19] 阶段4：修复 tools/tar 报错，重启编译并进入宿主工具链阶段。
- [2026-08-19] 阶段3：解决补丁冲突、补建 kiddin9 软链接、配置单 profile + 插件 + files 覆盖，defconfig 通过。
- [2026-08-19] 阶段2：采集参考机分区/配置/已装包，确认 110M 分区，落盘 configs/reference/。
- [2026-08-19] 阶段1：新 VPS 环境就绪（依赖/swap/克隆/feeds 通过），定位补丁冲突。
- [2026-08-19] 阶段1：切换到新 VPS 154.36.168.118，连通并采集主机信息。
- [2026-08-19] 阶段0：创建 AGENTS.md / docs/ARCHITECTURE.md / HANDOFF.md，git 初始化并首次提交。
## 阶段7 收尾（完成）
- 源码已推送：https://github.com/rainbowgag/q30pro.git
- 编译指南：docs/BUILD-GUIDE.md（含全部踩坑经验与其它设备适配方法）
- 固件：firmware/final4-20260821-2358/（已验证可用）

- [2026-08-22] 阶段9c：有线补 phy-mode(qsgmii/sgmii)+恢复独立 MAC，QCN9074 加 raw board.bin API1 回退，三频 160MHz 按 radio 路径重排，开始重编译。

- [2026-08-22] 阶段9c：有线 phy-mode 修复+独立MAC userspace 脚本，QCN9074 raw board.bin 三频回退，三频 160MHz 路径重排，产物 firmware/ax9000-20260822-161456/。

- [2026-08-22] 阶段AX6：Redmi AX6 定制编译成功（argon/passwall/openclash meta+editor，5G AA_5G，关IPv6，后台192.168.100.1），产物 firmware/ax6-20260822-1731/。
- [2026-08-22] 阶段9d：WAN QCA8081 补 reset-deassert-us=10000 重编译，产物 firmware/ax9000-20260822-171557/。
