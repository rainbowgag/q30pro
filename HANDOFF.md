# HANDOFF.md — 交接记录

> **Stopped here**：阶段2 完成——参考机信息已采集，110M 分区已确认（mtd4 ubi=0x6e80000，源自 09-jcg_q30-pro.patch）。
> **Next**：阶段3——解决 25-platform.patch 的 3 处 hunk 冲突，并做定制（LAN/WiFi/IPv6/主题/插件/clash_meta 预置）。
> **Blocker**：Kwrt 的 25-platform.patch 对 openwrt-25.12 HEAD（4a5c6b9）有 3 处 hunk 被拒：platform.sh、uboot-envtools/mediatek_filogic、11_fix_wifi_mac。

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

## 已知问题（阶段2/3 解决）
- openwrt-25.12 分支 HEAD=4a5c6b9（2026-07-22）与 Kwrt 补丁基线漂移，
  devices/mediatek_filogic/patches/25-platform.patch 有 3 个 hunk 被拒，产生 .rej：
  platform.sh（sysupgrade）、uboot-envtools/mediatek_filogic、11_fix_wifi_mac。
- 09-jcg_q30-pro.patch（设备专用补丁）已正常应用。

## 参考设备（已刷好固件，作为参照）
- 后台地址：10.0.0.1
- 用户名 / 密码：root / root
- 采集结果：见 configs/reference/reference-device.md（分区表/已装包/现状-目标差异）

## 硬性需求备忘
- 固件后台地址：192.168.100.1
- WiFi：5G SSID=AA_5G / 密码=asd12345；2.4G 默认禁用
- 默认关闭 IPv6
- 预装 argon 主题 + passwall + openclash（内置 Meta 内核）
- 锁定 openclash 内核/插件自更新
- 110M 分区，可在 uboot 与 sysupgrade 升级

## 阶段计划（小步推进，每阶段一个会话）
0 初始化（完成）→ 1 VPS 环境（完成）→ 2 设备采集/分区确认（完成）→ 3 定制配置
→ 4 首次编译 → 5 刷写验证 → 6 锁定更新 → 7 收尾交付

## 最近完成
- [2026-08-19] 阶段2：采集参考机（10.0.0.1）分区/配置/已装包；确认 110M 分区
  = mtd4 ubi 0x6e80000，由 09-jcg_q30-pro.patch 定义；落盘 configs/reference/。
- [2026-08-19] 阶段1：新 VPS 154.36.168.118 环境就绪（依赖/swap/克隆/feeds 通过），
  并定位 Kwrt 25-platform.patch 对 openwrt-25.12 HEAD 的 3 处 hunk 冲突。
- [2026-08-19] 阶段1：切换到新 VPS 154.36.168.118（114G 可用），连通并采集主机信息。
- [2026-08-19] 阶段1 进行中：SSH 连通 VPS；采集主机信息；定位磁盘占用
  （/root/ax6-build/openwrt 占 74G，为旧 ipq807x 全设备编译且失败）。
- [2026-08-19] 阶段0：创建 AGENTS.md / docs/ARCHITECTURE.md / HANDOFF.md，
  建立 configs/ 与 scripts/ 骨架，git 初始化并首次提交。
