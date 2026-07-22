# Rocky Build Log

date: 2026-07-22 | agent: Cody | status: In Progress

## Objective

Build Rocky as a single native OpenClaw agent on VPS4, verify it end to end, and document a repeatable human and AI-agent procedure.

## Baseline

- Ubuntu 24.04.4 LTS
- 4 vCPU
- 15 GiB RAM
- 193 GiB root disk
- No OpenClaw, Node.js, Docker, or Caddy installed
- No swap initially configured
- Only SSH listening publicly
- Host timezone initially UTC

## Completed

- Verified SSH access with the dedicated VPS4 key.
- Corrected the local Windows ACL on that private key so OpenSSH would accept it.
- Changed the server timezone to `America/Edmonton`.
- Added a 4 GiB swap file and made it persistent.
- Enabled UFW with inbound SSH allowed and other inbound traffic denied.
- Installed base packages: curl, CA certificates, Git, jq, rsync, UFW, and sudo.
- Created the dedicated `openclaw` runtime account.
- Enabled systemd lingering for the runtime account.
- Created the Node compile-cache directory owned by the runtime account.

## Current Gate

Install the current stable OpenClaw release under the dedicated runtime account, then start xAI/Grok device-code OAuth with Jack.

## Tracking

- GitHub issue: https://github.com/ZedBiz44/ZedBiz-openclaw-vps4/issues/1
- Notion SOP: https://app.notion.com/p/371a3e33d5818357872d0198ecade27d

