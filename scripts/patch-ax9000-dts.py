#!/usr/bin/env python3
# 修复 AX9000 DTS（幂等）：
# 1) 把 QCA8075 的 4 个 PHY 节点包进 ethernet-phy-package(qcom,qca8075-package)。
# 2) 加 qcom,package-mode="qsgmii"（AX9000 的 switch_mac_mode=0xb=MAC_MODE_QSGMII，必须匹配）。
# 3) 给 dp1..dp4 补 phy-mode="qsgmii"、dp5 补 phy-mode="sgmii"（上游 DTS 有，Kwrt 覆盖版漏掉，导致有线只发不收）。
# 4) 删除底部对 dp1..dp5 nvmem-cells/nvmem-cell-names 的删除语句，恢复各网口独立 MAC（否则全部复用同一 MAC，电脑无法拿到地址/进后台）。
import io, sys

path = sys.argv[1] if len(sys.argv) > 1 else \
    'target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq8072-ax9000.dts'

s = io.open(path, encoding='utf-8').read()

# --- 1/2) PHY package 包裹 ---
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
       '\t\tqcom,package-mode = "qsgmii";\n'
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

if new not in s:
    if old in s:
        s = s.replace(old, new, 1)
    elif 'compatible = "qcom,qca8075-package";' in s and 'qcom,package-mode' not in s:
        s = s.replace('compatible = "qcom,qca8075-package";',
                      'compatible = "qcom,qca8075-package";\n\t\tqcom,package-mode = "qsgmii";', 1)

# --- 3) dp1..dp4 phy-mode=qsgmii, dp5 phy-mode=sgmii ---
for label, mode in [('dp1','qsgmii'),('dp2','qsgmii'),('dp3','qsgmii'),('dp4','qsgmii'),('dp5','sgmii')]:
    head = '&%s {\n' % label
    idx = s.find(head)
    if idx == -1:
        continue
    # 仅在该节点块内判断是否已有 phy-mode，避免被其它节点误判
    end = s.find('\n};\n', idx)
    node_blk = s[idx:end + 4] if end != -1 else s[idx:idx + 200]
    if ('\tphy-mode = "%s";\n' % mode) in node_blk:
        continue
    anchor = '\tstatus = "okay";\n'
    aidx = s.find(anchor, idx)
    if aidx == -1:
        continue
    ins = aidx + len(anchor)
    s = s[:ins] + '\tphy-mode = "%s";\n' % mode + s[ins:]

# --- 4) 删除底部 dp1..dp5 的 nvmem 删除语句，恢复独立 MAC ---
for label in ['dp1','dp2','dp3','dp4','dp5']:
    block = ('&%s {\n'
             '\t/delete-property/ nvmem-cells;\n'
             '\t/delete-property/ nvmem-cell-names;\n'
             '};\n') % label
    if block in s:
        s = s.replace(block, '', 1)

io.open(path, 'w', encoding='utf-8').write(s)
print('PATCHED DTS(qsgmii+phy-mode+mac): %s' % path)
