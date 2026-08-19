#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root on VPS4." >&2
  exit 1
fi

restart_passcode_file="${RESTART_PASSCODE_FILE:?Set RESTART_PASSCODE_FILE to a local passcode file before running}"
install_dir="/opt/zedbiz-restart-api"

[[ -f "$restart_passcode_file" ]] || { echo "Missing restart passcode file" >&2; exit 1; }

install -d -o root -g root -m 0755 "$install_dir"
install -o root -g root -m 0600 "$restart_passcode_file" "$install_dir/restart.passcode"

cat > "$install_dir/server.py" <<'PY'
#!/usr/bin/env python3
import json
import os
import subprocess
import threading
import time
import urllib.request
import ssl
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

VPS_ID = os.environ.get("VPS_ID", "vps4")
BIND_HOST = os.environ.get("BIND_HOST", "127.0.0.1")
PORT = int(os.environ.get("PORT", "8787"))
PASSCODE_FILE = os.environ.get("PASSCODE_FILE", "/opt/zedbiz-restart-api/restart.passcode")
ALLOWED_ORIGIN = "https://agents.zbiz.ca"
AGENTS = {"rocky"}
HOSTS = {"rocky": "https://rocky.zbiz.ca/health"}
SERVICE_NAME = "openclaw-gateway.service"
LOCK = threading.Lock()
HEALTH_TIMEOUT_SECONDS = 150


def utc_now():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def tail(text, limit=3000):
    return (text or "")[-limit:]


def read_passcode():
    with open(PASSCODE_FILE, "r", encoding="utf-8") as f:
        return f.read().strip()


def run(cmd, timeout=120):
    return subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=timeout)


def response(handler, code, payload):
    body = json.dumps(payload).encode("utf-8")
    handler.send_response(code)
    handler.send_header("Content-Type", "application/json")
    handler.send_header("Content-Length", str(len(body)))
    handler.send_header("Access-Control-Allow-Origin", ALLOWED_ORIGIN)
    handler.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
    handler.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type")
    handler.end_headers()
    handler.wfile.write(body)


def service_state():
    proc = run([
        "/usr/bin/systemctl", "--user", "-M", "openclaw@", "show", SERVICE_NAME,
        "-p", "ActiveState", "-p", "SubState", "-p", "MainPID", "-p", "ActiveEnterTimestamp", "--no-pager",
    ], timeout=30)
    state = {"raw": tail(proc.stdout, 1200), "returncode": proc.returncode}
    for line in proc.stdout.splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            state[key] = value
    return state


def is_service_active():
    state = service_state()
    return state.get("ActiveState") == "active" and state.get("SubState") == "running", state


def public_health(agent):
    ctx = ssl.create_default_context()
    req = urllib.request.Request(HOSTS[agent], headers={"User-Agent": "zedbiz-restart-api/1.0"})
    with urllib.request.urlopen(req, timeout=8, context=ctx) as resp:
        body = resp.read(800).decode("utf-8", errors="replace")
        return {"http_status": resp.status, "body": body, "ok": 200 <= resp.status < 300}


def wait_public_health(agent):
    deadline = time.time() + HEALTH_TIMEOUT_SECONDS
    last = None
    while time.time() < deadline:
        try:
            last = public_health(agent)
            if last.get("ok") and '"ok":true' in last.get("body", "").replace(" ", ""):
                return True, last
        except Exception as exc:
            last = {"ok": False, "error": str(exc)}
        time.sleep(3)
    return False, last


def wait_active(before_pid):
    deadline = time.time() + 80
    latest = service_state()
    while time.time() < deadline:
        active, latest = is_service_active()
        if active and latest.get("MainPID") and latest.get("MainPID") != before_pid:
            return latest
        time.sleep(2)
    return latest


