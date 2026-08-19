#!/usr/bin/env python3
"""上传本地文件到 VPS（paramiko SFTP）。用法：
  $env:VPS_PASS='...'; python scripts/vps-put.py <local> <remote>
"""
import os
import sys
import paramiko

host = os.environ.get("VPS_HOST", "154.36.168.118")
port = int(os.environ.get("VPS_PORT", "22"))
user = os.environ.get("VPS_USER", "root")
pwd = os.environ.get("VPS_PASS", "")
local, remote = sys.argv[1], sys.argv[2]

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
sftp.put(local, remote)
sftp.close()
client.close()
print("uploaded: %s -> %s" % (local, remote))
