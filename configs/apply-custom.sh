#!/bin/bash
# 本项目固件定制脚本。在 openwrt 源码目录内执行（cwd=openwrt，configs 位于 ../configs）。
# 时机：Kwrt 的 devices/common/diy.sh + 目标 diy.sh + patches 之后、make defconfig 之前。
set -e

# 0) 确保 kiddin9 feed 软链接存在（Kwrt 的 feeds install 可能漏建，导致包不进 Kconfig）
mkdir -p package/feeds/kiddin9
for d in feeds/kiddin9/*/; do
  [ -f "$d/Makefile" ] || continue
  name=$(basename "$d")
  case "$name" in
    zabbix-ssl|zabbix-extra-mac80211) continue ;;
  esac
  ln -sfn "../../../feeds/kiddin9/$name" "package/feeds/kiddin9/$name"
done

# 1) 修复 jcg,q30-pro 升级路径：与参考机一致，走 nand_do_upgrade（默认分支）
sed -i '/jcg,q30-pro/d' target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh

# 2) 追加本项目 .config（单 profile + 主题/插件）
echo >> .config
cat ../configs/custom.config >> .config
# 覆盖 ALL_PROFILES：common/.config 默认=y，单 profile 必须为 n
sed -i 's/^CONFIG_TARGET_ALL_PROFILES=.*/CONFIG_TARGET_ALL_PROFILES=n/' .config

# 3) files/ 覆盖（uci-defaults / openclash meta 内核 / openclash-editor / 默认 config.yaml）
mkdir -p files
cp -r ../configs/files/. files/

# 可执行权限：uci-defaults、openclash 内核、editor 后端与门户服务
chmod +x files/etc/uci-defaults/99-jcg-q30-defaults \
        files/etc/uci-defaults/zz-openclash-editor \
        files/etc/openclash/core/clash_meta \
        files/etc/init.d/openclash-editor-portal \
        files/etc/hotplug.d/iface/99-openclash-editor-portal \
        files/usr/share/openclash-editor/backend.rb \
        files/usr/share/openclash-editor/portal-watch.sh \
        files/usr/share/openclash-editor/update.sh

echo "apply-custom done"