# HANDOFF.md — 交接记录

> **Stopped here**：阶段5 定位根因中。已确认设备已用 stock 0715 恢复（后台 10.0.0.1 正常）；正在 VPS 做「保守重建」二分定位 bootloop。
> **Next**：等最小化镜像（无 openclash/argon-config/files 覆盖）编译完成后刷入测试：若能启动→是本项目新增定制导致，再逐个加回；若仍 bootloop→锁定 openwrt-25.12 到 07.15 提交重建。
> **Blocker**：原始 bootloop 现场已丢失（设备已恢复成 stock 0715）。要拿崩溃日志需 UART 串口或 uboot TFTP 引导 initramfs。

---

## 构建机 VPS（凭据备忘）
- IP：154.36.168.118
- 用户：root
- 密码：MF6CiJ6IY6
- 端口：22
- 系统：Ubuntu 24.04.1 / x86_64 / 8 核 / 7.8G 内存（无 swap）/ 114G 可用磁盘

## 旧 VPS（保留，不用于本次构建）
- IP：154.12.50.97（root / 4Bdl9fpwqY / 22）
- 保留原因：/root/ax6-build（74G）等旧数据需保留，勿删

## 阶段1 结论（新 VPS 154.36.168.118）
- 依赖已装（gcc 13.3 / clang-18 / llvm-18 / qemu-utils 等）；已建 8G swap 文件并写入 /etc/fstab。
- 构建根：/root/q30-build（Kwrt 检出，含 devices/）；源码树 /root/q30-build/openwrt。
- 已跑通 feeds：packages / luci / routing / video / kiddin9（814 包）。
- 构建脚本已上传：/root/q30-build/build-kwrt.sh（支持 PREPARE_ONLY=1 只准备不编译）。

## 编译监控（阶段4）
- 启动：cd /root/q30-build/openwrt && export FORCE_UNSAFE_CONFIGURE=1 && setsid make -j8 > /root/q30-build/build.log 2>&1 < /dev/null &
- 查看进度：tail -30 /root/q30-build/build.log
- 查看是否还在跑：ps aux | grep make | grep -v grep
- 产物目录：/root/q30-build/openwrt/bin/targets/mediatek/filogic/
- 预期耗时：单 profile 约 1–2+ 小时（tools → toolchain → kernel → packages → image）。
- 注意：必须以 FORCE_UNSAFE_CONFIGURE=1 编译（root 身份下 tools/tar 等 configure 会拒绝）。

## 固件产物（阶段4 完成，已校验）
- VPS 路径：/root/q30-build/openwrt/bin/targets/mediatek/filogic/
- 本地路径：firmware/（已 gitignore）
- kwrt-mediatek-filogic-jcg_q30-pro-squashfs-sysupgrade.bin（52.9MB）→ OpenWrt 页面升级
- kwrt-mediatek-filogic-jcg_q30-pro-squashfs-factory.bin（55.6MB）→ uboot 刷入
- kwrt-mediatek-filogic-jcg_q30-pro-initramfs-kernel.bin（47.4MB）→ 救援/调试
- SHA256 本地已核对：sysupgrade=4bdf8bdd…0381f，factory=6a582b9e…3570a，
  initramfs=fb79c669…07eaf（与 VPS 的 sha256sums 一致）。

## 阶段5 问题：刷入后 bootloop（已恢复设备，根因定位中）
- 原始现象：OpenWrt sysupgrade 刷入后，电脑进不去后台。当时本机排查：
  - 有线网卡已设静态 192.168.100.10（原本 DHCP）。
  - ARP 能解析 192.168.100.1 -> 50-33-f0-e0-1c-e4（LAN MAC）。
  - 但 ping/SSH(22)/HTTP(80,443) 时通时断（仅一次 4 个 ping 应答后超时）。
  - 结论：内核起来，userland 起不来/崩溃，典型 bootloop。
- 已排除：root 密码就是 root（Kwrt 99-default-settings 里 passwd root=root）。

## 阶段5 根因分析（2026-08-20，重要）
- 现场：设备现已恢复为 stock Kwrt 25.12 **07.15.2026（内核 6.12.94）**，后台 10.0.0.1，SSH/后台正常。
  本地 firmware/ 同时存在两套镜像：
  - kwrt-07.15.2026-...（官方 release，内核 6.12.94，可用）
  - kwrt-mediatek-filogic-...（我们 08.19 自编译，内核 6.12.103，bootloop）
- 对比结论（在 VPS 上拆包验证）：
  - 两版 sysupgrade 的 **kernel FIT 里 fdt-1 DTB 完全相同**（crc32=90ddedb8/sha1=2d809ff1）。
  - 两版都走同一套 MT7981 NAND 启动：uboot 读 `kernel` 卷 → 内核 `ubiblock0_1(rootfs)` 挂 squashfs → `rootfs_data` UBIFS overlay（stock 设备 dmesg 证实）。
  - 因此差异只剩两点：内核 6.12.94→6.12.103，以及 rootfs 内容。
