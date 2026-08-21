# JCG Q30 PRO 定制 OpenWrt 固件

为 JCG Q30 PRO（MediaTek MT7981B / Filogic 820，128MB NAND）编译定制 OpenWrt 固件。

- 构建在远程 VPS 上进行，本地仓库保存构建配置与定制文件。
- 项目规则：`AGENTS.md`
- 当前进度：`HANDOFF.md`
- 架构说明：`docs/ARCHITECTURE.md`
- **编译指南（含踩坑经验）：`docs/BUILD-GUIDE.md`**

## 快速开始

```bash
git clone https://github.com/rainbowgag/q30pro.git /root/q30-build
cd /root/q30-build
setsid bash scripts/build-kwrt.sh > build.log 2>&1 < /dev/null &
```

产物：`/root/q30-build/openwrt/bin/targets/mediatek/filogic/*jcg_q30-pro*.bin`

详见 `docs/BUILD-GUIDE.md`。