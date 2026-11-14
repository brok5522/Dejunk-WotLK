# src/services

Phases 4 and 5 contain simulation-only seller, repair and destruction state
machines. They accept only adapters explicitly marked `simulation=true`; the
WoW runtime never constructs them. No inventory-mutating API or production
adapter exists.
