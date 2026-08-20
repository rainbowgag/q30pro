#!/bin/bash
# 保守重建（二分定位 bootloop）：
#   同一 openwrt-25.12 HEAD，单 profile jcg_q30-pro，
#   不含本项目新增的 openclash / luci-app-argon-config / files 覆盖（uci-defaults + clash_meta）。
#   保留 passwall / argon（与已知可用的 stock 0715 一致）。
# 用于区分：bootloop 来自「本项目新增定制」还是「openwrt-25.12 分支/内核回归」。
set -euo pipefail
B=/root/q30-build
O=$B/openwrt
cd "$O"

TS=$(date +%Y%m%d-%H%M%S)
mkdir -p "$B/bisect"
echo "[minimal] backup full .config -> $B/bisect/.config.full.$TS.bak"
cp -f .config "$B/bisect/.config.full.$TS.bak"
if [ -d files ]; then
  echo "[minimal] backup full files -> $B/bisect/files.full.$TS.bak"
  mv files "$B/bisect/files.full.$TS.bak"
fi

echo "[minimal] regenerate seed .config from Kwrt common+target"
cp -f "$B/devices/common/.config" .config
echo >> .config
cat "$B/devices/mediatek_filogic/.config" >> .config

# 单 profile
sed -i 's/^CONFIG_TARGET_ALL_PROFILES=.*/CONFIG_TARGET_ALL_PROFILES=n/' .config
sed -i 's/^CONFIG_TARGET_MULTI_PROFILE=.*/CONFIG_TARGET_MULTI_PROFILE=n/' .config
# 去掉本项目新增的三个包，确保不进入 image
sed -i '/^CONFIG_PACKAGE_luci-app-openclash/d' .config
sed -i '/^CONFIG_PACKAGE_luci-app-argon-config/d' .config
# 显式声明目标设备
echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_jcg_q30-pro=y" >> .config

echo "[minimal] make defconfig"
make defconfig

echo "[minimal] make"
export FORCE_UNSAFE_CONFIGURE=1
make -j"${JOBS:-$(( $(nproc) + 1 ))}"

echo "[minimal] collect images"
mkdir -p "$B/bisect/$TS"
cp -f bin/targets/mediatek/filogic/*jcg_q30-pro*.bin "$B/bisect/$TS/" 2>/dev/null || true
cp -f bin/targets/mediatek/filogic/sha256sums "$B/bisect/$TS/" 2>/dev/null || true
ls -la "$B/bisect/$TS/"
echo "[minimal] DONE TS=$TS"