# Rocky Hindsight Production And Backup SOP

Date: 2026-09-04 | Agent: Cody | Status: Implemented

## Approved Architecture

- Rocky, Hindsight, and the memory database remain on VPS4.
- The database runs in its own Docker container with permanent storage on VPS4.
- Hindsight runs in a second Docker container and is reachable only from VPS4.
- Rocky's OpenClaw plugin connects to `http://127.0.0.1:9077`.
- The retired embedded database and daemon files were removed after the clean replacement passed its restore test. Hostinger's independent VPS backup remains the only route to that discarded history.

## Safety Controls

- Confirmed writes, full-page protection, and database checksums are enabled.
- Docker and both containers restart automatically after a VPS restart.
- A health check verifies the database, the Hindsight API, and the safe-write settings every five minutes.
- A database export runs every six hours at low CPU and disk priority.
- Every export is validated, checksummed, encrypted, and retained locally for seven days.
- Google Drive upload begins only after the approved Google Desktop OAuth client is installed, `jack@zbiz.work` completes Google consent, and the approved destination folder ID is installed.
- Hostinger's weekly whole-VPS backup remains a separate final recovery layer.

## Backup Locations

- Local encrypted exports: `/opt/backups/hindsight/rocky/`
- Encryption key: `/etc/rocky-hindsight/backup-age.key` with a protected operator recovery copy outside VPS4.
- Google Drive: `ZedBiz Technical Backups/VPS4/Rocky/Hindsight/` after OAuth completion.

## Required Checks

- `systemctl status rocky-hindsight.service`
- `systemctl status rocky-hindsight-backup.timer`
- `systemctl status rocky-hindsight-health.timer`
- `/usr/local/sbin/rocky-hindsight-health`
- `journalctl -u rocky-hindsight-backup.service`

## Recovery Rule

- Never copy live database files as the normal backup method.
- Restore an encrypted export into a temporary database first.
- Prove a real Rocky memory can be read before replacing the working database.
- Stop and investigate if a backup, health check, or restore test fails.

## Verified Production Result

- Hindsight API `0.9.1`, Hindsight OpenClaw plugin `0.11.1`, and PostgreSQL `18.6` are active.
- Rocky's baseline load completed with 759 documents and zero failed loads: one `MEMORY.md` plus 758 shared-wiki Markdown pages.
- Direct Hindsight recall passed before and after a full Hindsight service restart in under one second during the final run.
- The encrypted backup restored into a separate temporary database with all 760 documents and 6,075 memory units present at backup time; the exact test memory was readable in the restored copy.
- Rocky's normal OpenClaw agent route recalled both the synthetic restart marker and the final-authority rule without tools or file reads.
- The synthetic test documents were removed from the live database after verification.
- Google Drive is not yet connected because VPS4 has no approved Google Desktop OAuth client credential or saved Google authorization.
