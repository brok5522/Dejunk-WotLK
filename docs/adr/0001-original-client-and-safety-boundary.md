# ADR 0001: Explicit legacy adapter and safety-first port

Status: proposed in Phase 0; implementation requires owner approval.

Context: modern Dejunk contains direct namespace APIs outside its partial facade,
new UI methods and mutable slot assumptions. Original 3.3.5a is not Wrath Classic.

Decision: build a dedicated legacy adapter, pure rule engine and store, native
legacy-frame UI, and a single revalidating transaction executor. No global API
shim and no wholesale copy of current dependencies. Prefer preserved behavior
with documented safety differences over pixel-identical modern UI. Native
minimap/configuration remove initial library risk; audited pinned libraries can
be adopted later through a separate decision.

Alternatives: changing only TOC fails at load; broad C_* emulation hides tuple and
semantic mismatches; directly copying current UI expands unverified surface;
modern Ace3 is not automatically old-client compatible either.

Consequences: more explicit porting work and conservative overprotection of
uncertain items. Isolated pure modules permit offline tests. Client probes remain
mandatory. Preserve source/license evidence if upstream code is adapted later.
