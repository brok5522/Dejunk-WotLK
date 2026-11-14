# Research provenance and how to extend it

## Immutable source snapshots

### Reference addon

[moody/Dejunk at 04bafd5](https://github.com/moody/Dejunk/tree/04bafd5e411441ef5b51bb8ed10d208f2d7758f5)

Inspect these modules for the actual behavior, rather than inferring it from a screenshot:

- `src/items/items.lua`: equipment/lock/refund/sellability behavior.
- `src/junk-filter/junk-filter.lua`, `item-filters.lua`, `junk-items-cache.lua`:
  filter order, reasons, combined display versus action-specific selection and sorting.
- `src/store/default-states.lua`, `migrations.lua`: defaults and profile storage.
- `src/services/seller.lua`, `destroyer.lua`, `confirmer.lua`: action lifecycle.
- `src/ui/screens/main-window/main-window.lua:356`: footer segments;
  `:470`: target-page toggle behavior.
- `src/ui/screens/main-window/options/`: global/profile options and profile CRUD.
- `src/ui/screens/junk-frame.lua`, `lootable-frame.lua`, `merchant-button.lua`,
  `transport-frame.lua`: controls and dimensions.
- `src/ui/components/`, `src/ui/item-tooltip.lua`, `item-icons.lua`, `minimap-icon.lua`:
  visuals, interactions and independent widget behavior.
- `src/input/commands.lua`, `keybindings.lua`: command and keybinding semantics.
- `README.md`, `LICENSE`: user behavior and separate artwork credit.

### Original-client FrameXML mirror

[3.3.5-interface-files at d0339b1](https://github.com/wowgaming/3.3.5-interface-files/tree/d0339b17b0221db76e6acd2dc2915d224a5b62ca)

This is a **community source mirror**, not a live trace or blanket redistribution license.
Useful anchors from the project research:

| File | Evidence to inspect |
|---|---|
| `ContainerFrame.lua:282,292` | Quest marker falsey tuple handling |
| `ContainerFrame.lua:632-633` | Fifth purchase-info return is refund seconds |
| `ContainerFrame.lua:700,747,774` | Container actions, nil lock semantics, tooltip use |
| `EquipmentManager.lua:97,284` | Original pickup and lock-field use |
| `MailFrame.lua:91` | Legacy item-info fields |
| `PaperDollFrame.lua:1120,2224` | Equipment-set UI calls |
| `UIErrorsFrame.lua:14` | Original UI_ERROR_MESSAGE argument shape |
| `Blizzard_AuctionUI/Blizzard_AuctionUI.lua:380,621` | Localized class/subclass lists; not proof of numeric-ID equivalence |
| `MerchantFrame.xml` | 384×512 parent, name/portrait and item-row anchors |
| `InterfaceOptionsFrame.lua`, `Blizzard_BindingUI.lua` | Native options/binding patterns |

Line references belong to this immutable snapshot; do not apply them blindly to
other revisions. The snapshot manifest records hashes for the inspected subset,
not every file in either repository.

## Included research archive

`research-snapshot/` contains the original project's COMPATIBILITY.md.txt, SOURCES.md.txt,
UPSTREAM.md.txt, DEPENDENCIES.md.txt, api-symbols.csv and source-manifest.json. It preserves
research reasoning, proposals and source URLs. They are preserved as text snapshots, not active documentation pages. Some local links in these historical
files refer to the original repository's docs layout; use the immutable links or
the curated index above when reading them outside that repository.

No raw Blizzard code, client binaries, session secrets, private account records,
chat transcript or claim of exhaustive web-search history is included. This skill
captures the retrievable evidence and conclusions available from the project.

## Adding new findings

Record target build, function/return/event shape, exact source commit/file/line,
classification (source observation / inference / fake test / client observation),
reproducer, resulting patch and limits. Add a focused regression fixture where it
protects behavior. For a different addon, pin its own reference and licenses; do
not relabel this Dejunk research as an audit of that addon.
