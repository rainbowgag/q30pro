# 参考机采集结果（JCG Q30 PRO，后台 10.0.0.1，root/root）

采集日期：2026-08-19

## 设备与固件
- 型号：JCG Q30 PRO；board_name：jcg,q30-pro
- 固件：Kwrt 24.10-SNAPSHOT（revision 11.10.2025），target=mediatek/filogic，arch=aarch64_cortex-a53
- 内核：6.6.116；rootfs=squashfs + overlay

## 分区表（关键：确认 110M 分区）
    mtd0 bl2        0x0000000 0x0100000 (1MB)
    mtd1 u-boot-env 0x0100000 0x0080000 (512KB)
    mtd2 Factory    0x0180000 0x0200000 (2MB)
    mtd3 fip        0x0380000 0x0200000 (2MB)
    mtd4 ubi        0x0580000 0x6e80000 (110.5MB)  ← 110M 分区
- 110M 来源：devices/mediatek_filogic/patches/09-jcg_q30-pro.patch 把上游 ubi 从 0x7000000 改为 0x6e80000，
  同时给 NAND 加 NMBM、并去掉 fip 的 read-only（fip 可写，用于 uboot 刷入）。

## 目标固件需预装（参考机已装）
- luci-theme-argon 2.4.3 + luci-app-argon-config
- luci-app-openclash 0.47.116（core_version=linux-arm64，Meta；default_dashboard=metacubexd）
- luci-app-passwall 25.12.19-r1
- OpenClash meta 内核：/etc/openclash/core/clash_meta（约 10MB）。
  注意：它由 openclash 运行时下载，非任何 ipk 提供（grep opkg info 无归属）。
  因此我们的固件需通过 files/ 覆盖把 clash_meta 预置进去，并锁定“内核/插件自更新”。

## 现状 → 目标（差异清单）
    LAN 地址    10.0.0.1/24          → 192.168.100.1/24
    5G WiFi     SSID=Kwrt_5G 无加密   → SSID=AA_5G，WPA2 key=asd12345
    2.4G WiFi   SSID=Kwrt_2.4G 启用   → 默认禁用
    IPv6        开启(wan6/ip6assign)  → 默认关闭
    OpenClash   已装(可自更新)        → 预装 Meta 内核 + 锁自更新

## 参考配置关键点
- 无线：radio0=2g(HE20,ch1,CN)，radio1=5g(HE160,ch44,CN)
- openclash 配置端口：http 7890 / socks 7891 / mixed 7893 / tproxy 7895；en_mode=fake-ip
- passwall 默认 enabled=0（不启用）
