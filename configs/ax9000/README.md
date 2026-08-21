# Xiaomi AX9000 适配骨架（待完善）

## 已确认的设备信息（来自 openwrt-25.12 / Kwrt）
- OpenWrt 设备名：`xiaomi_ax9000`
- target / subtarget：`qualcommax / ipq807x`
- SoC：Qualcomm IPQ8072A（DTS compatible `qcom,ipq8074`）
- Flash：NAND（DTS 分区合计 256MB）
- 关键分区：
  - `ubi_kernel`：0x1180000，大小 0x3800000（56MB）
  - `rootfs`：0x4980000，大小 0xb680000（**182.5MB**）
- 启动：`root=/dev/ubiblock0_0`（上游） / Kwrt 的 04-stock.patch 已处理 `xiaomi,ax9000` 的 `nand_do_upgrade` 双分区切换
- WiFi：三频
  - ath11k（QCN9074，5G 游戏频段）
  - ath10k（QCA9887，2.4G + 5G）
  - 固件包：`ipq-wifi-xiaomi_ax9000 kmod-ath11k-pci ath11k-firmware-qcn9074 kmod-ath10k-ct ath10k-firmware-qca9887-ct`
- 镜像：FitImage + UbiFit（`KERNEL_SIZE := 57344k`）

## 待确认（TODO）
- [ ] **分区大小**：用户提到「也是 110M 分区」，但当前 DTS 的 rootfs 是 182.5MB。需确认：
  - 实际设备 rootfs 分区到底多大？
  - 若确实要 110M，需要像 Q30 那样加 DTS 分区补丁（当前骨架未做）。
- [ ] **三频 WiFi 的 SSID/密码**：默认按 2.4G=AA_2.4G、5G=AA_5G、游戏频段=AA_5G_Game 处理，可改。
- [ ] 后台 LAN 地址（默认按 Q30 用 192.168.100.1，可改）
- [ ] 是否需要 IPv6（默认关闭）
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
1. **三频**：AX9000 有 3 个 radio（radio0=2.4G，radio1=5G，radio2=5G游戏频段），uci-defaults 需要处理 3 个 radio。
2. **双分区**：`nand_do_upgrade` + `flag_boot_rootfs` 切换（Kwrt 04-stock.patch 已处理，不要再 sed platform.sh）。
3. **WiFi disabled 坑**：25.12 的 disabled 在 wifi-iface（default_radioX）上。
4. **NCSI / nginx 纯 HTTP**：已复用 Q30 的共享文件（nginx 纯 HTTP + NCSI 劫持）。