#!/usr/bin/env python3
# 修复 AX9000 DTS：把 QCA8075 的 4 个 PHY 节点包进 ethernet-phy-package(qcom,qca8075-package)。
# 否则 qca807x PHY 驱动 probe 时 package 匹配失败返回 -EINVAL，导致 4 个 LAN 口有线不通（只发不收）。
import io, sys

path = sys.argv[1] if len(sys.argv) > 1 else \
    'target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq8072-ax9000.dts'

s = io.open(path, encoding='utf-8').read()

old = ('\tqca8075_0: ethernet-phy@0 {\n'
       '\t\tcompatible = "ethernet-phy-ieee802.3-c22";\n'
       '\t\treg = <0>;\n'
       '\t};\n'
       '\n'
       '\tqca8075_1: ethernet-phy@1 {\n'
       '\t\tcompatible = "ethernet-phy-ieee802.3-c22";\n'
       '\t\treg = <1>;\n'
       '\t};\n'
       '\n'
       '\tqca8075_2: ethernet-phy@2 {\n'
       '\t\tcompatible = "ethernet-phy-ieee802.3-c22";\n'
       '\t\treg = <2>;\n'
       '\t};\n'
       '\n'
       '\tqca8075_3: ethernet-phy@3 {\n'
       '\t\tcompatible = "ethernet-phy-ieee802.3-c22";\n'
       '\t\treg = <3>;\n'
       '\t};\n')

new = ('\tethernet-phy-package@0 {\n'
       '\t\tcompatible = "qcom,qca8075-package";\n'
       '\t\t#address-cells = <1>;\n'
       '\t\t#size-cells = <0>;\n'
       '\t\treg = <0>;\n'
       '\n'
       '\t\tqca8075_0: ethernet-phy@0 {\n'
       '\t\t\tcompatible = "ethernet-phy-ieee802.3-c22";\n'
       '\t\t\treg = <0>;\n'
       '\t\t};\n'
       '\n'
       '\t\tqca8075_1: ethernet-phy@1 {\n'
       '\t\t\tcompatible = "ethernet-phy-ieee802.3-c22";\n'
       '\t\t\treg = <1>;\n'
       '\t\t};\n'
       '\n'
       '\t\tqca8075_2: ethernet-phy@2 {\n'
       '\t\t\tcompatible = "ethernet-phy-ieee802.3-c22";\n'
       '\t\t\treg = <2>;\n'
       '\t\t};\n'
       '\n'
       '\t\tqca8075_3: ethernet-phy@3 {\n'
       '\t\t\tcompatible = "ethernet-phy-ieee802.3-c22";\n'
       '\t\t\treg = <3>;\n'
       '\t\t};\n'
       '\t};\n')

if new in s:
    print('ALREADY PATCHED: %s' % path)
    sys.exit(0)

if old not in s:
    print('OLD DTS BLOCK NOT FOUND: %s' % path, file=sys.stderr)
    sys.exit(1)

s = s.replace(old, new, 1)
io.open(path, 'w', encoding='utf-8').write(s)
print('PATCHED DTS: %s' % path)