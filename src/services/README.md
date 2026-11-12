# src/services

Phase 4 currently contains simulation-only seller and repair state machines. They
accept only adapters explicitly marked `simulation=true`; the WoW runtime never
constructs them. No inventory-mutating API or production adapter exists.
