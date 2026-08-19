#!/bin/bash
# Kwrt 定制固件构建脚本（草案：阶段1 在 VPS 上校准后冻结）
# 用途：复刻 Kwrt GitHub Actions 的本地构建流程，只编译 jcg_q30-pro。
# 预期目录布局（BUILD_ROOT = Kwrt 检出根目录）：
#   BUILD_ROOT/devices/...    Kwrt 编排层（diy.sh/.config/patches）
#   BUILD_ROOT/openwrt/       上游 openwrt/openwrt 源码
set -euo pipefail

BUILD_ROOT="${BUILD_ROOT:-/root/q30-build}"
KWRT_BRANCH="${KWRT_BRANCH:-25.12}"
# 注意：openwrt-25.12 是滚动分支，Kwrt 的 devices 补丁会随上游更新而漂移。
# 2026-08 实测：HEAD=4a5c6b9 时 25-platform.patch 有 3 个 hunk 被拒。
# 阶段2/3 需把 OPENWRT_BRANCH 固定到 Kwrt 补丁匹配的 commit/tag，或手工解决冲突。
OPENWRT_BRANCH="${OPENWRT_BRANCH:-openwrt-25.12}"
TARGET="${TARGET:-mediatek_filogic}"
JOBS="${JOBS:-$(( $(nproc) + 1 ))}"

mkdir -p "$BUILD_ROOT"
cd "$BUILD_ROOT"

# 1) 获取 Kwrt 编排层（devices/ 等）
if [ ! -d devices ]; then
  tmp="$(mktemp -d)"
  git clone --depth 1 -b "$KWRT_BRANCH" https://github.com/kiddin9/Kwrt.git "$tmp"
  shopt -s dotglob
  mv "$tmp"/* .
  rmdir "$tmp"
fi

# 2) 获取上游 openwrt 源码（与 devices/ 同级）
if [ ! -d openwrt/.git ]; then
  git clone --depth 1 -b "$OPENWRT_BRANCH" https://github.com/openwrt/openwrt.git openwrt
fi

# 3) 复制定制层（复刻 workflow 的 "Load custom configuration"）
cp -rf devices/common/. openwrt/
cp -rf "devices/$TARGET/." openwrt/
cp -rf devices openwrt/
cd openwrt

# git_clone_path：Kwrt diy.sh 会调用；复刻自 workflow 的定义
git_clone_path() {
  trap 'rm -rf "$tmpdir"' EXIT
  branch="$1" rurl="$2" mv="$3"
  [[ "$mv" != "mv" ]] && shift 2 || shift 3
  rootdir="$PWD"
  tmpdir="$(mktemp -d)" || exit 1
  if [ "${#branch}" -lt 10 ]; then
    git clone -b "$branch" --depth 1 --filter=blob:none --sparse "$rurl" "$tmpdir"
    cd "$tmpdir"
  else
    git clone --filter=blob:none --sparse "$rurl" "$tmpdir"
    cd "$tmpdir"
    git checkout "$branch"
  fi
  git sparse-checkout init --cone
  git sparse-checkout set "$@"
  [[ "$mv" != "mv" ]] && cp -rn ./* "$rootdir/" || mv -n "$@"/* "$rootdir/$@/"
  cd "$rootdir"
}
export -f git_clone_path

# 4) 通用定制（内含 feeds update/install、默认包扩展、品牌改写等）
chmod +x devices/common/diy.sh
/bin/bash devices/common/diy.sh

# 5) 合并 .config（common + target）
cp -f devices/common/.config .config
if [ -f "devices/$TARGET/.config" ]; then
  echo >> .config
  cat "devices/$TARGET/.config" >> .config
fi

# 6) 目标级定制 + 自有 diy 覆盖
if [ -f "devices/$TARGET/diy.sh" ]; then
  chmod +x "devices/$TARGET/diy.sh"
  /bin/bash "devices/$TARGET/diy.sh"
fi
cp -Rf ./diy/* ./ 2>/dev/null || true

# 7) 打补丁（复刻 workflow 的 "Apply patches"）
cp -rn devices/common/patches "devices/$TARGET/"
find "devices/$TARGET/patches" -maxdepth 1 -type f -name '*.revert.patch' -print0 | sort -z | xargs -I % -t -0 -n 1 sh -c "patch -d './' -R --no-backup-if-mismatch -p1 -F 1 -i '%'"
find "devices/$TARGET/patches" -maxdepth 1 -type f -name '*.patch' ! -name '*.revert.patch' ! -name '*.bin.patch' -print0 | sort -z | xargs -I % -t -0 -n 1 sh -c "patch -d './' --no-backup-if-mismatch -p1 -F 1 -i '%'"

# 8) 本项目定制（单 profile、LAN=192.168.100.1、WiFi、关 IPv6、主题/插件）
if [ -f "$BUILD_ROOT/configs/apply-custom.sh" ]; then
  bash "$BUILD_ROOT/configs/apply-custom.sh"
fi

# 9) 构建（PREPARE_ONLY=1 时只做环境/feeds 准备，不编译）
if [ "${PREPARE_ONLY:-0}" = "1" ]; then
  echo "PREPARE_ONLY=1：准备完成，跳过 defconfig 与编译。"
  exit 0
fi
make defconfig
make -j"$JOBS"

echo "完成。产物：openwrt/bin/targets/mediatek/filogic/"
