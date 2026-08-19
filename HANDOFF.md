# HANDOFF.md — 交接记录

> **Stopped here**：阶段1 已连通 VPS（Ubuntu 24.04 / 8核 / 7.8G 内存 / 120G 磁盘），发现磁盘仅剩 11G，阻塞编译。
> **Next**：待确认清理方案后，释放空间并安装依赖、克隆源码、跑通 feeds。
> **Blocker**：VPS 磁盘 92% 满（117G 剩 11G），大头是 /root/ax6-build（74G，旧 ipq807x 全设备编译且失败），需清理。

---

## 构建机 VPS（凭据备忘）
- IP：154.12.50.97
- 用户：root
- 密码：4Bdl9fpwqY
- 端口：22
- 系统：Ubuntu 24.04.1 / x86_64 / 8 核 / 7.8G 内存 / 120G 磁盘（现仅剩约 11G）

## 参考设备（已刷好固件，作为参照）
- 后台地址：10.0.0.1
- 用户名 / 密码：root / root

## 硬性需求备忘
- 固件后台地址：192.168.100.1
- WiFi：5G SSID=AA_5G / 密码=asd12345；2.4G 默认禁用
- 默认关闭 IPv6
- 预装 argon 主题 + passwall + openclash（内置 Meta 内核）
- 锁定 openclash 内核/插件自更新
- 110M 分区，可在 uboot 与 sysupgrade 升级

## 阶段计划（小步推进，每阶段一个会话）
0 初始化（本次完成）→ 1 VPS 环境 → 2 设备采集/分区确认 → 3 定制配置
→ 4 首次编译 → 5 刷写验证 → 6 锁定更新 → 7 收尾交付

## 最近完成
- [2026-08-19] 阶段1 进行中：SSH 连通 VPS；采集主机信息；定位磁盘占用
  （/root/ax6-build/openwrt 占 74G，为旧 ipq807x 全设备编译且失败）。
- [2026-08-19] 阶段0：创建 AGENTS.md / docs/ARCHITECTURE.md / HANDOFF.md，
  建立 configs/ 与 scripts/ 骨架，git 初始化并首次提交。
