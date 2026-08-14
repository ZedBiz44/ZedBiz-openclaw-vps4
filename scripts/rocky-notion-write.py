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

# Canonical invocation guard. The wrapper is the only component that obtains
# Rocky's 1Password-backed token. If an agent calls this implementation file
# directly, route it through the wrapper before parsing any command.
if os.environ.get("ROCKY_NOTION_WRITE_WRAPPER") != "1":
    wrapper = "/home/openclaw/bin/rocky-notion-write"
    os.execvpe(wrapper, [wrapper, *sys.argv[1:]], os.environ.copy())


class NotionError(RuntimeError):
    pass


def load_config(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        config = json.load(handle)
    if not config.get("log_page_id"):
        raise NotionError("Rocky-Notion-Write-Log is not configured")
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


def title_property(title: str) -> dict:
    return {
        "title": {
            "type": "title",
            "title": [{"type": "text", "text": {"content": title}}],
        }
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


def canonical_page_url(page_id: str) -> str:
    return f"https://app.notion.com/p/{page_id.replace('-', '')}"


def split_text(text: str, limit: int = 1900) -> list[str]:
    remaining = text.strip()
    chunks: list[str] = []
    while remaining:
        if len(remaining) <= limit:
            chunks.append(remaining)
            break
        split_at = max(
            remaining.rfind("\n\n", 0, limit),
            remaining.rfind("\n", 0, limit),
            remaining.rfind(" ", 0, limit),
        )
        if split_at < limit // 2:
            split_at = limit
        chunk = remaining[:split_at].strip()
        if chunk:
            chunks.append(chunk)
        remaining = remaining[split_at:].strip()
    return chunks


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
    """Authorize the exact target solely through the Notion write integration."""
    target_id = normalize_page_id(target)
    target_page = request(token, "GET", f"/pages/{target_id}")
    return "notion-connection", target_id, page_title(target_page)

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


def command_check(token: str, config: dict, args: argparse.Namespace) -> int:
    try:
        root_alias, target_id, target_title = resolve_target(token, config, args.target)
    except NotionError as exc:
        try:
            target_id = normalize_page_id(args.target)
        except NotionError:
            target_id = args.target[:100]
        log_attempt(
            token,
            config,
            source=args.source,
            root_alias="none",
            target_title="(unapproved or inaccessible)",
            target_id=target_id,
            summary="Requested destination preflight",
            status="denied",
            verification="no target write attempted",
            action="target check",
            approval_required="yes - alternative destination required",
            error=str(exc),
        )
        print(
            "target_status=denied: destination is outside Rocky's approved write trees "
            "or inaccessible to the write integration; no target write attempted; "
            "denial logged",
        )
        return 0

    print(
        "target_status=allowed: "
        f"title={target_title} id={target_id} url={canonical_page_url(target_id)} "
        f"authority=notion-connection"
    )
    return 0


def command_access(token: str, config: dict) -> int:
    try:
        request(token, "GET", f"/pages/{config['log_page_id']}")
        print("write-log: accessible")
        print("write authority: determined by the Rocky-Notion-Write-API Notion connection")
        return 0
    except NotionError as exc:
        print(f"write-log: blocked ({exc})", file=sys.stderr)
        return 2

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

    canonical_url = canonical_page_url(target_id)
    print(
        "append successful: "
        f"title={target_title} id={target_id} url={canonical_url} "
        f"authority=notion-connection; exact block verified; write logged"
    )
    return 0


def command_create_copy(token: str, config: dict, args: argparse.Namespace) -> int:
    if args.approved_by.strip().lower() != "jack":
        raise NotionError("Create-copy requires explicit --approved-by Jack")

    root_alias, parent_id, parent_title = resolve_target(token, config, args.parent)
    title = args.title.strip()
    content = args.content.strip()
    if not title:
        raise NotionError("Create-copy title cannot be empty")
    if len(title) > 200:
        raise NotionError("Create-copy title exceeds the 200-character safety limit")
    if not content:
        raise NotionError("Create-copy content cannot be empty")
    if len(content) > 12000:
        raise NotionError("Create-copy content exceeds the 12,000-character safety limit")

    created = request(
        token,
        "POST",
        "/pages",
        {
            "parent": {"type": "page_id", "page_id": parent_id},
            "properties": title_property(title),
        },
    )
    created_id = created.get("id", "")
    if not created_id:
        raise NotionError("Notion did not return the created working-copy page ID")

    verified_blocks: list[str] = []
    try:
        fetched = request(token, "GET", f"/pages/{created_id}")
        if page_title(fetched) != title:
            raise NotionError("Created working-copy title verification failed")
        for chunk in split_text(content):
            appended = append_text(token, created_id, chunk)
            results = appended.get("results", [])
            if len(results) != 1 or not results[0].get("id"):
                raise NotionError("Notion did not return a copied-content block ID")
            block_id = results[0]["id"]
            verify_block_text(token, block_id, chunk)
            verified_blocks.append(block_id)
    except NotionError as exc:
        log_attempt(
            token,
            config,
            source=args.source,
            root_alias=root_alias,
            target_title=title,
            target_id=created_id,
            summary=f"Working copy from {args.source_url}: {content}",
            status="partial",
            verification=f"{len(verified_blocks)} copied blocks verified",
            action="create working copy",
            approval_required="yes - approved by Jack",
            error=str(exc),
        )
        raise NotionError(
            "Working-copy page was created, but content verification or logging failed; "
            "do not retry automatically"
        ) from exc

    verification = (
        f"created page and {len(verified_blocks)} copied content blocks verified"
    )
    log_attempt(
        token,
        config,
        source=args.source,
        root_alias=root_alias,
        target_title=title,
        target_id=created_id,
        summary=f"Working copy from {args.source_url}: {content}",
        status="success",
        verification=verification,
        action="create working copy",
        approval_required="yes - approved by Jack",
    )
    print(
        "create-copy successful: "
        f"title={title} id={created_id} url={canonical_page_url(created_id)} "
        f"parent_title={parent_title} parent_id={parent_id} "
        f"authority=notion-connection; content verified; write logged"
    )
    return 0


def command_replace(token: str, config: dict, args: argparse.Namespace) -> int:
    root_alias, target_id, target_title = resolve_target(token, config, args.target)
    if len(args.new_text) > 2000:
        raise NotionError("Replacement text exceeds Notion's 2,000-character limit")
    matches = matching_child_blocks(token, target_id, args.old_text)
    if len(matches) != 1:
        raise NotionError(
            f"Replace requires exactly one matching paragraph; found {len(matches)}"
        )
    block = matches[0]
    if block.get("type") != "paragraph":
        raise NotionError("Replace currently supports exact paragraph blocks only")
    block_id = block["id"]
    request(
        token,
        "PATCH",
        f"/blocks/{block_id}",
        {"paragraph": paragraph(args.new_text)["paragraph"]},
    )
    verify_block_text(token, block_id, args.new_text)
    log_attempt(
        token,
        config,
        source=args.source,
        root_alias=root_alias,
        target_title=target_title,
        target_id=target_id,
        summary=f"Replaced exact paragraph: {args.old_text} -> {args.new_text}",
        status="success",
        verification=f"exact replacement block verified: {block_id}",
        action="replace paragraph",
    )
    print(
        "replace successful: "
        f"title={target_title} id={target_id} url={canonical_page_url(target_id)} "
        f"authority=notion-connection; exact block verified; write logged"
    )
    return 0


def command_relocate(token: str, config: dict, args: argparse.Namespace) -> int:
    if args.approved_by.strip().lower() != "jack":
        raise NotionError("Relocate requires explicit --approved-by Jack")

    source_root, source_id, source_title = resolve_target(token, config, args.source_page)
    target_root, target_id, target_title = resolve_target(token, config, args.target_page)
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
    canonical_url = canonical_page_url(target_id)
    print(
        "relocate successful: "
        f"from_title={source_title} from_id={source_id} "
        f"to_title={target_title} to_id={target_id} url={canonical_url} "
        f"authority=notion-connection; exact target verified; source archived; write logged"
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

    subparsers.add_parser("access", help="Verify access to Rocky-Notion-Write-Log and the Notion-controlled write route")

    check_parser = subparsers.add_parser(
        "check",
        help="Check whether a requested destination is accessible through the Notion write connection",
    )
    check_parser.add_argument("target", help="Notion page URL/ID to preflight")
    check_parser.add_argument("--source", default="Jack")

    append_parser = subparsers.add_parser("append", help="Append text to an approved page")
    append_parser.add_argument(
        "target",
        help="Notion page URL or page ID accessible to the Rocky write connection",
    )
    append_parser.add_argument("text")
    append_parser.add_argument("--source", default="Jack")

    create_parser = subparsers.add_parser(
        "create-copy",
        help="Create a controlled text working copy under an approved page",
    )
    create_parser.add_argument("parent", help="Approved parent alias or page URL/ID")
    create_parser.add_argument("title")
    create_parser.add_argument("content")
    create_parser.add_argument("--source-url", required=True)
    create_parser.add_argument("--source", default="Jack")
    create_parser.add_argument("--approved-by", required=True)

    replace_parser = subparsers.add_parser(
        "replace",
        help="Replace one exact paragraph on an approved page",
    )
    replace_parser.add_argument("target", help="Approved page alias or URL/ID")
    replace_parser.add_argument("old_text")
    replace_parser.add_argument("new_text")
    replace_parser.add_argument("--source", default="Jack")

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
        if args.command == "check":
            return command_check(token, config, args)
        if args.command == "append":
            return command_append(token, config, args)
        if args.command == "create-copy":
            return command_create_copy(token, config, args)
        if args.command == "replace":
            return command_replace(token, config, args)
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
