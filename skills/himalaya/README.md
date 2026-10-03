# Rocky Himalaya compatibility override

Owner: ZedBiz. Operational scope: Rocky on VPS4 only.

This repository-owned command guide targets the official pimalaya/himalaya v2.2.1 binary. It is written from the installed CLI help and pinned upstream migration/configuration documentation. It does not embed upstream implementation code or credentials.

The runtime identifier deliberately remains `himalaya` so OpenClaw workspace precedence replaces the bundled v1 command guide. This is a platform compatibility mapping for Rocky, not a new public skill publication. Deploy only SKILL.md; keep this README outside the runtime package.

Verification: native OpenClaw quick_validate.py and Z AI validate_skill.py passed; protected-runtime IMAP/SMTP authentication, mailbox listing, envelope listing, message reading and unsent draft composition passed. The SMTP check is not delivery verification. No mail was sent or deleted.

Source documentation:
- https://github.com/pimalaya/himalaya/blob/v2.2.1/MIGRATION.md
- https://github.com/pimalaya/himalaya/blob/v2.2.1/config.sample.toml

Recovery: restore the saved Himalaya 1.2.0 binary and v1 configuration together, then remove only this workspace override. The original bundled skill remains installed.
