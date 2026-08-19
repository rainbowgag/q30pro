# configs/ — 固件定制产物

本目录保存所有对固件的可复现定制。任何在 VPS 上对源码/配置的改动，都必须以
以下形式之一回落到本目录并提交 git，否则视为丢失。

- diffconfig/：每次成功构建后导出的 .config 精简快照（./scripts/diffconfig.sh）
- files/：OpenWrt files/ 覆盖目录（自定义 /etc/config/network、wireless、firewall 等）
- patches/：devices 补丁之外的额外设备级补丁
