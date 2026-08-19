#!/usr/bin/env bash
set -euo pipefail

# Reproducibly prepare Rocky's local media and caption-transcription lane.
# OpenAI Whisper runs locally and does not require an API credential.

openclaw_home="/home/openclaw"
openclaw_bin="$openclaw_home/.npm-global/bin/openclaw"
uv_bin="$openclaw_home/.local/bin/uv"
whisper_target="$openclaw_home/.local/share/uv/tools/openai-whisper/bin/whisper"
runtime_dir="/run/user/$(id -u openclaw)"

if [[ ! -x "$uv_bin" ]]; then
  echo "Missing Rocky uv binary: $uv_bin" >&2
  exit 1
fi

DEBIAN_FRONTEND=noninteractive apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y ffmpeg python3-venv

runuser -u openclaw -- env \
  HOME="$openclaw_home" \
  PATH="$openclaw_home/.local/bin:/usr/bin:/bin" \
  "$uv_bin" tool install openai-whisper

ln -sfn "$whisper_target" /usr/local/bin/whisper
ln -sfn "$whisper_target" /usr/bin/whisper

runuser -u openclaw -- "$whisper_target" --help >/dev/null

# The long-running gateway caches binary eligibility, so refresh it after
# installing Whisper and then confirm OpenClaw exposes the bundled skill.
runuser -u openclaw -- env \
  HOME="$openclaw_home" \
  XDG_RUNTIME_DIR="$runtime_dir" \
  systemctl --user restart openclaw-gateway

sleep 3

runuser -u openclaw -- env \
  HOME="$openclaw_home" \
  PATH="/usr/bin:$openclaw_home/.npm-global/bin:/usr/local/bin:/bin:$openclaw_home/.local/bin:$openclaw_home/bin" \
  "$openclaw_bin" skills info openai-whisper | grep -F "openai-whisper ✓ Ready"

runuser -u openclaw -- env \
  HOME="$openclaw_home" \
  XDG_RUNTIME_DIR="$runtime_dir" \
  systemctl --user is-active --quiet openclaw-gateway

echo "Rocky local media tools and OpenAI Whisper are ready."
