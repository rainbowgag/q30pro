# Redmi AX6 适配骨架（待完善）

## 已确认的设备信息（来自 Kwrt / openwrt-25.12）
- OpenWrt 设备名：`redmi_ax6`
- target / subtarget：`qualcommax / ipq807x`
- SoC：Qualcomm IPQ8071（四核 A53）
- Flash：SPI-NAND 128MB，**双 rootfs（rootfs / rootfs_1）**
- 升级路径：`nand_do_upgrade` + 双分区切换（Kwrt 的 `04-stock.patch` 已处理，无需再 sed platform.sh）
- WiFi：ath10k（QCA），2.4G QCA9887 + 5G QCN5054，固件 `ipq-wifi-redmi_ax6`
- 镜像：FitImage + UbiFit（kernel 在 UBI fit 卷）

## 待用户确认（TODO）
- [ ] 后台 LAN 地址（默认按 Q30 用 192.168.100.1，可改）
- [ ] 2.4G/5G SSID 与密码（默认 AA_2.4G / AA_5G / asd12345，可改）
- [ ] 是否需要 IPv6（默认关闭）
- [ ] 参考机采集：分区表 / 已装包 / 现有配置（建议先刷一台原厂或已有 OpenWrt 采集）
- [ ] openclash 默认运行模式（默认 fake-ip-mix）

## 如何用它编译
参考 docs/BUILD-GUIDE.md，构建时把 apply 脚本换成 AX6 的：
```bash
# 在 openwrt 源码目录内
bash /root/q30-build/configs/ax6/apply-custom.sh
```
然后 `make defconfig && FORCE_UNSAFE_CONFIGURE=1 make -j$(($(nproc)+1))`。
产物：`bin/targets/qualcommax/ipq807x/*redmi_ax6*.bin`

## 特别注意（与 Q30 的不同点）
1. **双 rootfs**：AX6 是 A/B 双分区，sysupgrade 会切换 `flag_boot_rootfs`，首次刷入建议用 factory/initramfs。
2. **ath10k 校准数据**：WiFi 校准在 `0:art` 分区，Kwrt 的 `11-ath10k-caldata` 热插拔脚本负责提取（已由 04-stock.patch 提供）。
3. **不要 sed platform.sh**：`redmi,ax6` 的升级分支已经在 Kwrt 补丁里，Q30 那套 sed 不适用。
4. **WiFi disabled 坑同 Q30**：25.12 的 mac80211.uc 把 disabled 放在 wifi-iface 上，见 30-ax6-wifi。