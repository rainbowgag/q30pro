# Redmi AX6 适配（已冻结）

## 设备信息（已通过参考机 192.168.100.1 实测确认）
- OpenWrt 设备名：`redmi_ax6`
- target / subtarget：`qualcommax / ipq807x`
- SoC：Qualcomm IPQ8071（四核 A53）
- Flash：SPI-NAND 128MB，双 rootfs（rootfs / rootfs_1）
- 升级路径：`nand_do_upgrade` + 双分区切换（Kwrt 04-stock.patch 已处理，无需 sed platform.sh）
- WiFi：ath10k（QCA）。实测 radio0=5G（QCN5054，HE160）、radio1=2.4G（QCA9887，HE40）；
  校准数据由 Kwrt 11-ath10k-caldata 热插拔提取
- 镜像：FitImage + UbiFit（kernel 在 UBI fit 卷）

## 固化需求（与 Q30 一致）
- 后台 LAN：192.168.100.1（root/root）
- 默认关闭 IPv6
- WiFi：5G `AA_5G` / `asd12345` 启用；2.4G 默认禁用
- 预装 argon 主题 + passwall + openclash（内置 Meta 内核）
- openclash：`fake-ip-mix`、`core_version=linux-arm64`、`auto_update=0`、`update=0`、`enable=0`（不可自更新）
- 预装 openclash-editor（Visual Editor 2.4.0）

## 如何用它编译
参考 docs/BUILD-GUIDE.md。在 VPS 上：
```bash
cd /root/q30-build
setsid bash scripts/build-ax6.sh > build-ax6.log 2>&1 < /dev/null &
```
产物：`openwrt/bin/targets/qualcommax/ipq807x/*redmi_ax6*.bin`

## 特别注意（与 Q30 的不同点）
1. 双 rootfs：AX6 是 A/B 双分区，sysupgrade 会切换 flag_boot_rootfs，首次刷入建议 factory/initramfs。
2. ath10k 校准数据在 0:art 分区，由 Kwrt 11-ath10k-caldata 热插拔提取。
3. 不要 sed platform.sh（redmi,ax6 已在 Kwrt 补丁）。
4. WiFi 按 band 识别：radio0=5G、radio1=2.4G（参考机实测），脚本不写死 radio 序号。