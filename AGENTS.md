# AGENTS.md — 项目规则（JCG Q30 PRO 定制固件）

## 项目定位
为 JCG Q30 PRO（MediaTek MT7981B / Filogic 820，128MB NAND）编译定制 OpenWrt 固件。
面向普通用户：出厂即带 PassWall + OpenClash（内置 Meta 内核、锁定自更新）与 Argon 主题，
默认关闭 IPv6，后台地址 192.168.100.1。

## 技术栈
- 构建系统：kiddin9/Kwrt（分支 25.12，编排层；实际编译 openwrt/openwrt 的 openwrt-25.12 分支）
- 目标：mediatek / filogic / jcg_q30-pro（架构 aarch64_cortex-a53）
- 构建环境：远程 VPS（Linux），连接信息见 HANDOFF.md
- 定制载体：.config（diffconfig 快照）+ files/ 覆盖 + devices 补丁 + scripts/

## 构建 / 测试 / 运行命令
构建在 VPS 上进行，完整流程以 scripts/build-kwrt.sh 为准（阶段1 校准）。
核心命令（在 VPS 的 openwrt 源码目录内）：

    ./scripts/feeds update -a && ./scripts/feeds install -a
    make defconfig
    make -j$(($(nproc)+1))

产物目录：openwrt/bin/targets/mediatek/filogic/（含 *-sysupgrade.bin 与 *-factory.bin）

## 代码约定
- 所有固件改动必须在本地仓库落盘：diffconfig / files/ / patches/ / scripts/，禁止只在 VPS 上改源码
- 每次成功构建后，导出 diffconfig 并提交（./scripts/diffconfig.sh > configs/diffconfig/jcg-q30-pro.diffconfig）
- git 提交信息用中文并标注阶段号，例如：阶段3：jcg-q30-pro 单 profile 与默认设置
- 每次会话结束时，重写 HANDOFF.md 顶部三行交接块，并把完成项追加到「最近完成」

## 禁用事项（硬性需求，任何会话不得违反）
- 禁止默认启用 IPv6
- 禁止保留 OpenClash 内核 / 插件自更新入口（需锁定为不可更新）
- 禁止改动 5G WiFi：SSID=AA_5G、密码=asd12345；2.4G 保持默认禁用
- 禁止改动后台地址 192.168.100.1
- 禁止删除或改坏 AGENTS.md / HANDOFF.md / docs/ARCHITECTURE.md
