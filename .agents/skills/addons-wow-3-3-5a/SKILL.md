---
name: addons-wow-3-3-5a
description: Build, port, review, debug, test, package, and document addons for the original World of Warcraft 3.3.5a client, build 12340, Interface 30300, using Lua 5.1. Use for WotLK legacy API compatibility, bag/item handling, FrameXML UI, SavedVariables, merchant/sell/repair/loot actions, or retail/Classic-to-original-client ports. Includes evidence and hard-won debugging lessons from Dejunk-WotLK. Do not apply original-client assumptions to Wrath Classic, Retail, or modified clients without verification.
---

# addons wow 3.3.5a

Produce working, reviewable original-client addon changes. Preserve the requested
behavior, research the actual API, and report observed evidence separately from
inference. This skill is portable; resolve all paths relative to this directory.

## Start here

1. Read the project's instructions and current state before changing it. Preserve
   existing work and SavedVariables. Check prior user authorization; do not ask
   repeatedly for actions already authorized.
2. Establish the target: **original 3.3.5a, build 12340, Interface 30300, Lua 5.1**.
   Wrath Classic is a separate target. For a modified client, record its build and
   capabilities rather than treating it as stock.
3. For a port, pin the reference addon commit and identify its defaults, screens,
   inputs, filters, ordering, commands, action flow, assets and licenses. A layout
   engine alone is not the original UI. User-requested deviations take precedence
   and must be documented.
4. Choose only the relevant references below. Do not load the entire research
   archive as a default. Do not copy Dejunk-specific policies into unrelated addons.
5. Identify a concrete failing path, implement the fix, exercise the same path,
   and continue independent authorized work until the requested deliverable is ready.
   Do not end with repeated promises to continue.

## Reference map

| Work | Read |
|---|---|
| Target, Lua and API differences | [api-compatibility.md](references/api-compatibility.md) |
| Frames, Escape, input, drops, layering, scrollbars | [ui-debugging.md](references/ui-debugging.md) |
| Inventory actions and delayed work | [transactions.md](references/transactions.md) |
| Evidence, mock fidelity, client tests, packaging, publication | [testing-and-release.md](references/testing-and-release.md) |
| Defaults, filters, unresolved parity and project lessons | [dejunk-case-study.md](references/dejunk-case-study.md) |
| Immutable sources and research caveats | [research-index.md](references/research-index.md) |

Historical research snapshots are preserved under `references/research-snapshot/`.
They contain proposals and older phase claims. The curated references above explain
what was actually observed, what changed, and which assumptions remain unverified.

## Engineering rules

- Put game API access behind a small compatibility boundary. Keep classification,
  storage, sorting and parsing pure where possible. Use a private addon namespace
  from `local addonName, Addon = ...`; introduce only required public globals.
- Normalize legacy tuples explicitly. A successful falsey return is not the same
  as an unavailable or throwing API. Preserve UNKNOWN when a value matters.
- Use Lua 5.1. Do not introduce modern `C_*`/`Enum` shims to hide compatibility
  gaps. Check a library's executed APIs as well as syntax and transitive dependencies.
- Never use a portable recipe as proof of client behavior. FrameXML is evidence
  of how the stock UI uses an API, not a full C API specification.
- Treat localized class/subclass labels and auction-list indices as uncertain
  crosswalks, not universally correct numeric item subclass IDs.
- Keep render state and frame visibility in agreement. Verify repeated opening,
  closing, page switching and reloading, not only first construction.
- For inventory actions, revalidate slot identity, full link, stack count, lock,
  settings, cursor and relevant context immediately before dispatch and again
  after confirmation. Do not clear an unrelated cursor to make an action possible.
- Use fake APIs to test mutations. Do not test real deletion. Honor any separately
  authorized, bounded live sale/repair/loot test; never infer permission to delete
  valuable inventory from a broad debugging request.
- Retain relevant license notices. Code MIT does not make separately credited
  artwork MIT. Do not ship Blizzard client files or personal game data.

## Practical workflow

1. Reproduce from the user's exact input: minimap versus slash command, first open
   versus reopen, click versus drop, focused edit box versus unfocused Escape,
   merchant open versus closed, fresh versus existing SavedVariables.
2. Inspect the implementation and pinned source, using `rg` and narrow reads.
   Record the root cause and meaningful unknowns; avoid a screenshot-only patch.
3. Change the smallest coherent set of code and metadata. For a UI bug, inspect
   mouse capture, frame size/level/strata, templates and state before changing art.
4. Run the project's relevant checks with **actual Lua 5.1**. Use realistic nil/1,
   native API shapes, delayed events and UI event sequences in mocks. Do not add
   shallow tests that only repeat implementation constants.
5. If a legacy behavior is uncertain, make a bounded read-only probe for the
   target client and state exactly what evidence it should collect.
6. Build a deterministic installable package with correct folder layout and all
   notices. Verify the artifact's metadata and hash, not just the source version.
7. Publish only within the user's authorized repository/scope. Check the final
   ref, CI, release assets and downloaded artifact/hash. A staged file, branch or
   successful local build is not a published release.
8. Report concrete changes, verification and remaining limits in the user's
   language. For this project's Persian-speaking owner, give concise Persian
   explanations and GitHub download links only, as requested in the session.

## Included tools

Run from any directory; no absolute workspace paths are required:

```sh
python3 scripts/audit_addon.py /path/to/Addon --toc Addon.toc --luac luac5.1
python3 scripts/package_addon.py /path/to/Addon /tmp/Addon.zip \
  --toc Addon.toc --include assets --include LICENSE --include THIRD_PARTY_NOTICES.md
```

The auditor checks the TOC/XML load graph, target metadata, safe paths and optional
Lua 5.1 syntax. Modern API matches are **review warnings**, not automatic proof of
incompatibility. It does not execute addon Lua or simulate WoW. The packager includes
only that load graph and explicit extra paths, refuses overwrites and personal game
folders, and verifies the resulting archive. Review artwork/license completeness
before distribution; a tool cannot determine ownership for you.

`templates/Addon335Template/` is a minimal **read-only** startup diagnostic addon.
Rename its folder/TOC and slash command before using it as a new project.

## Installation and reuse

The machine name is `addons-wow-3-3-5a`; its display name is **addons wow 3.3.5a**.
For Codex, place the complete directory in a supported `.agents/skills/` location
for the project or user, then refresh/restart skill discovery if required. Invoke
`$addons-wow-3-3-5a`. Check the target product's installation conventions rather
than claiming automatic registration. For other assistants, attach the bundle or
read this file plus the relevant references; `agents/openai.yaml` is optional UI
metadata, not a runtime dependency. See [README.fa.md](README.fa.md) for Persian usage.
