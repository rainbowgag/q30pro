#!/usr/bin/env python3
"""从远程下载文件到本地（paramiko SFTP）。用法：
  $env:VPS_PASS='...'; python scripts/vps-get.py <remote> <local>
"""
import os
import sys
import paramiko

host = os.environ.get("VPS_HOST", "154.36.168.118")
port = int(os.environ.get("VPS_PORT", "22"))
user = os.environ.get("VPS_USER", "root")
pwd = os.environ.get("VPS_PASS", "")
remote, local = sys.argv[1], sys.argv[2]

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
sftp = client.open_sftp()
sftp.get(remote, local)
sftp.close()
client.close()
print("downloaded: %s -> %s" % (remote, local))
