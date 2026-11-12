# Dependency and licensing decisions

Phase 0 vendors **nothing**. Versions below are observations of bundled files
at the pinned Dejunk revision, not approved dependencies of this port.

| Dependency | Observed version | Decision |
| --- | --- | --- |
| LibStub | minor 2 | Candidate; small legacy registry, public-domain notice in source; only needed if libraries adopted |
| CallbackHandler-1.0 | minor 8 | Current bundle uses securecallfunction; do not assume original-client compatibility. Audit a historical implementation and license before pinning |
| LibDataBroker-1.1 | minor 4 | Optional broker integration; requires LibStub and CallbackHandler; test callback dispatch and coexistence |
| LibDBIcon-1.0 | minor 52 | Do not vendor current file unchanged: numeric textures, project flags and modern compartment support. Prefer native legacy minimap button initially; audited historical library is an alternative |
| Waffle | 0.12.2 | Layout/composition abstraction; avoid bringing large UI surface into initial port; native legacy widgets with explicit layout |
| Wux | 0.4.0 | Reducer/store design reference; use a small independently written store with schema tests; adopting Wux later requires license and runtime audit |
| Ace3 / AceDB / AceConfig | not in this upstream bundle | Possible legacy alternatives, not chosen by default; current releases also need auditing. Do not claim Dejunk requires Ace3 |

Native minimap and configuration implementations preserve requested behavior
without library dependencies. If later selecting historical libraries, record
repository, immutable commit/tag, file checksums, license text, transitive graph,
5.1 syntax result, missing-global results and original-client test evidence in
this document before adding their files. Test with another addon loading a newer
minor of the same library: LibStub's version selection can change execution.

Upstream Dejunk is MIT, copyright (c) 2017–2026 moody. If substantial code is
adapted, include that full MIT license and attribution in distributed code.
The original README separately credits Cash (CC BY 3.0) and FontAwesome (CC BY
4.0); MIT alone does not cover all art. Prefer built-in texture paths initially.
No copied artwork, Blizzard FrameXML, upstream libraries or runtime code is
included in this Phase 0 repository. A license for newly implemented port code
must be selected and documented before distribution; Phase 0 does not silently
relicense upstream materials.

## Phase 1 update
The read-only foundation is independently written, has no library dependencies,
and uses legacy native frames. Its code is under the root MIT LICENSE (copyright
2026 Dejunk-WotLK contributors). No upstream runtime or art was copied. The future
vendor/notice policy above still applies if external code is introduced.
