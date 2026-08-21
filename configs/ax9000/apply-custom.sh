#!/bin/bash
# Xiaomi AX9000 定制脚本。在 openwrt 源码目录内执行（cwd=openwrt）。
set -e

# 0) 补建 kiddin9 feed 软链接
mkdir -p package/feeds/kiddin9
for d in feeds/kiddin9/*/; do
  [ -f "$d/Makefile" ] || continue
  name=$(basename "$d")
  case "$name" in
    zabbix-ssl|zabbix-extra-mac80211) continue ;;
  esac
  ln -sfn "../../../feeds/kiddin9/$name" "package/feeds/kiddin9/$name"
done

# 1) xiaomi,ax9000 无需 sed platform.sh（Kwrt 04-stock.patch 已处理）

# 2) 追加 .config
echo >> .config
cat ../configs/ax9000/custom.config >> .config
sed -i 's/^CONFIG_TARGET_ALL_PROFILES=.*/CONFIG_TARGET_ALL_PROFILES=n/' .config

# 3) files 覆盖
mkdir -p files
# 3.1 共享文件（clash_meta / editor / config.yaml / nginx 纯 HTTP / NCSI）
cp -f ../configs/files/etc/openclash/core/clash_meta files/etc/openclash/core/ 2>/dev/null || true
cp -f ../configs/files/etc/openclash/config/config.yaml files/etc/openclash/config/ 2>/dev/null || true
cp -f ../configs/files/etc/uci-defaults/zz-openclash-editor files/etc/uci-defaults/ 2>/dev/null || true
cp -rf ../configs/files/usr/share/openclash-editor/. files/usr/share/openclash-editor/ 2>/dev/null || true
cp -rf ../configs/files/usr/lib/lua/luci/controller/openclash_editor.lua files/usr/lib/lua/luci/controller/ 2>/dev/null || true
cp -rf ../configs/files/usr/lib/lua/luci/view/openclash_editor/. files/usr/lib/lua/luci/view/openclash_editor/ 2>/dev/null || true
cp -rf ../configs/files/www/luci-static/resources/openclash-editor/. files/www/luci-static/resources/openclash-editor/ 2>/dev/null || true
cp -f ../configs/files/etc/init.d/openclash-editor-portal files/etc/init.d/ 2>/dev/null || true
cp -f ../configs/files/etc/hotplug.d/iface/99-openclash-editor-portal files/etc/hotplug.d/iface/ 2>/dev/null || true
cp -f ../configs/files/etc/config/nginx files/etc/config/ 2>/dev/null || true
mkdir -p files/etc/nginx/conf.d
cp -f ../configs/files/etc/nginx/conf.d/30-ncsi.locations files/etc/nginx/conf.d/ 2>/dev/null || true

# 3.2 AX9000 专属
cp -r ../configs/ax9000/files/. files/

chmod +x files/etc/uci-defaults/99-ax9000-defaults \
        files/etc/uci-defaults/zz-openclash-editor \
        files/etc/hotplug.d/ieee80211/30-ax9000-wifi \
        files/etc/openclash/core/clash_meta \
        files/etc/init.d/openclash-editor-portal \
        files/etc/hotplug.d/iface/99-openclash-editor-portal \
        files/usr/share/openclash-editor/backend.rb \
        files/usr/share/openclash-editor/portal-watch.sh \
        files/usr/share/openclash-editor/update.sh

echo "ax9000 apply-custom done"