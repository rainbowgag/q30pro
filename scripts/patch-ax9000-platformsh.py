#!/usr/bin/env python3
# 修复 Kwrt 04-stock.patch 对 ipq807x platform.sh 的 hunk 冲突。
# 上游 openwrt-25.12 在 xiaomi 系列的分支里多了一行 CI_DATA_UBIPART="rootfs"，
# 导致 04-stock.patch 的 platform.sh hunk 无法应用（bootcount 与 11-ath10k-caldata 正常）。
# 本脚本把 xiaomi 系列的单分区升级逻辑替换为 A/B 双分区（rootfs/rootfs_1）升级逻辑，幂等。
import io, sys

path = sys.argv[1] if len(sys.argv) > 1 else \
    'target/linux/qualcommax/ipq807x/base-files/lib/upgrade/platform.sh'

s = io.open(path, encoding='utf-8').read()

old = ('\tredmi,ax6|\\\n'
       '\txiaomi,ax3600|\\\n'
       '\txiaomi,ax9000)\n'
       '\t\t# Make sure that UART is enabled\n'
       '\t\tfw_setenv boot_wait on\n'
       '\t\tfw_setenv uart_en 1\n'
       '\n'
       '\t\t# Enforce single partition.\n'
       '\t\tfw_setenv flag_boot_rootfs 0\n'
       '\t\tfw_setenv flag_last_success 0\n'
       '\t\tfw_setenv flag_boot_success 1\n'
       '\t\tfw_setenv flag_try_sys1_failed 8\n'
       '\t\tfw_setenv flag_try_sys2_failed 8\n'
       '\n'
       '\t\t# Kernel and rootfs are placed in 2 different UBI\n'
       '\t\tCI_KERN_UBIPART="ubi_kernel"\n'
       '\t\tCI_ROOT_UBIPART="rootfs"\n'
       '\t\tCI_DATA_UBIPART="rootfs"\n'
       '\t\tnand_do_upgrade "$1"\n'
       '\t\t;;')

new = ('\tredmi,ax6|\\\n'
       '\txiaomi,ax3600|\\\n'
       '\txiaomi,ax9000)\n'
       '\t\tpart_num="$(fw_printenv -n flag_boot_rootfs)"\n'
       '\t\tif [ "$part_num" -eq "1" ]; then\n'
       '\t\t\tCI_UBIPART="rootfs_1"\n'
       '\t\t\ttarget_num=1\n'
       '\t\t\t# Reset fail flag for the current partition\n'
       '\t\t\t# With both partition set to fail, the partition 2 (bit 1)\n'
       '\t\t\t# is loaded\n'
       '\t\t\tfw_setenv flag_try_sys2_failed 0\n'
       '\t\telse\n'
       '\t\t\tCI_UBIPART="rootfs"\n'
       '\t\t\ttarget_num=0\n'
       '\t\t\t# Reset fail flag for the current partition\n'
       '\t\t\t# or uboot will skip the loading of this partition\n'
       '\t\t\tfw_setenv flag_try_sys1_failed 0\n'
       '\t\tfi\n'
       '\n'
       '\t\t# Tell uboot to switch partition\n'
       '\t\tfw_setenv flag_boot_rootfs "$target_num"\n'
       '\t\tfw_setenv flag_last_success "$target_num"\n'
       '\n'
       '\t\t# Reset success flag\n'
       '\t\tfw_setenv flag_boot_success 0\n'
       '\n'
       '\t\tnand_do_upgrade "$1"\n'
       '\t\t;;')

if new in s:
    print('ALREADY PATCHED: %s' % path)
    sys.exit(0)

if old not in s:
    print('UNRECOGNIZED platform.sh content (neither old nor new xiaomi block found): %s' % path, file=sys.stderr)
    sys.exit(1)

s = s.replace(old, new, 1)
io.open(path, 'w', encoding='utf-8').write(s)
print('PATCHED: %s' % path)