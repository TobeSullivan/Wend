#!/usr/bin/env bash
# Push the built Wend server to the Hetzner VPS and (re)start it.
# Run from the repo root in Git Bash / WSL / any bash:  bash deploy/deploy.sh root@<VPS_IP>
#
# Prereqs on this machine: the binary is built (deploy/build/wend_server.x86_64),
# ssh + scp available, and your SSH key is authorized on the box.
# First-time box setup (create user, firewall, install the unit) is in deploy/README.md —
# this script only ships a new binary and bounces the service.
set -euo pipefail

TARGET="${1:?usage: bash deploy/deploy.sh user@host}"
BIN="deploy/build/wend_server.x86_64"
UNIT="deploy/wend-server.service"

[ -f "$BIN" ] || { echo "missing $BIN — build first (see deploy/README.md 'Build')"; exit 1; }

SSHOPT="-o StrictHostKeyChecking=accept-new"

echo ">> uploading binary + unit to $TARGET"
scp $SSHOPT "$BIN"  "$TARGET:/tmp/wend_server.x86_64"
scp $SSHOPT "$UNIT" "$TARGET:/tmp/wend-server.service"

echo ">> installing on remote"
ssh $SSHOPT "$TARGET" 'bash -s' <<'REMOTE'
set -euo pipefail
id wend >/dev/null 2>&1 || useradd --system --home /opt/wend --shell /usr/sbin/nologin wend
install -d -o wend -g wend /opt/wend
install -m 0755 -o wend -g wend /tmp/wend_server.x86_64 /opt/wend/wend_server.x86_64
install -m 0644 /tmp/wend-server.service /etc/systemd/system/wend-server.service
rm -f /tmp/wend_server.x86_64 /tmp/wend-server.service
systemctl daemon-reload
systemctl enable wend-server.service
systemctl restart wend-server.service
sleep 1
systemctl --no-pager --lines=12 status wend-server.service || true
REMOTE

echo ">> done. Tail logs with:  ssh $TARGET journalctl -u wend-server -f"
