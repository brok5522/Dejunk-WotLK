# Compatibility-port roadmap

The acceptance target is upstream Dejunk 3.5.1 at commit
`04bafd5e411441ef5b51bb8ed10d208f2d7758f5`, adapted to original WoW 3.3.5a,
build 12340, Interface 30300 and Lua 5.1. The target is upstream behavior and UI
parity, with legacy API substitutions only. New settings, generalized rule
languages, alternate screen flows and other redesigns are out of scope.

The current branch is **not release-ready**. It has a read-only compatibility
foundation, storage/evaluation scaffolding and user-observed previews. Some
port-built UI and configuration options do not match upstream and must be
replaced or removed. The Waffle engine alone does not constitute the original
UI port. Live transaction calls remain behind the review/authorization gate in
`AGENTS.md`.

| Phase | Deliverables | Acceptance / exit gate |
| --- | --- | --- |
| 0 — Reference | Pin upstream source, FrameXML/API evidence and licenses | Immutable source links and checksums |
| 1 — Legacy compatibility | Original API tuples, build guard, events, scheduler and item data | Tests against build 12340 FrameXML behavior; UNKNOWN for unproven data |
| 2 — Upstream behavior model | Match upstream store, profiles, options, lists, defaults and filter precedence | Fixtures match upstream cases; saved settings migrate without loss |
| 3 — Item presentation | Original tooltips, bag icons, item categories and list interactions | Original 3.3.5a UI evidence for each adapted API |
| 4 — Seller and repair | Port upstream manual/automatic selling, Safe Sell, merchant button, messages, cancellation and repair | Mock parity tests; separate review and authorization before live-action testing |
| 5 — Destroy and loot | Port upstream one-item destroy, confirmation, junk frame and lootable frame | Mock parity tests and 3.3.5a UI review; no unintended cursor or item use |
| 6 — Original UI and input | Adapt upstream main window, profile/global options, lists, profiles, keybindings, minimap and merchant controls | Upstream screens/interactions preserved; client screenshots and command checks |
| 7 — Release candidate | Regression, saved-variable recovery, package, licenses and install guide | Original-client parity evidence and owner approval before public release |

## Upstream behavior checklist

- Defaults: Poor quality included; Auto Sell and Auto Repair off; Safe Sell off;
  Safe Destroy on; original global/profile options and action scopes preserved.
- Filters: upstream order and SELL/DESTROY/BOTH applicability preserved;
  stack price uses the full stack and zero-price items are not sellable.
- Lists: the four global/profile include/exclude lists, name search, item-drop
  behavior, and original plain-text import/export flow.
- Screens: original main window, profile/global options, profiles, lists,
  keybindings, junk items, lootable items, and transport/import-export frames.
- Actions: upstream manual/automatic seller, one-item destroy confirmation,
  merchant controls, repair behavior, loot opening, tooltips and bag icons;
  calls must use 3.3.5a globals and keep upstream default opt-ins.
- Commands and bindings: retain upstream command names and behavior. Do not add
  the port-only `/djw rules add` ALL/ANY rule language to the release UI.
- Retail-only systems (artifact relics, warband bank, addon compartment) are
  omitted because original 3.3.5a has no equivalent.

The port must not add protective settings or alter ordinary classification
precedence as a substitute for upstream behavior. If an API difference prevents
parity, document the exact case and implement the closest behavior supported by
the legacy client. Keep uncertainty safe only where the API truly cannot prove
the upstream input; do not turn that into a new user-facing feature.
