# claude-telegram-bridge

Talk to a PC's Claude Code session from a phone over Telegram, so the team can keep working away from the desk. Public repo, shared with teammates.

## Layout

| Path | Purpose |
|---|---|
| `install.ps1` / `install.bat` | One-shot setup per PC. Idempotent: re-running skips what is done and rewrites the launcher. |
| `prompts/remote-role.md` | Role and rules appended to the launcher session (`--append-system-prompt-file`). |
| `docs/` | HTML manual with screenshots (`docs/img/`). |

## How it works

- Official plugin `telegram@claude-plugins-official` + Bun. Works with the company gateway auth (verified 2026-09-27).
- One bot token allows one polling session. The plugin is disabled at user scope and enabled only in the launcher via `--settings ~/.claude/telegram-session.json`.
- Every user makes their own bot. Tokens live in `~/.claude/channels/telegram/.env`, never in this repo.

## Rules

- Public repo: no tokens, chat IDs, internal hostnames, or company file paths. Blur them in screenshots.
- `.bat` files are ASCII English only (Windows cmd encoding).
- Test `install.ps1` on a PC where setup is already done (must be a no-op apart from the launcher) before committing changes to it.

## Roadmap

1. Manual (HTML + screenshots)
2. Tune `remote-role.md` after a few days of real use
3. Skills for remote PC control
