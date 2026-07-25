#!/usr/bin/env python3
"""Narrow, logged Notion write helper for Rocky."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path
from zoneinfo import ZoneInfo


API_BASE = "https://api.notion.com/v1"
NOTION_VERSION = "2025-09-03"
DEFAULT_CONFIG = Path("/home/openclaw/.config/openclaw/rocky-notion-write.json")


class NotionError(RuntimeError):
    pass


def load_config(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        config = json.load(handle)
    if not config.get("log_page_id"):
        raise NotionError("Rocky-Notion-Write-Log is not configured")
    if not config.get("pages"):
        raise NotionError("No approved Notion pages are configured")
    return config


def request(token: str, method: str, path: str, payload: dict | None = None) -> dict:
    body = None if payload is None else json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        f"{API_BASE}{path}",
        data=body,
        method=method,
        headers={
            "Authorization": f"Bearer {token}",
            "Notion-Version": NOTION_VERSION,
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        try:
            parsed = json.loads(detail)
            message = parsed.get("message", detail)
        except json.JSONDecodeError:
            message = detail
        raise NotionError(f"Notion API returned HTTP {exc.code}: {message}") from exc
    except urllib.error.URLError as exc:
        raise NotionError(f"Notion API connection failed: {exc.reason}") from exc


def paragraph(text: str) -> dict:
    return {
        "object": "block",
        "type": "paragraph",
        "paragraph": {
            "rich_text": [
                {
                    "type": "text",
                    "text": {"content": text},
                }
            ]
        },
    }


def append_text(token: str, page_id: str, text: str) -> dict:
    return request(
        token,
        "PATCH",
        f"/blocks/{page_id}/children",
        {"children": [paragraph(text)]},
    )


def mountain_timestamp() -> str:
    return dt.datetime.now(ZoneInfo("America/Edmonton")).isoformat(timespec="seconds")


def log_attempt(
    token: str,
    config: dict,
    *,
    source: str,
    alias: str,
    target_id: str,
    summary: str,
    status: str,
    verification: str,
    error: str = "",
) -> None:
    safe_summary = summary.replace("\n", " ").strip()[:500]
    safe_error = error.replace("\n", " ").strip()[:500]
    fields = [
        f"Date/time: {mountain_timestamp()}",
        "Agent: Rocky",
        f"Request source: {source}",
        f"VA area: {alias}",
        f"Target: {config['pages'][alias]['title']}",
        f"Target ID: {target_id}",
        "Action: append",
        f"Summary: {safe_summary}",
        f"Status: {status}",
        "Approval required: no",
        f"Verification: {verification}",
    ]
    if safe_error:
        fields.append(f"Error: {safe_error}")
    append_text(token, config["log_page_id"], " | ".join(fields))


def command_access(token: str, config: dict) -> int:
    failures = 0
    targets = {
        **{alias: item["id"] for alias, item in config["pages"].items()},
        "write-log": config["log_page_id"],
    }
    for alias, page_id in targets.items():
        try:
            request(token, "GET", f"/pages/{page_id}")
            print(f"{alias}: accessible")
        except NotionError as exc:
            failures += 1
            print(f"{alias}: blocked ({exc})", file=sys.stderr)
    return 0 if failures == 0 else 2


def command_append(token: str, config: dict, args: argparse.Namespace) -> int:
    if args.alias not in config["pages"]:
        allowed = ", ".join(sorted(config["pages"]))
        raise NotionError(f"Target is not approved. Allowed aliases: {allowed}")

    target = config["pages"][args.alias]
    try:
        append_text(token, target["id"], args.text)
    except NotionError as exc:
        try:
            log_attempt(
                token,
                config,
                source=args.source,
                alias=args.alias,
                target_id=target["id"],
                summary=args.text,
                status="failed",
                verification="target write failed",
                error=str(exc),
            )
        except NotionError as log_exc:
            raise NotionError(f"Target write failed; write-log also failed: {log_exc}") from exc
        raise

    try:
        request(token, "GET", f"/pages/{target['id']}")
        verification = "target page fetched after append"
        log_attempt(
            token,
            config,
            source=args.source,
            alias=args.alias,
            target_id=target["id"],
            summary=args.text,
            status="success",
            verification=verification,
        )
    except NotionError as exc:
        raise NotionError(
            "Target append succeeded, but verification or mandatory write logging failed: "
            f"{exc}"
        ) from exc

    print(f"append successful: {target['title']}; write logged")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--config",
        type=Path,
        default=DEFAULT_CONFIG,
        help=argparse.SUPPRESS,
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("access", help="Verify access to every approved page and log")

    append_parser = subparsers.add_parser("append", help="Append text to an approved page")
    append_parser.add_argument("alias")
    append_parser.add_argument("text")
    append_parser.add_argument("--source", default="Jack")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    token = os.environ.get("ROCKY_NOTION_WRITE_TOKEN", "")
    if not token:
        print("ROCKY_NOTION_WRITE_TOKEN is unavailable", file=sys.stderr)
        return 2
    try:
        config = load_config(args.config)
        if args.command == "access":
            return command_access(token, config)
        if args.command == "append":
            return command_append(token, config, args)
        raise NotionError(f"Unsupported command: {args.command}")
    except (NotionError, OSError, json.JSONDecodeError) as exc:
        print(str(exc), file=sys.stderr)
        return 2
    finally:
        token = ""


if __name__ == "__main__":
    raise SystemExit(main())
