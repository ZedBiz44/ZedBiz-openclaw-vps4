#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

vps1_host="${VPS1_HOST:?Set VPS1_HOST before running}"
openclaw_uid="$(id -u openclaw)"
runtime_dir="/run/user/$openclaw_uid"
ssh_dir="/home/openclaw/.ssh"
workspace="/home/openclaw/.openclaw/workspace"
wiki_dir="$workspace/shared-memory-wiki"

sudo -u openclaw ssh-keyscan -H "$vps1_host" >> "$ssh_dir/known_hosts"
sort -u "$ssh_dir/known_hosts" -o "$ssh_dir/known_hosts"
chown openclaw:openclaw "$ssh_dir/known_hosts"
chmod 0600 "$ssh_dir/known_hosts"

cat > /etc/systemd/system/rocky-vps1-tunnel.service <<EOF
[Unit]
Description=Rocky private reverse tunnel to VPS1 Caddy
After=network-online.target
Wants=network-online.target

[Service]
User=openclaw
ExecStart=/usr/bin/ssh -NT -i $ssh_dir/vps1-caddy-tunnel -o BatchMode=yes -o StrictHostKeyChecking=yes -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -R 127.0.0.1:3012:127.0.0.1:18789 jackadmin@$vps1_host
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

install -d -o openclaw -g openclaw -m 0755 "$wiki_dir"
install -d -o openclaw -g openclaw -m 0755 /home/openclaw/bin

cat > /home/openclaw/bin/sync-vps1-shared-wiki.sh <<EOF
#!/usr/bin/env bash
set -euo pipefail
/usr/bin/rsync -rz --delete --checksum \
  -e '/usr/bin/ssh -i $ssh_dir/vps1-wiki-rsync -o BatchMode=yes -o StrictHostKeyChecking=yes' \
  jackadmin@$vps1_host:/ $wiki_dir/
EOF
chown openclaw:openclaw /home/openclaw/bin/sync-vps1-shared-wiki.sh
chmod 0750 /home/openclaw/bin/sync-vps1-shared-wiki.sh

user_unit_dir="/home/openclaw/.config/systemd/user"
install -d -o openclaw -g openclaw -m 0755 "$user_unit_dir"

cat > "$user_unit_dir/rocky-wiki-sync.service" <<'EOF'
[Unit]
Description=Sync VPS1 shared Memory Wiki to Rocky
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/home/openclaw/bin/sync-vps1-shared-wiki.sh
EOF

cat > "$user_unit_dir/rocky-wiki-sync.timer" <<'EOF'
[Unit]
Description=Run Rocky shared Memory Wiki sync every 15 minutes

[Timer]
OnBootSec=2m
OnUnitActiveSec=15m
Persistent=true

[Install]
WantedBy=timers.target
EOF

chown openclaw:openclaw "$user_unit_dir/rocky-wiki-sync.service" "$user_unit_dir/rocky-wiki-sync.timer"

systemctl daemon-reload
systemctl enable --now rocky-vps1-tunnel.service
sudo -u openclaw env XDG_RUNTIME_DIR="$runtime_dir" systemctl --user daemon-reload
sudo -u openclaw env XDG_RUNTIME_DIR="$runtime_dir" systemctl --user enable --now rocky-wiki-sync.timer
sudo -u openclaw env XDG_RUNTIME_DIR="$runtime_dir" systemctl --user start rocky-wiki-sync.service

echo "Rocky's private Caddy tunnel and read-only wiki sync are installed"

