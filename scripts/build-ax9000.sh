#!/bin/bash
# Xiaomi AX9000 构建脚本（阶段8）。复刻 build-kwrt.sh 的本地构建流程，目标改为 qualcommax_ipq807x，
# 并在最后应用 configs/ax9000/apply-custom.sh（不含 openclash），再 defconfig && make。
# 预期目录布局（BUILD_ROOT = Kwrt 检出根目录）：
#   BUILD_ROOT/devices/...    Kwrt 编排层（diy.sh/.config/patches）
#   BUILD_ROOT/openwrt/       上游 openwrt/openwrt 源码
set -euo pipefail

BUILD_ROOT="${BUILD_ROOT:-/root/q30-build}"
KWRT_BRANCH="${KWRT_BRANCH:-25.12}"
OPENWRT_BRANCH="${OPENWRT_BRANCH:-openwrt-25.12}"
TARGET="qualcommax_ipq807x"
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

# 8) AX9000 定制（单 profile、LAN=192.168.100.1、三频 WiFi、关 IPv6、argon/passwall，无 openclash）
bash "$BUILD_ROOT/configs/ax9000/apply-custom.sh"

# 9) 构建（PREPARE_ONLY=1 时只做环境/feeds 准备，不编译）
if [ "${PREPARE_ONLY:-0}" = "1" ]; then
  echo "PREPARE_ONLY=1：准备完成，跳过 defconfig 与编译。"
  exit 0
fi
make defconfig
export FORCE_UNSAFE_CONFIGURE=1
make -j"$JOBS"

echo "完成。产物：openwrt/bin/targets/qualcommax/ipq807x/"