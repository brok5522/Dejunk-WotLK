# Dejunk-WotLK

Compatibility port of [Dejunk](https://github.com/moody/Dejunk) for the original
World of Warcraft **3.3.5a / build 12340 / Interface 30300 / Lua 5.1**.

**Goal: preserve the pinned upstream Dejunk behavior on WoW 3.3.5a.** This is a compatibility port, not a redesign or feature expansion. The pinned upstream Waffle layout engine is loaded, but the original screens and core actions are not yet fully ported.
The upstream Poor-quality junk default is enabled automatically for new profiles; the rule editor is for additional custom conditions, not required setup.
Earlier screenshots verified port-built configuration screens and read-only previews. They do not establish parity with the original Dejunk UI or actions. Seller, repair and destruction are not connected to live game actions yet.

See the [Persian project guide](docs/PHASE1.fa.md). Older phase guides describe
development scaffolding, not a parity-complete release. The port is not yet
ready for normal use.

## Documentation
- [Phase 2 Persian install and test guide](docs/PHASE2.fa.md)
- [Phase 3 Persian install and preview guide](docs/PHASE3.fa.md)
- [Phase 4 Persian simulation-only guide](docs/PHASE4.fa.md)
- [Phase 5 Persian simulation-only guide](docs/PHASE5.fa.md)
- [Current development status in Persian](docs/USAGE.fa.md)
- [Historical Phase 6 UI notes](docs/PHASE6.fa.md)
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

These commands document the current development scaffold and are not a claim
of parity with upstream Dejunk's commands or screens. The final port must use
the upstream interface and behavior. Saved settings live in the account-level
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

Development-only commands include `/djw rules` and `/djw preview sell|destroy`;
the generalized ALL/ANY rule editor is out of scope for the upstream port.
Existing diagnostics include `/djw status`, `/djw probe` (chat), `/djw report` (copy panel),
`/djw slot <bag 0..4> <slot>` (explicit slot probe), `/djw help`.
`/dejunkwotlk` is an alias. The original addon's `/dejunk` is not intercepted.

## Attribution
Upstream Dejunk 3.5.1 was examined at commit
`04bafd5e411441ef5b51bb8ed10d208f2d7758f5`, under MIT (copyright 2017–2026 moody).
The independently written port code is licensed under [MIT](LICENSE).
No upstream runtime code or artwork is distributed here. Preserve upstream MIT
notices if code is adapted later; separately review artwork and library licenses.
See [dependency policy](docs/research/DEPENDENCIES.md).
