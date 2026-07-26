#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

version="${GOG_VERSION:-0.34.1}"
archive="gogcli_${version}_linux_amd64.tar.gz"
base_url="https://github.com/openclaw/gogcli/releases/download/v${version}"
work_dir="$(mktemp -d)"

cleanup() {
  rm -rf -- "$work_dir"
}
trap cleanup EXIT

curl -fsSL "$base_url/$archive" -o "$work_dir/$archive"
curl -fsSL "$base_url/checksums.txt" -o "$work_dir/checksums.txt"

(
  cd "$work_dir"
  grep "  $archive\$" checksums.txt | sha256sum --check -
  tar -xzf "$archive"
)

gog_binary="$(find "$work_dir" -maxdepth 2 -type f -name gog -print -quit)"
[[ -n "$gog_binary" ]] || {
  echo "The release archive did not contain a gog binary." >&2
  exit 1
}

openclaw_home="/home/openclaw"
secure_bin_dir="$openclaw_home/.local/secure-bin"
wrapper="$openclaw_home/bin/gog"
config_dir="$openclaw_home/.config/gogcli"
keyring_env="$config_dir/keyring.env"
dropin_dir="$openclaw_home/.config/systemd/user/openclaw-gateway.service.d"
runtime_dir="/run/user/$(id -u openclaw)"

install -d -o root -g root -m 0755 "$secure_bin_dir"
install -o root -g root -m 0755 "$gog_binary" "$secure_bin_dir/gog-real"
install -d -o openclaw -g openclaw -m 0755 "$openclaw_home/bin"
install -d -o openclaw -g openclaw -m 0700 "$config_dir"

if [[ ! -s "$keyring_env" ]]; then
  umask 077
  printf 'GOG_KEYRING_PASSWORD=%s\n' "$(openssl rand -hex 32)" > "$keyring_env"
  chown openclaw:openclaw "$keyring_env"
fi
chmod 0600 "$keyring_env"

cat > "$wrapper" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
export HOME=/home/openclaw
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
set -a
# shellcheck disable=SC1091
source /home/openclaw/.config/gogcli/keyring.env
set +a
exec /home/openclaw/.local/secure-bin/gog-real "$@"
EOF
chown openclaw:openclaw "$wrapper"
chmod 0700 "$wrapper"

install -d -o openclaw -g openclaw -m 0755 "$dropin_dir"
cat > "$dropin_dir/gog-path.conf" <<'EOF'
[Service]
Environment=OPENCLAW_PATH_BOOTSTRAPPED=1
EOF
chown openclaw:openclaw "$dropin_dir/gog-path.conf"
chmod 0644 "$dropin_dir/gog-path.conf"

# Remove temporary direct copies from earlier/manual installations. Rocky must
# use the wrapper so encrypted OAuth tokens are available non-interactively.
rm -f /usr/bin/gog /usr/local/bin/gog "$openclaw_home/.npm-global/bin/gog"

sudo -iu openclaw env \
  HOME=/home/openclaw \
  OPENCLAW_PATH_BOOTSTRAPPED=1 \
  gog --version

sudo -iu openclaw env HOME=/home/openclaw gog auth keyring file

sudo -u openclaw env HOME="$openclaw_home" XDG_RUNTIME_DIR="$runtime_dir" \
  systemctl --user daemon-reload
sudo -u openclaw env HOME="$openclaw_home" XDG_RUNTIME_DIR="$runtime_dir" \
  systemctl --user restart openclaw-gateway.service

echo "gog is installed for Rocky with an encrypted file keyring. Google OAuth authorization is still required."
