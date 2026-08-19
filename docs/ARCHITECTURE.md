# 架构说明 — JCG Q30 PRO 定制 OpenWrt 固件

## 总体
「产品」是固件镜像，不在本地编译，而是在远程 VPS 上编译。本地仓库只保存构建配置、
定制文件与文档；VPS 是可按需重建的构建机。

## 模块划分
1. 本地仓库（本目录）
   - AGENTS.md / HANDOFF.md / docs/ARCHITECTURE.md：项目记忆
   - configs/：固件定制产物（diffconfig、files/ 覆盖、patches/ 补丁）
   - scripts/：构建与连接辅助脚本
2. 构建机（VPS 154.12.50.97，凭据见 HANDOFF.md）
   - Kwrt 仓库（25.12）：编排层，提供 devices/ 定制脚本与 .config
   - openwrt/ 源码树（openwrt/openwrt openwrt-25.12）：真正编译的目标
   - 产物：bin/targets/mediatek/filogic/*-sysupgrade.bin 等
3. 目标设备（JCG Q30 PRO）
   - 参考机：10.0.0.1（root/root），已刷好固件，用于采集分区与既有配置作为参照

## 构建数据流
    Kwrt devices/ 定制层（diy.sh + .config + patches）
              │
              ▼
    openwrt/ 源码树 ── feeds update/install ── make defconfig ── make
              │
              ▼
    bin/targets/mediatek/filogic/ 固件镜像
              │
              ├── uboot（恢复/首次刷入）
              └── sysupgrade（OpenWrt 页面升级）

## 关键设计决策
- 采用 Kwrt 而非裸 OpenWrt：直接继承 passwall / openclash / argon 等整合与补丁，减少自研
- 构建放 VPS：本地是 Windows，且编译需 Linux + 大磁盘/内存；本地仓库只存配置
- 只编译 jcg_q30-pro 单 profile：默认 ALL_PROFILES 会编译整个 filogic 所有设备，极慢
- 定制全部落盘（diffconfig / files / patches）以保证可复现

## 必须先明确的（阶段2 冻结）
- [x] 设备实际分区布局：mtd4 ubi = 0x6e80000（110.5M），由 09-jcg_q30-pro.patch 定义
- [ ] 110M 分区下 uboot / sysupgrade 的正确刷入步骤（fip 已放开 read-only）
- [x] 参考机现有 openclash / passwall / wifi / 网络配置（见 configs/reference/reference-device.md）
- [ ] OpenClash meta 内核在 op-packages feed 中的包名，及「禁止自更新」的锁定方式

## 固件硬性需求（验收标准）
- 后台 192.168.100.1；默认关闭 IPv6
- WiFi：5G SSID=AA_5G / key=asd12345；2.4G 禁用
- 预装 argon 主题、PassWall、OpenClash（内置 Meta 内核）
- OpenClash 内核与插件不可自更新
- 可在 uboot 与 OpenWrt 页面（sysupgrade）升级，适配 110M 分区
