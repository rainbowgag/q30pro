#!/usr/bin/env python3
"""在 VPS 上执行命令并流式回显。凭据从环境变量读取，不在仓库中硬编码。
用法（PowerShell）：
  $env:VPS_PASS='...'; python scripts/vps.py 'uptime'
可用环境变量：
  VPS_HOST (默认 154.12.50.97)
  VPS_PORT (默认 22)
  VPS_USER (默认 root)
  VPS_PASS (必填)
"""
import os
import sys
import paramiko

host = os.environ.get("VPS_HOST", "154.12.50.97")
port = int(os.environ.get("VPS_PORT", "22"))
user = os.environ.get("VPS_USER", "root")
pwd = os.environ.get("VPS_PASS", "")
cmd = sys.argv[1] if len(sys.argv) > 1 else "echo ok"

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(
    hostname=host,
    port=port,
    username=user,
    password=pwd,
    timeout=30,
    allow_agent=False,
    look_for_keys=False,
)

# 用 PTY 让 stdout/stderr 合并并逐行流式输出，避免长命令期间无回显。
_stdin, stdout, _stderr = client.exec_command(cmd, timeout=None, get_pty=True)
_stdin.close()

for line in iter(stdout.readline, ""):
    sys.stdout.write(line)
    sys.stdout.flush()

rc = stdout.channel.recv_exit_status()
client.close()
sys.exit(rc)
