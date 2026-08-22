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

# 1) 修复 Kwrt 04-stock.patch 对 platform.sh 的 hunk 冲突，应用 A/B 双分区升级逻辑（幂等）
python3 ../scripts/patch-ax6-platformsh.py target/linux/qualcommax/ipq807x/base-files/lib/upgrade/platform.sh

# 2) 追加本项目 .config（单 profile + 主题/插件）
echo >> .config
cat ../configs/ax6/custom.config >> .config
sed -i 's/^CONFIG_TARGET_ALL_PROFILES=.*/CONFIG_TARGET_ALL_PROFILES=n/' .config

# 2b) 排除不需要/易失败的默认包：
#   qosify 在 25.12 下依赖 bpf/clang 且编译失败；本项目不需要 QoS。
#   ruby YJIT 需要 rust/host（会触发超长的 LLVM/rustc 构建）；编辑器仅需纯 ruby。
sed -i 's/^CONFIG_PACKAGE_qosify=.*/# CONFIG_PACKAGE_qosify is not set/' .config
sed -i 's/^CONFIG_RUBY_ENABLE_YJIT=.*/# CONFIG_RUBY_ENABLE_YJIT is not set/' .config

# 3) files 覆盖
mkdir -p files

# 3.1 共享文件（来自 Q30 的 configs/files，仅复制 openclash 内核/配置与 openclash-editor，
#     不复制 nginx(NCSI) 与 Q30 专属的 30-jcg-wifi）
mkdir -p files/etc/openclash/core
mkdir -p files/etc/openclash/config
mkdir -p files/etc/uci-defaults
mkdir -p files/etc/init.d
mkdir -p files/etc/hotplug.d/iface
mkdir -p files/usr/share/openclash-editor
mkdir -p files/usr/lib/lua/luci/controller
mkdir -p files/usr/lib/lua/luci/view
mkdir -p files/www/luci-static/resources

cp -f  ../configs/files/etc/openclash/core/clash_meta files/etc/openclash/core/
cp -f  ../configs/files/etc/openclash/config/config.yaml files/etc/openclash/config/
cp -f  ../configs/files/etc/uci-defaults/zz-openclash-editor files/etc/uci-defaults/
cp -f  ../configs/files/etc/init.d/openclash-editor-portal files/etc/init.d/
cp -f  ../configs/files/etc/hotplug.d/iface/99-openclash-editor-portal files/etc/hotplug.d/iface/
cp -rf ../configs/files/usr/share/openclash-editor/. files/usr/share/openclash-editor/
cp -f  ../configs/files/usr/lib/lua/luci/controller/openclash_editor.lua files/usr/lib/lua/luci/controller/
cp -rf ../configs/files/usr/lib/lua/luci/view/openclash_editor/. files/usr/lib/lua/luci/view/openclash_editor/
cp -rf ../configs/files/www/luci-static/resources/openclash-editor/. files/www/luci-static/resources/openclash-editor/

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