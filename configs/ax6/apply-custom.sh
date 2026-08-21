#!/bin/bash
# Redmi AX6 定制脚本。在 openwrt 源码目录内执行（cwd=openwrt）。
# 时机：Kwrt 的 devices/common/diy.sh + 目标 diy.sh + patches 之后、make defconfig 之前。
set -e

# 0) 补建 kiddin9 feed 软链接（Kwrt feeds install 可能漏建）
mkdir -p package/feeds/kiddin9
for d in feeds/kiddin9/*/; do
  [ -f "$d/Makefile" ] || continue
  name=$(basename "$d")
  case "$name" in
    zabbix-ssl|zabbix-extra-mac80211) continue ;;
  esac
  ln -sfn "../../../feeds/kiddin9/$name" "package/feeds/kiddin9/$name"
done

# 1) 注意：redmi,ax6 无需 sed platform.sh（Kwrt 04-stock.patch 已处理双分区升级）

# 2) 追加本项目 .config（单 profile + 主题/插件）
echo >> .config
cat ../configs/ax6/custom.config >> .config
sed -i 's/^CONFIG_TARGET_ALL_PROFILES=.*/CONFIG_TARGET_ALL_PROFILES=n/' .config

# 3) files 覆盖
mkdir -p files
# 3.1 共享文件（来自 Q30 的 configs/files，含 clash_meta/editor/config.yaml）
cp -f ../configs/files/etc/openclash/core/clash_meta files/etc/openclash/core/ 2>/dev/null || true
cp -f ../configs/files/etc/openclash/config/config.yaml files/etc/openclash/config/ 2>/dev/null || true
cp -f ../configs/files/etc/uci-defaults/zz-openclash-editor files/etc/uci-defaults/ 2>/dev/null || true
cp -rf ../configs/files/usr/share/openclash-editor/. files/usr/share/openclash-editor/ 2>/dev/null || true
cp -rf ../configs/files/usr/lib/lua/luci/controller/openclash_editor.lua files/usr/lib/lua/luci/controller/ 2>/dev/null || true
cp -rf ../configs/files/usr/lib/lua/luci/view/openclash_editor/. files/usr/lib/lua/luci/view/openclash_editor/ 2>/dev/null || true
cp -rf ../configs/files/www/luci-static/resources/openclash-editor/. files/www/luci-static/resources/openclash-editor/ 2>/dev/null || true
cp -f ../configs/files/etc/init.d/openclash-editor-portal files/etc/init.d/ 2>/dev/null || true
cp -f ../configs/files/etc/hotplug.d/iface/99-openclash-editor-portal files/etc/hotplug.d/iface/ 2>/dev/null || true

# 3.2 AX6 专属文件
cp -r ../configs/ax6/files/. files/

# 可执行权限
chmod +x files/etc/uci-defaults/99-ax6-defaults \
        files/etc/uci-defaults/zz-openclash-editor \
        files/etc/hotplug.d/ieee80211/30-ax6-wifi \
        files/etc/openclash/core/clash_meta \
        files/etc/init.d/openclash-editor-portal \
        files/etc/hotplug.d/iface/99-openclash-editor-portal \
        files/usr/share/openclash-editor/backend.rb \
        files/usr/share/openclash-editor/portal-watch.sh \
        files/usr/share/openclash-editor/update.sh

echo "ax6 apply-custom done"