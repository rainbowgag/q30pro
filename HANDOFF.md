# HANDOFF.md — 交接记录

> **Stopped here**：阶段4 完成——固件已编译成功并下载到本地 firmware/，SHA256 校验通过。
> **Next**：阶段5——刷写验证（先 uboot 刷 factory，再 OpenWrt 页面刷 sysupgrade），核对后台/WiFi/IPv6/插件。
> **Blocker**：无。

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

## 已解决的构建问题（阶段3）
- 25-platform.patch 对 openwrt-25.12 HEAD 的 3 处 hunk 冲突：已用 sed 删除 platform.sh 中的
  jcg,q30-pro（使其走 nand_do_upgrade，与参考机一致）；其余 2 处 hunk 与 jcg 无关（cudy/aigo/umi）。
- Kwrt 的 feeds install 漏建 package/feeds/kiddin9 软链接：apply-custom.sh 手动补建，
  并排除 zabbix-ssl / zabbix-extra-mac80211（与 packages feed 的 user id 53 冲突）。
- 定制产物已落盘：configs/custom.config、configs/apply-custom.sh、configs/files/、configs/diffconfig/。

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
0 初始化（完成）→ 1 VPS 环境（完成）→ 2 设备采集/分区确认（完成）→ 3 定制配置（完成）
→ 4 首次编译（完成）→ 5 刷写验证 → 6 锁定更新 → 7 收尾交付

## 最近完成
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
