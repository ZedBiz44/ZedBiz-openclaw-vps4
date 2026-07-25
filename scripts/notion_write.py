#!/usr/bin/env python3
"""Narrow, logged Notion write helper for Rocky."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
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
    if len(text) > 2000:
        raise NotionError("Append text exceeds Notion's 2,000-character rich-text limit")
    return request(
        token,
        "PATCH",
        f"/blocks/{page_id}/children",
        {"children": [paragraph(text)]},
    )


def mountain_timestamp() -> str:
    return dt.datetime.now(ZoneInfo("America/Edmonton")).isoformat(timespec="seconds")


def normalize_page_id(value: str) -> str:
    path_value = value.split("?", 1)[0].split("#", 1)[0].rstrip("/")
    final_segment = path_value.rsplit("/", 1)[-1]
    hex_chars = re.sub(r"(?i)[^0-9a-f]", "", final_segment)
    if len(hex_chars) < 32:
        raise NotionError("Target must be an approved alias, Notion page URL, or page ID")
    # Notion URLs may prefix the ID with a page title. Some titles end in
    # hexadecimal characters (for example, "Chad"), so always take the final
    # 32 hexadecimal characters rather than the first regex-sized chunk.
    raw = hex_chars[-32:].lower()
    return f"{raw[:8]}-{raw[8:12]}-{raw[12:16]}-{raw[16:20]}-{raw[20:]}"


def page_title(page: dict) -> str:
    for prop in page.get("properties", {}).values():
        if prop.get("type") != "title":
            continue
        title = "".join(item.get("plain_text", "") for item in prop.get("title", []))
        if title:
            return title
    return "(untitled)"


def resolve_target(token: str, config: dict, target: str) -> tuple[str, str, str]:
    if target in config["pages"]:
        item = config["pages"][target]
        return target, item["id"], item["title"]

    target_id = normalize_page_id(target)
    target_page = request(token, "GET", f"/pages/{target_id}")
    roots = {item["id"]: alias for alias, item in config["pages"].items()}
    current = target_page

    for _ in range(12):
        current_id = current["id"]
        if current_id in roots:
            return roots[current_id], target_id, page_title(target_page)
        parent = current.get("parent", {})
        if parent.get("type") != "page_id":
            break
        current = request(token, "GET", f"/pages/{parent['page_id']}")

    raise NotionError(
        "Target is outside the six approved VA edit-page trees; no write attempted"
    )


def verify_block_text(token: str, block_id: str, expected: str) -> None:
    block = request(token, "GET", f"/blocks/{block_id}")
    block_type = block.get("type")
    rich_text = block.get(block_type, {}).get("rich_text", [])
    actual = "".join(item.get("plain_text", "") for item in rich_text)
    if actual != expected:
        raise NotionError(
            f"Appended block verification failed for block {block_id}"
        )


def log_attempt(
    token: str,
    config: dict,
    *,
    source: str,
    root_alias: str,
    target_title: str,
    target_id: str,
    summary: str,
    status: str,
    verification: str,
    action: str = "append",
    approval_required: str = "no",
    error: str = "",
) -> None:
    safe_summary = summary.replace("\n", " ").strip()[:500]
    safe_error = error.replace("\n", " ").strip()[:500]
    fields = [
        f"Date/time: {mountain_timestamp()}",
        "Agent: Rocky",
        f"Request source: {source}",
        f"VA area: {root_alias}",
        f"Target: {target_title}",
        f"Target ID: {target_id}",
        f"Action: {action}",
        f"Summary: {safe_summary}",
        f"Status: {status}",
        f"Approval required: {approval_required}",
        f"Verification: {verification}",
    ]
    if safe_error:
        fields.append(f"Error: {safe_error}")
    append_text(token, config["log_page_id"], " | ".join(fields))


def block_text(block: dict) -> str:
    block_type = block.get("type")
    rich_text = block.get(block_type, {}).get("rich_text", [])
    return "".join(item.get("plain_text", "") for item in rich_text)


def matching_child_blocks(token: str, page_id: str, expected: str) -> list[dict]:
    matches: list[dict] = []
    cursor = ""
    while True:
        suffix = f"?page_size=100&start_cursor={cursor}" if cursor else "?page_size=100"
        response = request(token, "GET", f"/blocks/{page_id}/children{suffix}")
        for block in response.get("results", []):
            if not block.get("archived") and block_text(block) == expected:
                matches.append(block)
        if not response.get("has_more"):
            return matches
        cursor = response.get("next_cursor", "")
        if not cursor:
            raise NotionError("Notion pagination ended without a next cursor")


def archive_block(token: str, block_id: str) -> None:
    result = request(token, "PATCH", f"/blocks/{block_id}", {"archived": True})
    if not result.get("archived"):
        raise NotionError(f"Source block archive verification failed for block {block_id}")


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
    root_alias, target_id, target_title = resolve_target(
        token, config, args.target
    )
    try:
        appended = append_text(token, target_id, args.text)
    except NotionError as exc:
        try:
            log_attempt(
                token,
                config,
                source=args.source,
                root_alias=root_alias,
                target_title=target_title,
                target_id=target_id,
                summary=args.text,
                status="failed",
                verification="target write failed",
                error=str(exc),
            )
        except NotionError as log_exc:
            raise NotionError(f"Target write failed; write-log also failed: {log_exc}") from exc
        raise

    try:
        results = appended.get("results", [])
        if len(results) != 1 or not results[0].get("id"):
            raise NotionError("Notion did not return the appended block ID")
        block_id = results[0]["id"]
        verify_block_text(token, block_id, args.text)
        verification = f"exact appended block verified: {block_id}"
        log_attempt(
            token,
            config,
            source=args.source,
            root_alias=root_alias,
            target_title=target_title,
            target_id=target_id,
            summary=args.text,
            status="success",
            verification=verification,
        )
    except NotionError as exc:
        raise NotionError(
            "Target append succeeded, but verification or mandatory write logging failed: "
            f"{exc}"
        ) from exc

    canonical_url = f"https://app.notion.com/p/{target_id.replace('-', '')}"
    print(
        "append successful: "
        f"title={target_title} id={target_id} url={canonical_url} "
        f"approved_root={root_alias}; exact block verified; write logged"
    )
    return 0


def command_relocate(token: str, config: dict, args: argparse.Namespace) -> int:
    if args.approved_by.strip().lower() != "jack":
        raise NotionError("Relocate requires explicit --approved-by Jack")

    source_root, source_id, source_title = resolve_target(token, config, args.source_page)
    target_root, target_id, target_title = resolve_target(token, config, args.target_page)
    if source_root != target_root:
        raise NotionError("Relocate source and target must be in the same approved VA tree")
    if source_id == target_id:
        raise NotionError("Relocate source and target cannot be the same page")

    source_matches = matching_child_blocks(token, source_id, args.text)
    if len(source_matches) != 1:
        raise NotionError(
            f"Relocate requires exactly one matching source block; found {len(source_matches)}"
        )

    target_matches = matching_child_blocks(token, target_id, args.text)
    if len(target_matches) > 1:
        raise NotionError(
            f"Relocate found {len(target_matches)} matching target blocks; no change attempted"
        )

    if target_matches:
        target_block_id = target_matches[0]["id"]
        target_verification = f"existing exact target block verified: {target_block_id}"
    else:
        appended = append_text(token, target_id, args.text)
        results = appended.get("results", [])
        if len(results) != 1 or not results[0].get("id"):
            raise NotionError("Notion did not return the relocated target block ID")
        target_block_id = results[0]["id"]
        verify_block_text(token, target_block_id, args.text)
        target_verification = f"exact target block verified: {target_block_id}"

    source_block_id = source_matches[0]["id"]
    try:
        archive_block(token, source_block_id)
    except NotionError as exc:
        log_attempt(
            token,
            config,
            source=args.source,
            root_alias=source_root,
            target_title=target_title,
            target_id=target_id,
            summary=args.text,
            status="partial",
            verification=f"{target_verification}; source block not archived",
            action="relocate",
            approval_required="yes - approved by Jack",
            error=str(exc),
        )
        raise NotionError(
            "Target copy is verified, but the misplaced source block could not be archived; "
            "do not retry automatically"
        ) from exc

    verification = (
        f"{target_verification}; source block archived and verified: {source_block_id}"
    )
    log_attempt(
        token,
        config,
        source=args.source,
        root_alias=source_root,
        target_title=target_title,
        target_id=target_id,
        summary=args.text,
        status="success",
        verification=verification,
        action="relocate",
        approval_required="yes - approved by Jack",
    )
    canonical_url = f"https://app.notion.com/p/{target_id.replace('-', '')}"
    print(
        "relocate successful: "
        f"from_title={source_title} from_id={source_id} "
        f"to_title={target_title} to_id={target_id} url={canonical_url} "
        f"approved_root={target_root}; exact target verified; source archived; write logged"
    )
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
    append_parser.add_argument(
        "target",
        help="Approved alias or a descendant Notion page URL/ID",
    )
    append_parser.add_argument("text")
    append_parser.add_argument("--source", default="Jack")

    relocate_parser = subparsers.add_parser(
        "relocate",
        help="Move one exact paragraph between pages in the same approved tree",
    )
    relocate_parser.add_argument("source_page", help="Approved source alias or page URL/ID")
    relocate_parser.add_argument("target_page", help="Approved target alias or page URL/ID")
    relocate_parser.add_argument("text", help="Exact paragraph text to relocate")
    relocate_parser.add_argument("--source", default="Jack")
    relocate_parser.add_argument("--approved-by", required=True)
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
        if args.command == "relocate":
            return command_relocate(token, config, args)
        raise NotionError(f"Unsupported command: {args.command}")
    except (NotionError, OSError, json.JSONDecodeError) as exc:
        print(str(exc), file=sys.stderr)
        return 2
    finally:
        token = ""


if __name__ == "__main__":
    raise SystemExit(main())
