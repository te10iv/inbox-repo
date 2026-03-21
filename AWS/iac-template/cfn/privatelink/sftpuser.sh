#!/bin/bash
# sftpuser.sh - Script to create an SFTP-only user with chroot jail on Linux
# Usage: sudo bash sftpuser.sh
set -e
# 1) Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Use sudo." >&2
  exit 1
fi
# 2) Install OpenSSH server if not present
if ! command -v sshd >/dev/null 2>&1; then
  echo "OpenSSH server not found. Installing..."
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    apt-get install -y openssh-server
  elif command -v yum >/dev/null 2>&1; then
    yum install -y openssh-server
  else
    echo "Unsupported package manager. Please install OpenSSH server manually." >&2
    exit 1
  fi
fi
# 3) Ensure sshd service is running
systemctl enable sshd
systemctl start sshd
# 4) Create SFTP-only user
SFTP_USER="sftpuser"
if ! id "${SFTP_USER}" >/dev/null 2>&1; then
  useradd "${SFTP_USER}"
fi
# Set password (demo). In production, prefer key auth and disable password auth.
echo "${SFTP_USER}:ChangeMe123!" | chpasswd
# 5) Prepare chroot directory structure
# ChrootDirectory must be owned by root and not writable by the user.
mkdir -p "/home/${SFTP_USER}/upload"
chown root:root "/home/${SFTP_USER}"
chmod 755 "/home/${SFTP_USER}"
chown "${SFTP_USER}:${SFTP_USER}" "/home/${SFTP_USER}/upload"
chmod 700 "/home/${SFTP_USER}/upload"
# 6) Update sshd_config for SFTP-only chroot user
SSHD_CONFIG="/etc/ssh/sshd_config"
# Ensure Subsystem uses internal-sftp (idempotent)
if grep -qE '^\s*Subsystem\s+sftp\s+' "${SSHD_CONFIG}"; then
  sed -i 's|^\s*Subsystem\s\+sftp\s\+.*$|Subsystem sftp internal-sftp|g' "${SSHD_CONFIG}"
else
      echo "Subsystem sftp internal-sftp" >> "${SSHD_CONFIG}"
    fi
    # Add Match block only if not present (idempotent)
    if ! grep -qE "^\s*Match\s+User\s+${SFTP_USER}\b" "${SSHD_CONFIG}"; then
      cat >> "${SSHD_CONFIG}" <<EOF
Match User ${SFTP_USER}
  ChrootDirectory /home/${SFTP_USER}
  ForceCommand internal-sftp
  AllowTcpForwarding no
  X11Forwarding no
  KbdInteractiveAuthentication yes
  AuthenticationMethods password
EOF
fi
# (Optional hardening) Disable SSH password auth globally if desired:
# sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "${SSHD_CONFIG}"
# 7) Restart sshd to apply changes
systemctl restart sshd

# # 動作確認
# id sftpuser
# uid=1001(sftpuser) gid=1001(sftpuser) groups=1001(sftpuser)
# # 失敗
# id: ‘sftpuser’: no such user
# ls -ld /home/sftpuser
# drwxr-xr-x  root     root     /home/sftpuser
# ls -ld /home/sftpuser/upload
# drwx------  sftpuser sftpuser /home/sftpuser/upload
# grep -A5 -n "Match User sftpuser" /etc/ssh/sshd_config
# # 期待値
# Match User sftpuser
#   ChrootDirectory /home/sftpuser
#   ForceCommand internal-sftp
#   AllowTcpForwarding no
#   X11Forwarding no
# grep "^Subsystem sftp" /etc/ssh/sshd_config
# Subsystem sftp internal-sftp
# systemctl status sshd
# EC2 ローカルで SFTP 接続テスト（重要）
# sftp sftpuser@localhost
# パスワードを聞かれ、ログインできれば成功。
# pwd
# ls
# cd upload
# put /etc/hostname test.txt
# ls
# exit
# # これだと動かなかったので以下を追加設定
# sudo su
# vi /etc/ssh/sshd_config
# # Match User sftpuserの下に以下を追加
#   PasswordAuthentication yes
#   KbdInteractiveAuthentication yes
#   AuthenticationMethods password