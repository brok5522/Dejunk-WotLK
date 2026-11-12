# Phase 1 implementation contracts

Authorized by the owner after the Phase 0 review. Offline implementation is
ready; original 12340 client evidence is pending. No Phase 2 work is included.

## Runtime and initialization
The TOC loads nine files in explicit order. `namespace.lua` uses the loader's
private addon table, no public addon object. The compatibility module checks
GetBuildInfo before creating a lifecycle frame or constructing the bag adapter.
Version 3.3.5/3.3.5a, build 12340 and Interface 30300 must all match. Missing
mandatory read APIs or critical event registrations disable initialization;
status/help/report remain available. There are no libraries, C_* shims, hooks on
visible item tooltips, configuration state or SavedVariables.

Startup requires both this addon's ADDON_LOADED and PLAYER_LOGIN; unrelated
addons cannot activate reads. The first scan runs on a deferred update. Logout
cancels work, invalidates the cache and unregisters lifecycle events. Merchant
and UI-error events are observed only. The compatibility layer forwards the
legacy UI_ERROR_MESSAGE first argument unchanged to internal subscribers and
records only its type in diagnostics.

## Scheduler, bus and snapshots
The scheduler is driven by a compat-owned OnUpdate script only while work is
pending; it is removed when idle. Tasks have cancellable tokens, execute once
in scheduling order when due, and tasks created inside callbacks wait for the
next update. Callback errors are isolated and counted. The event bus supports
unsubscribe during dispatch; newly added listeners wait for the next emission.

Cache scope is bags 0..4. Each event invalidates the current generation
immediately and schedules one scan after 0.1 seconds; 200 events before the
update still cause one scan. A generation change during scanning prevents the
result from being marked current. Unknown bag occupancy or uncached metadata
triggers at most two additional scans 0.5 seconds apart. Lock changes trigger
refresh via events; missing safety data does not cause infinite polling.

`GetSnapshot()` and update notifications return deep copies. These are owned
by the recipient; callers cannot mutate the internal cache. Lua 5.1 tables are
not frozen: consumers should not mutate shared event payloads. `valid` indicates
generation coherence, **not** that all metadata or safety fields are known.
`unknown` counts unresolved bag-size/occupancy/metadata entries, not every unknown
safety field. Internal events are implementation details, not the public API
planned for Phase 6.

## Legacy adapter semantics
Slot state is EMPTY, OCCUPIED or UNKNOWN. ID comes from a hyperlink, count and
lock from tuple returns, and optional GetContainerItemID is cross-checked.
Conflicting evidence, modern table returns, API errors and partial slots remain
unknown. Empty texture with nonempty ID evidence cannot classify a slot empty.
GetItemInfo metadata is accepted only when its full returned link matches the
slot and quality/base item-level are valid. Missing price stays absent; zero
is a known zero. Class/subclass are localized labels, not numeric class IDs.

Safety properties use booleans or the literal `unknown`. Nil C-API flags are
unknown; only explicit booleans/0/1 are normalized. Refund seconds use the fifth
purchase return; nil is deliberately not interpreted as non-refundable. A known
empty equipment-set collection yields false membership; failed/partial set
reads yield unknown for every item. All carried copies of a set ID are marked
members. Automatic snapshots leave binding unknown; an explicit slot probe
scans a hidden tooltip for localized soulbound/account/BOE/BOU lines and
re-reads the slot afterwards. Unrecognized text remains unknown. No claim of
complete heirloom, quest or binding classification is made before client probes.

The 128-slot and 100-set caps are defensive limits for malformed API output,
not claims about standard-client capacities. The original-client APIs and native
widget methods must still be verified against the actual build.

## Diagnostic commands and packaging
`/djw` and `/dejunkwotlk` accept status, probe, report, slot and help. No action
commands exist. Report includes build/capabilities, registered events, cache
counts, the last explicit slot probe and last 32 event payload shapes. It omits
character/account names, equipment-set names, item hyperlinks, raw tooltip lines
and UI-error text. Class/subclass labels and the selected item ID/count/value
are included. It is in memory only and can be copied using the legacy report
panel, with chat fallback if the panel fails.

`tools/check.py` runs the target/load-order, static read-only boundary, actual
Lua 5.1 compilation and legacy fixture suite. `tools/package.py` produces only
the TOC, runtime files, MIT license and a standalone diagnostic README inside
one Dejunk-WotLK folder. ZIP names/timestamps/permissions are deterministic; the
script refuses overwrite. Nothing is installed, pushed or published by packaging.

## Phase 2 transition
The owner authorized Phase 2. Work is underway on `phase-2/store-profiles-lists`; see [PHASE2.md](PHASE2.md). Rules, UI and inventory operations remain outside this phase.
