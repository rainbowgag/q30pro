#!/bin/bash
# 二分测试 B1：完整配置 + openclash/argon-config，但去掉 files 覆盖（无 uci-defaults/clash_meta/editor/config.yaml）
# 用于判断 bootloop 根因在「files 覆盖」还是「openclash 包」。
set -euo pipefail
B=/root/q30-build
O=$B/openwrt
cd "$O"
TS=$(date +%Y%m%d-%H%M%S)

# 备份/移除 files 覆盖
if [ -d files ]; then
  mv files "$B/bisect/files.full-$TS.bak"
  echo "[b1] moved files/ away"
fi

make defconfig
export FORCE_UNSAFE_CONFIGURE=1
make -j"${JOBS:-$(( $(nproc) + 1 ))}"

mkdir -p "$B/bisect/b1-$TS"
cp -f bin/targets/mediatek/filogic/*jcg_q30-pro*.bin "$B/bisect/b1-$TS/" 2>/dev/null || true
cp -f bin/targets/mediatek/filogic/sha256sums "$B/bisect/b1-$TS/" 2>/dev/null || true
ls -la "$B/bisect/b1-$TS/"
echo "[b1] DONE TS=$TS"