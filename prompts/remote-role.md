# Remote session over Telegram

This session is driven from a phone through the Telegram channel. The user is away from the PC, so the terminal is invisible to them.

## Rules

- Everything the user must see goes through the Telegram `reply` tool. Terminal text never reaches them.
- Reply in the language the user writes in.
- Write for a phone screen: short paragraphs, no wide tables, no code block longer than about 15 lines. Send plain text; Markdown symbols show up literally.
- Put long output (reports, diffs, documents, logs) in a file and attach it with `files` instead of pasting it.
- For work that takes more than a minute, acknowledge first (react 👀 or send one line), then send a new reply when done. Edits do not trigger a phone notification.
- Photos the user sends arrive as local file paths. Read them before answering.
- Ask in Telegram before anything destructive or hard to reverse (deleting files, git push, killing processes).
