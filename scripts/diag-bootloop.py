#!/usr/bin/env python3
"""诊断 bootloop：反复短超时 SSH 到设备，捕捉 up 窗口并抓崩溃日志。
用法: python scripts/diag-bootloop.py <host> [pass1,pass2,...] [attempts]
"""
import sys
import time
import paramiko

host = sys.argv[1] if len(sys.argv) > 1 else "192.168.100.1"
passwords = (sys.argv[2].split(",") if len(sys.argv) > 2 and sys.argv[2] else ["root"])
attempts = int(sys.argv[3]) if len(sys.argv) > 3 else 30

cmd = "uptime; echo ===DMESG-TAIL===; dmesg | tail -25; echo ===LOGREAD-TAIL===; logread 2>/dev/null | tail -35"

for i in range(attempts):
    for pwd in passwords:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        try:
            client.connect(host, 22, "root", pwd, timeout=3, allow_agent=False, look_for_keys=False)
            _i, out, _e = client.exec_command(cmd, timeout=12)
            data = out.read().decode("utf-8", "replace")
            print("CONNECTED attempt=", i, "pass=", pwd)
            print(data)
            client.close()
            sys.exit(0)
        except Exception:
            client.close()
    sys.stdout.write(".")
    sys.stdout.flush()
    time.sleep(1)

print()
print("FAILED after", attempts, "attempts")
sys.exit(1)
