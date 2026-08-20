#!/bin/bash
# 保守重建（二分定位 bootloop）：
#   在「当前完整定制 .config」基础上，仅移除本项目新增的 openclash / luci-app-argon-config，
#   并去掉 files 覆盖（uci-defaults + clash_meta）。
#   保留 passwall / argon / 单 profile / 其余全部设置（与完整构建一致，仅差这两个包与 files）。
# 判定：
#   - 能启动  -> 根因在 openclash / argon-config / files 覆盖，再逐个加回定位。
#   - bootloop -> 根因在 openwrt-25.12 分支/内核（6.12.103 vs stock 6.12.94），锁定提交重建。
set -euo pipefail
B=/root/q30-build
O=$B/openwrt
cd "$O"

TS=$(date +%Y%m%d-%H%M%S)
mkdir -p "$B/bisect"

# 1) 备份当前完整 .config 与 files
echo "[minimal] backup full .config -> $B/bisect/.config.full.$TS.bak"
cp -f .config "$B/bisect/.config.full.$TS.bak"
if [ -d files ]; then
  echo "[minimal] backup full files -> $B/bisect/files.full.$TS.bak"
  mv files "$B/bisect/files.full.$TS.bak"
fi

# 2) 仅移除本项目新增的两个包（保留 passwall/argon 与单 profile）
sed -i '/^CONFIG_PACKAGE_luci-app-openclash/d' .config
sed -i '/^CONFIG_PACKAGE_luci-app-argon-config/d' .config

# 3) 确保单 profile（完整 .config 已含 ALL_PROFILES=n 与 jcg_q30-pro=y；这里兜底）
sed -i 's/^CONFIG_TARGET_ALL_PROFILES=.*/CONFIG_TARGET_ALL_PROFILES=n/' .config
grep -q 'CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_jcg_q30-pro=y' .config \
  || echo 'CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_jcg_q30-pro=y' >> .config

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