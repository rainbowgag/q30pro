#!/bin/bash
# 完整版构建：argon + passwall + openclash(meta/锁定) + openclash-editor + 默认 config.yaml + files 覆盖
set -euo pipefail
B=/root/q30-build
O=$B/openwrt
cd "$O"
TS=$(date +%Y%m%d-%H%M%S)

# 1) 恢复完整 .config（含 openclash/argon/argon-config/passwall）
cp -f "$B/bisect/.config.full.20260820-094048.bak" .config

# 2) 应用本项目定制（重新生成 files/，并追加 custom.config，新增 ruby-psych）
bash "$B/configs/apply-custom.sh"

# 3) defconfig + make
make defconfig
export FORCE_UNSAFE_CONFIGURE=1
make -j"${JOBS:-$(( $(nproc) + 1 ))}"

# 4) 收集产物
mkdir -p "$B/bisect/full-$TS"
cp -f bin/targets/mediatek/filogic/*jcg_q30-pro*.bin "$B/bisect/full-$TS/" 2>/dev/null || true
cp -f bin/targets/mediatek/filogic/sha256sums "$B/bisect/full-$TS/" 2>/dev/null || true
ls -la "$B/bisect/full-$TS/"
echo "[full] DONE TS=$TS"