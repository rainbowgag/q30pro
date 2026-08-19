# configs/ — 固件定制产物

本目录保存所有对固件的可复现定制。任何在 VPS 上对源码/配置的改动，都必须以
以下形式之一回落到本目录并提交 git，否则视为丢失。

- custom.config：本项目追加的 .config（单 profile + 主题/插件）
- apply-custom.sh：在 VPS 的 openwrt 目录内执行的定制脚本
- files/：OpenWrt files/ 覆盖（uci-defaults 设 LAN/WiFi/关 IPv6；clash_meta 预置）
- diffconfig/：解析后的 .config 快照（jcg-q30-pro.config）
- patches/：预留的设备级额外补丁