- rootfs 差异（stock 0715 vs 我们 08.19）：
  - stock 有 passwall / argon / my-default-settings，但**没有 openclash、没有 luci-app-argon-config、没有我们的 files 覆盖**。
  - 我们额外加了：luci-app-openclash、luci-app-argon-config、files/ 覆盖（99-jcg-q30-defaults + clash_meta 10MB）。
- 判断：bootloop 大概率来自「本项目新增定制」（openclash/files 覆盖）或「openwrt-25.12 分支在 6.12.94→6.12.103 的回归」。正在保守重建二分。

## 保守重建（二分定位，进行中）
- 脚本：scripts/build-minimal.sh（已上传 VPS /root/q30-build/build-minimal.sh）
- 做法：同一 openwrt-25.12 HEAD（4a5c6b9），单 profile jcg_q30-pro，
  去掉 openclash / luci-app-argon-config / files 覆盖，保留 passwall+argon（与 stock 0715 一致）。
- 备份：/root/q30-build/bisect/（.config.full.*.bak、files.full.*.bak、full/ 三镜像）
- 日志：/root/q30-build/build-minimal.log
- 判定：
  - 最小化镜像能启动 → 根因在本项目新增定制（openclash / files 覆盖），再逐个加回定位。
  - 仍 bootloop → 根因在 openwrt-25.12 分支/内核回归，锁定到 07.15 提交重建。

## 已解决的构建问题（阶段3）
- 25-platform.patch 对 openwrt-25.12 HEAD 的 3 处 hunk 冲突：已用 sed 删除 platform.sh 中的
  jcg,q30-pro（使其走 nand_do_upgrade，与参考机一致）；其余 2 处 hunk 与 jcg 无关（cudy/aigo/umi）。
- Kwrt 的 feeds install 漏建 package/feeds/kiddin9 软链接：apply-custom.sh 手动补建，
  并排除 zabbix-ssl / zabbix-extra-mac80211（与 packages feed 的 user id 53 冲突）。
- 定制产物已落盘：configs/custom.config、configs/apply-custom.sh、configs/files/、configs/diffconfig/。

## 参考设备 / 目标设备（当前为 stock 0715）
- 当前后台：10.0.0.1，root / root，JCG Q30 PRO（board jcg,q30-pro）
- 分区：mtd4 ubi = 0x6e80000（110M），UBI 卷 = kernel(4.6M) + rootfs(33.9M) + rootfs_data(65.7M)
- 采集结果：见 configs/reference/reference-device.md（注意：该文档采集的是 24.10，现已重刷为 25.12 stock）

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

## 最近完成
- [2026-08-20] 阶段5：确认设备已恢复为 stock 0715；拆包对比定位 bootloop 差异（DTB 相同，差异在内核版本与 rootfs 新增定制）；启动保守重建二分。
- [2026-08-20] 阶段5：发现刷入后 bootloop（内核起、userland 挂），定位中。
- [2026-08-20] 阶段4：编译成功，产出 sysupgrade/factory/initramfs 三个镜像，
  下载到本地 firmware/ 并核对 SHA256。
- [2026-08-19] 阶段4：修复 tools/tar 报错（root 需 FORCE_UNSAFE_CONFIGURE=1），重启编译并进入宿主工具链阶段。
- [2026-08-19] 阶段4 进行中：make -j8 后台编译已启动并通过预检，进入 tools/compile。
- [2026-08-19] 阶段3：解决补丁冲突（jcg 走 nand_do_upgrade）、补建 kiddin9 软链接、
  配置单 profile + argon/passwall/openclash、files 覆盖（LAN/WiFi/关IPv6/clash_meta 预置）、
  make defconfig 通过；保存 .config 快照到 configs/diffconfig/jcg-q30-pro.config。
- [2026-08-19] 阶段2：采集参考机（10.0.0.1）分区/配置/已装包；确认 110M 分区
  = mtd4 ubi 0x6e80000，由 09-jcg_q30-pro.patch 定义；落盘 configs/reference/。
- [2026-08-19] 阶段1：新 VPS 154.36.168.118 环境就绪（依赖/swap/克隆/feeds 通过），
  并定位 Kwrt 25-platform.patch 对 openwrt-25.12 HEAD 的 3 处 hunk 冲突。
- [2026-08-19] 阶段1：切换到新 VPS 154.36.168.118（114G 可用），连通并采集主机信息。
- [2026-08-19] 阶段1 进行中：SSH 连通 VPS；采集主机信息；定位磁盘占用
  （/root/ax6-build/openwrt 占 74G，为旧 ipq807x 全设备编译且失败）。
- [2026-08-19] 阶段0：创建 AGENTS.md / docs/ARCHITECTURE.md / HANDOFF.md，
  建立 configs/ 与 scripts/ 骨架，git 初始化并首次提交。