def restart_agent(agent):
    started_at = time.time()
    requested_at = utc_now()
    before = service_state()
    before_pid = before.get("MainPID")
    stages = [{"name": "Restart requested", "at": requested_at, "ok": True}]

    restart = run(["/usr/bin/systemctl", "--user", "-M", "openclaw@", "restart", SERVICE_NAME], timeout=120)
    output = restart.stdout
    if restart.returncode != 0:
        stages.append({"name": "Service restart command failed", "at": utc_now(), "ok": False})
        return 500, {
            "ok": False, "agent": agent, "vps": VPS_ID, "method": "systemd user service restart",
            "requested_at": requested_at, "completed_at": utc_now(),
            "duration_seconds": round(time.time() - started_at, 1), "before": before,
            "after": service_state(), "changed": False, "health_ok": False,
            "final_status": "Service restart command failed", "stages": stages, "output": tail(output),
        }
    stages.append({"name": "Service restart command accepted", "at": utc_now(), "ok": True})

    after = wait_active(before_pid)
    changed = bool(after.get("MainPID") and after.get("MainPID") != before_pid and after.get("ActiveState") == "active")
    stages.append({"name": "New service process detected" if changed else "Service process did not change", "at": utc_now(), "ok": changed})

    health_ok, health = wait_public_health(agent)
    stages.append({"name": "Healthy again" if health_ok else "Health check timed out", "at": utc_now(), "ok": health_ok})
    ok = changed and health_ok
    return (200 if ok else 500), {
        "ok": ok, "agent": agent, "vps": VPS_ID, "method": "systemd user service restart",
        "requested_at": requested_at, "completed_at": utc_now(),
        "duration_seconds": round(time.time() - started_at, 1), "before": before,
        "after": after, "changed": changed, "health_ok": health_ok, "health": health,
        "final_status": "Healthy again" if ok else "Restart proof failed", "stages": stages,
        "output": tail(output),
    }


class Handler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        response(self, 204, {})

    def do_POST(self):
        parts = self.path.strip("/").split("/")
        if len(parts) != 3 or parts[0] != "_zedbiz-restarts" or parts[1] != VPS_ID:
            response(self, 404, {"ok": False, "error": "Not found"})
            return
        if self.headers.get("Authorization", "") != "Bearer " + read_passcode():
            response(self, 401, {"ok": False, "error": "Unauthorized"})
            return
        agent = parts[2].lower()
        if agent not in AGENTS:
            response(self, 404, {"ok": False, "error": "Unknown VPS4 agent"})
            return
        if not LOCK.acquire(blocking=False):
            response(self, 409, {"ok": False, "error": "Restart already running"})
            return
        try:
            code, payload = restart_agent(agent)
            response(self, code, payload)
        except subprocess.TimeoutExpired as exc:
            response(self, 504, {"ok": False, "vps": VPS_ID, "agent": agent, "final_status": "Restart timed out", "error": str(exc)})
        except Exception as exc:
            response(self, 500, {"ok": False, "vps": VPS_ID, "agent": agent, "final_status": "Restart failed", "error": str(exc)})
        finally:
            LOCK.release()

    def log_message(self, fmt, *args):
        print("%s - %s" % (self.address_string(), fmt % args), flush=True)


if __name__ == "__main__":
    server = ThreadingHTTPServer((BIND_HOST, PORT), Handler)
    print(f"zedbiz restart api listening on {BIND_HOST}:{PORT} for {VPS_ID}", flush=True)
    server.serve_forever()
PY
chmod 0755 "$install_dir/server.py"

cat > /etc/systemd/system/zedbiz-rocky-restart-api.service <<'UNIT'
[Unit]
Description=ZedBiz Rocky restart API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Environment=VPS_ID=vps4
Environment=BIND_HOST=127.0.0.1
Environment=PORT=8787
Environment=PASSCODE_FILE=/opt/zedbiz-restart-api/restart.passcode
ExecStart=/usr/bin/python3 /opt/zedbiz-restart-api/server.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now zedbiz-rocky-restart-api.service
systemctl restart zedbiz-rocky-restart-api.service
systemctl is-active --quiet zedbiz-rocky-restart-api.service

echo "Rocky restart API is installed on 127.0.0.1:8787"
