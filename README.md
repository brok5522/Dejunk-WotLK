# Dejunk-WotLK

Planned recreation of [Dejunk](https://github.com/moody/Dejunk) for the original
World of Warcraft **3.3.5a / build 12340 / Interface 30300 / Lua 5.1**.

**Status: Phase 0 complete; implementation awaits owner approval.**
This repository contains research, design and development scaffolding. There is
no installable addon, TOC, runtime Lua, inventory action or vendored library yet.
Do not copy this checkout into AddOns expecting a working addon.

## Documentation
- [Persian report](docs/PHASE0.fa.md)
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

## Local checks
```sh
python3 tools/check_phase0.py
git diff --check
```
Python 3 is the only Phase 0 check dependency. No game or account is needed.
Future runtime packaging will create a `Dejunk-WotLK/` addon folder with an
Interface 30300 TOC and an explicit audited load order.

## Attribution
Upstream Dejunk 3.5.1 was examined at commit
`04bafd5e411441ef5b51bb8ed10d208f2d7758f5`, under MIT (copyright 2017–2026 moody).
No upstream runtime code or artwork is distributed here. Preserve upstream MIT
notices if code is adapted later; separately review artwork and library licenses.
See [dependency policy](docs/research/DEPENDENCIES.md).
