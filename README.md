# Dejunk-WotLK

Planned recreation of [Dejunk](https://github.com/moody/Dejunk) for the original
World of Warcraft **3.3.5a / build 12340 / Interface 30300 / Lua 5.1**.

**Status: Phase 6 configuration UI in progress; profile lifecycle, rules, thresholds, searchable lists and reviewed bulk import/export are implemented.**
The upstream Poor-quality junk default is enabled automatically for new profiles; the rule editor is for additional custom conditions, not required setup.
The owner has verified the configuration, profile selection, four-pane list view, row selection, item name/icon rendering, rule preview and Options windows in the target client. `/djw config` provides settings, quality controls, read-only previews, profile controls (create, duplicate, rename, reset and delete), the four-pane list browser, a basic custom-rule editor, and level/price thresholds. Seller, repair and destruction remain simulation-only and no game transaction can be triggered.

See [installation and read-only verification in Persian](docs/PHASE1.fa.md).

## Documentation
- [Phase 2 Persian install and test guide](docs/PHASE2.fa.md)
- [Phase 3 Persian install and preview guide](docs/PHASE3.fa.md)
- [Phase 4 Persian simulation-only guide](docs/PHASE4.fa.md)
- [Phase 5 Persian simulation-only guide](docs/PHASE5.fa.md)
- [Phase 6 Persian configuration guide](docs/PHASE6.fa.md)
- [Phase 2 design and validation](docs/PHASE2.md)
- [Phase 1 implementation contracts](docs/PHASE1.md)
- [Historical Phase 0 Persian report](docs/PHASE0.fa.md)
- [Upstream analysis](docs/research/UPSTREAM.md)
- [API compatibility and alternatives](docs/research/COMPATIBILITY.md)
- [Dependency decisions](docs/research/DEPENDENCIES.md)
- [Evidence and immutable sources](docs/research/SOURCES.md)
- [Architecture and data contracts](docs/ARCHITECTURE.md)
- [Safety policy](docs/SAFETY.md)
- [Feature parity and roadmap](docs/ROADMAP.md)
- [Testing strategy](docs/TESTING.md) and [actual validation](docs/VALIDATION.md)
- [GitHub review and merge guide](docs/REVIEW.fa.md)
- [Permanent agent instructions](AGENTS.md)

## Phase 2 commands

- `/djw profiles list`, `create <name>`, `switch <id>`; in `/djw config`, open Profiles to create or activate a profile.
- `/djw profile list`, `create <name>`, `switch <id>`, `rename <id> <name>`, `reset <id>`, `delete <id>`
- `/djw lists show <global|profile> <inclusions|exclusions>`
- `/djw lists add|remove <global|profile> <inclusions|exclusions> <itemID>`
- `/djw lists import <global|profile> <inclusions|exclusions> <IDs>`

These commands only edit settings and item-ID lists in Phase 2. Phase 3 adds a
read-only rule evaluator and preview. Phase 4 adds mock-only transaction code,
still not connected to a game action. Saved settings live in the account-level
`DejunkWotLKDB` variable; back it up with the game's WTF account folder before
manual edits or addon removal.

## Local checks and packaging
```sh
python3 tools/check.py
python3 tools/package.py work/Dejunk-WotLK-phase1.zip
git diff --check
```
Use Python 3.9+ and **lua5.1 / luac5.1**. If binaries are elsewhere, pass
`--lua /path/to/lua5.1 --luac /path/to/luac5.1` to `tools/check.py`.
The check verifies TOC/load order, the read-only source boundary, Lua 5.1 syntax,
research/docs and the behavioral suite. `tools/check_phase0.py` retains research
checks; its historical no-runtime gate was replaced after Phase 1 approval.
The package command refuses to overwrite existing files, creates a deterministic
single-folder ZIP and never installs or publishes it.

Phase 3 commands include `/djw rules` and `/djw preview sell|destroy`. Preview
never triggers an action. Existing commands: `/djw status`, `/djw probe` (chat), `/djw report` (copy panel),
`/djw slot <bag 0..4> <slot>` (explicit slot probe), `/djw help`.
`/dejunkwotlk` is an alias. The original addon's `/dejunk` is not intercepted.

## Attribution
Upstream Dejunk 3.5.1 was examined at commit
`04bafd5e411441ef5b51bb8ed10d208f2d7758f5`, under MIT (copyright 2017–2026 moody).
The independently written port code is licensed under [MIT](LICENSE).
No upstream runtime code or artwork is distributed here. Preserve upstream MIT
notices if code is adapted later; separately review artwork and library licenses.
See [dependency policy](docs/research/DEPENDENCIES.md).
