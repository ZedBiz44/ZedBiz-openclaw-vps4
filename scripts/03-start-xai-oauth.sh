#!/usr/bin/env bash
set -euo pipefail

rm -f /tmp/rocky-xai-oauth.log /tmp/rocky-xai-oauth.pid

nohup script -q -f -c \
  "sudo -iu openclaw env PATH=/home/openclaw/.npm-global/bin:/usr/local/bin:/usr/bin:/bin openclaw models auth login --provider xai --method oauth" \
  /tmp/rocky-xai-oauth.log </dev/null >/dev/null 2>&1 &

echo "$!" > /tmp/rocky-xai-oauth.pid
echo "xAI OAuth process started"
