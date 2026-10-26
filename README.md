# claude-output-styles

A small collection of Claude Code [output styles](https://code.claude.com/docs/en/output-styles) ("tones"), with a one-line installer.

## Styles

| File | Name | What it does | Sample reply |
|---|---|---|---|
| `output-styles/ste.md` | `ASD-STE100` | Simplified Technical English (informal approximation): short sentences, active voice, one idea each, no invented facts. | "Put the file in the folder. Then restart the tool." |
| `output-styles/israeli.md` | `Israeli` | Dugri Israeli senior engineer: blunt, warm, picks one option, Hebrew slang in chat replies (max 2). Takes initiative but asks before risky actions. Technical text stays standard English. | "Tachles: missing import in api.ts breaks the build. One-line fix. Apply it?" |

## Install

> **Installing never turns a tone on.** Claude Code keeps its default style until you pick one with `/output-style <name>` or `/config` → Output style.

### A. Script

```bash
git clone https://github.com/omriariav/claude-output-styles.git
cd claude-output-styles
./install.sh                 # all styles -> ~/.claude/output-styles/
./install.sh israeli         # only some
./install.sh --project       # -> ./.claude/output-styles/ (this project only)
./install.sh --link          # symlink instead of copy (follows git pull)
./install.sh --list          # show available styles
```

Or without cloning:

```bash
curl -fsSL https://raw.githubusercontent.com/omriariav/claude-output-styles/main/install.sh | bash -s -- israeli
```

> **Warning:** `--link --project` creates absolute symlinks into your clone. Do not commit them, because they break for teammates.

User scope respects `CLAUDE_CONFIG_DIR`. A differing existing file is replaced and the old one saved as `<name>.md.bak` (or `<name>.md.bak.<timestamp>` if that exists).

### B. Manual

```bash
mkdir -p ~/.claude/output-styles
cp output-styles/israeli.md ~/.claude/output-styles/
```

## Activate

Installing never activates a tone. Pick one:

- `/output-style Israeli` or `/config` and pick Output style.
- `/output-style` takes the style's **Name** (`Israeli`, `ASD-STE100`), not the file name (`ste`). It is case-insensitive.
- `/output-style` and `/config` save the choice for the current project only (`.claude/settings.local.json`). For a user-wide default, opt in explicitly with `"outputStyle": "Israeli"` in `~/.claude/settings.json`. This value is case-sensitive and must match the Name.
- Restart Claude Code only after you add or edit a style file. Switching between installed styles applies from the next message (Claude Code v2.1.251+).
- Both styles set `keep-coding-instructions: true`. Per the docs, that flag only takes effect on the full system prompt. If your setup uses the shorter prompt, set `CLAUDE_CODE_SIMPLE_SYSTEM_PROMPT=0`.

Switch back with `/output-style default`.

## Uninstall

```bash
./install.sh --uninstall            # all
./install.sh --uninstall israeli    # one (add --project for project scope)
```

Uninstall removes only unmodified files that this script installed.

## Add a new tone

1. Drop `output-styles/<name>.md` with frontmatter (`name`, `description`, optional `keep-coding-instructions`).
2. Add its basename to `STYLES_REMOTE` at the top of `install.sh` (used for the piped install).
3. Add a row to the table above.

## License

- **License:** MIT (see LICENSE). `output-styles/ste.md` is adapted from [JAICHANGPARK/ASD-STE100](https://github.com/JAICHANGPARK/ASD-STE100) (MIT). The upstream notice is in NOTICE. This is an informal approximation, not affiliated with ASD.
- **Inspiration:** the Israeli style is an original text, inspired by the ideas in [shmulc8's "Israeli output style" gist](https://gist.github.com/shmulc8/50d20025be23a3636a6b38331674a949), which itself builds on [chkp-roniz's Caveman output style](https://gist.github.com/chkp-roniz/79518f458cd9c8399e05a4bcb732c1c7). No text is copied from either.
