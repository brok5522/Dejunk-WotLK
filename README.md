# Dejunk-WotLK

Planned recreation of [Dejunk](https://github.com/moody/Dejunk) for the original
World of Warcraft **3.3.5a / build 12340 / Interface 30300 / Lua 5.1**.

**Status: Phase 1 implemented; owner-reported basic client smoke checks passed; broader acceptance partial.**
Phase 1 read-only diagnostics were exercised by the owner. Phase 2 adds persistent profiles and lists. No selling, deletion, repair or item use is implemented. Phase 2 validation is pending.

See [installation and read-only verification in Persian](docs/PHASE1.fa.md).

## Documentation
- [Phase 2 design](docs/PHASE2.md) and [Phase 1 client evidence](docs/CLIENT-ACCEPTANCE.md)
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

Commands: `/djw status`, `/djw probe` (chat), `/djw report` (copy panel),
`/djw slot <bag 0..4> <slot>` (explicit slot probe), `/djw help`.
`/dejunkwotlk` is an alias. The original addon's `/dejunk` is not intercepted.

## Attribution
Upstream Dejunk 3.5.1 was examined at commit
`04bafd5e411441ef5b51bb8ed10d208f2d7758f5`, under MIT (copyright 2017–2026 moody).
The independently written port code is licensed under [MIT](LICENSE).
No upstream runtime code or artwork is distributed here. Preserve upstream MIT
notices if code is adapted later; separately review artwork and library licenses.
See [dependency policy](docs/research/DEPENDENCIES.md).
