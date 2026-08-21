# Xiaomi AX9000 适配骨架

## 已确认的设备信息（来自 openwrt-25.12 / Kwrt）
- OpenWrt 设备名：`xiaomi_ax9000`
- target / subtarget：`qualcommax / ipq807x`
- SoC：Qualcomm IPQ8072A（DTS compatible `qcom,ipq8074`）
- Flash：NAND（DTS 分区合计 256MB）
- 关键分区：
  - `ubi_kernel`：0x1180000，大小 0x3800000（56MB）
  - `rootfs`：0x4980000，大小 0xb680000（182.5MB）
- 启动：`root=/dev/ubiblock0_0`（上游）；Kwrt 的 04-stock.patch 已处理 `xiaomi,ax9000` 的 `nand_do_upgrade` 双分区切换
- WiFi：三频
  - ath11k（QCN9074，5G 游戏频段）
  - ath10k（QCA9887，2.4G + 5G）
  - 固件包：`ipq-wifi-xiaomi_ax9000 kmod-ath11k-pci ath11k-firmware-qcn9074 kmod-ath10k-ct ath10k-firmware-qca9887-ct`
- 镜像：FitImage + UbiFit（`KERNEL_SIZE := 57344k`）

## 本骨架包含
- argon 主题 + luci-app-argon-config
- passwall
- 三频 WiFi 默认启用：2.4G `AA_2.4G`、5G `AA_5G`、5G 游戏频段 `AA_5G_Game`（密码 asd12345）
- 默认关闭 IPv6
- 后台 `192.168.100.1`
- nginx 纯 HTTP + Windows NCSI 联网检测修复

## 不包含（按需求）
- **openclash**
- **openclash 可视化编辑器（openclash-editor）**

## 待确认（TODO）
- [ ] 三频 SSID/密码（默认 AA_2.4G / AA_5G / AA_5G_Game / asd12345，可改）
- [ ] 后台 LAN 地址（默认 192.168.100.1，可改）
- [ ] 参考机采集：分区表 / 已装包 / 原厂配置

## 如何编译
在 openwrt 源码目录内：
```bash
bash /root/q30-build/configs/ax9000/apply-custom.sh
make defconfig
FORCE_UNSAFE_CONFIGURE=1 make -j$(($(nproc)+1))
```
产物：`bin/targets/qualcommax/ipq807x/*xiaomi_ax9000*.bin`

## 特别注意
1. **三频**：AX9000 有 3 个 radio（radio0=2.4G，radio1=5G，radio2=5G游戏频段）。
2. **双分区**：`nand_do_upgrade` + `flag_boot_rootfs` 切换（Kwrt 04-stock.patch 已处理，不要再 sed platform.sh）。
3. **WiFi disabled 坑**：25.12 的 disabled 在 wifi-iface（default_radioX）上。