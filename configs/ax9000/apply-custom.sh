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
# 3.1 共享文件（nginx 纯 HTTP + NCSI）
cp -f ../configs/files/etc/config/nginx files/etc/config/ 2>/dev/null || true
mkdir -p files/etc/nginx/conf.d
cp -f ../configs/files/etc/nginx/conf.d/30-ncsi.locations files/etc/nginx/conf.d/ 2>/dev/null || true

# 3.2 AX9000 专属
cp -r ../configs/ax9000/files/. files/

chmod +x files/etc/uci-defaults/99-ax9000-defaults \
        files/etc/hotplug.d/ieee80211/30-ax9000-wifi

echo "ax9000 apply-custom done"