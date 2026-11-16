<div align="center">

# Dejunk-WotLK

**A cleaner inventory for original World of Warcraft 3.3.5a.**

[![Client](https://img.shields.io/badge/WoW-3.3.5a%20%2812340%29-4fafe3)](#compatibility)
[![Status](https://img.shields.io/badge/release-1.0.3-green)](#release-status)
[![Code license](https://img.shields.io/badge/code-MIT-green)](LICENSE)

[Download](https://github.com/brok5522/Dejunk-WotLK/releases) · [فارسی](README.fa.md) · [Report an issue](https://github.com/brok5522/Dejunk-WotLK/issues)

</div>

A compatibility port inspired by [Dejunk by moody](https://github.com/moody/Dejunk).
Classify bag items with shared or character-specific profiles, inspect the result,
and sell junk at a merchant through a familiar interface.

## Features

- **Four item lists:** global and profile Inclusions / Exclusions, with search,
  item drops, modifier-click transfers, and text import/export.
- **Profiles:** create, activate, rename, duplicate, reset and delete profiles.
- **Junk Items window:** item icons, quality colors, stack values and individual
  sell, exclude and destroy controls.
- **Merchant tools:** manual selling, optional Auto Sell / Auto Repair, and a
  movable icon-and-count merchant button.
- **Lootable Items window:** open supported bag items and ignore an item type
  for the current session.
- **Interface controls:** minimap icon, keybindings, explanatory bag tooltips,
  and small/large bag overlays, including [Bagnon 3.3.5](docs/BAGNON-COMPATIBILITY.md).
- **Action checks:** current slot identity, cursor and merchant checks, a
  twelve-attempt Safe Sell limit, and Safe Destroy confirmation by default.

## Compatibility

| Requirement | Supported target |
|---|---|
| Game client | Original WoW **3.3.5a** |
| Build | **12340** |
| Interface | **30300** |
| Lua | **5.1** |
| External addon dependencies | None; Waffle is bundled |

Retail and Wrath Classic are different clients and are not supported targets.
The `3.3.5` label in the window identifies the target client; the addon version
is listed in the AddOns menu and the release.

## Install

1. Download **`Dejunk-WotLK-1.0.3.zip`** from
   [Releases](https://github.com/brok5522/Dejunk-WotLK/releases).
2. Close WoW. If upgrading, back up your `WTF` SavedVariables and replace the
   old `Dejunk-WotLK` folder rather than mixing files from multiple versions.
3. Extract the ZIP into `World of Warcraft/Interface/AddOns/`.
4. Confirm this exact layout:

```text
Interface/
└── AddOns/
    └── Dejunk-WotLK/
        ├── Dejunk-WotLK.toc
        ├── src/
        ├── libs/
        └── assets/
```

5. Enable **Dejunk-WotLK** on the character-selection AddOns screen, then enter
   the game and type `/dejunk`.

Use the attached addon ZIP. GitHub's automatic **Source code** archives are for
contributors and have an extra repository directory.

## First use

New profiles include **Poor-quality items** by default. **Auto Sell**, **Auto
Repair** and **Safe Sell** start off; **Safe Destroy** starts on.

Open `/dejunk junk` to inspect candidates before selling. Add an item to an
Exclusions list to keep it. At a merchant, use the coins icon for a single stack
or **Start Selling** for a run. Enable automatic behavior only after checking
that your profile selects the intended items.

**Import/Export copies text, not files:** Export fills the field with comma-separated
item IDs and selects them. Press **Ctrl+C** to copy. Paste IDs and press Import
to add them to the selected list.

| Control | Action |
|---|---|
| Minimap left-click | Toggle the main window |
| Minimap right-click | Toggle Junk Items |
| Merchant left-click | Start selling |
| Merchant right-click | Toggle Junk Items |
| Alt + right-click on minimap/merchant button | Request Destroy Next |
| Shift + right-click on merchant button | Reset its position |
| Active profile / item counts in the footer | Open Profiles / toggle the corresponding window |

## Commands

| Command | Action |
|---|---|
| `/dejunk` | Toggle settings |
| `/dejunk profiles` | Toggle Profiles |
| `/dejunk junk` | Toggle Junk Items |
| `/dejunk loot` | Toggle Lootable Items |
| `/dejunk sell` | Start selling at a merchant |
| `/dejunk destroy` | Request one destroy action |
| `/dejunk help` | Show commands |
| `/djw status` · `/djw report` | Compatibility status / copyable diagnostics |

## Release status

**1.0.2 adds RichSteini Bagnon 3.3.5 support to the 1.0.1 audit fixes.** See the
[release notes](docs/RELEASE-1.0.2.md) and [detailed fix status](docs/FIXES-REVIEW-1.0.0.md).
Actual Lua 5.1 checks cover saved data, filters, action lifecycle, UI interactions
and reproducible packaging. The owner's previous client acceptance applies to
1.0.0; the changed paths need the [1.0.1 retest](docs/RELEASE-1.0.2.md).

Full upstream parity is not claimed. Comprehensive localization and integrations with other bag addons remain incomplete.
The tested Bagnon source contract is documented [here](docs/BAGNON-COMPATIBILITY.md). Canonical category mapping recognizes English
item labels; unknown localized labels are not guessed from auction positions.
Original-client visual and transaction acceptance is separate from offline tests.
See [the parity matrix](docs/PARITY.md) and [validation evidence](docs/VALIDATION.md).

## Troubleshooting

Enable Lua errors with `/console scriptErrors 1`, then `/reload`. When reporting
an issue, include your addon version, client build, the exact error, the action
that triggered it, `/djw report`, and a screenshot when layout is involved.
Never include account credentials or personal SavedVariables in public reports.

## Reusable development skill

The portable **addons wow 3.3.5a** skill captures this project's original-client
research, debugging lessons and reusable tools. It is separate from the game addon.
[Skill source](.agents/skills/addons-wow-3-3-5a/SKILL.md) ·
[Download skill 1.0.0](https://github.com/brok5522/Dejunk-WotLK/releases/tag/skill-addons-wow-3-3-5a-v1.0.0).

## Development

```sh
python3 tools/check_phase0.py
python3 tools/check.py --lua lua5.1 --luac luac5.1
python3 tools/package.py /tmp/Dejunk-WotLK.zip
```

The release workflow runs the checks, builds the installable ZIP and publishes
its SHA-256 checksum. Generated ZIPs belong in release assets, not the source tree.
Historical design notes remain in `docs/` for provenance.

## Credits and licenses

- Compatibility-port code: **MIT**, [LICENSE](LICENSE).
- Original design/reference: **moody / Dejunk**, pinned to
  [`04bafd5`](https://github.com/moody/Dejunk/tree/04bafd5e411441ef5b51bb8ed10d208f2d7758f5).
- Bundled **Waffle 0.12.2**: moody, MIT; its copyright notice is retained.
- **Cash / Dejunk logo:** [Lorc](https://game-icons.net/1x1/lorc/cash.html),
  [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/).
- **UI action icons:** [Font Awesome](https://fontawesome.com/),
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

See [third-party notices](THIRD_PARTY_NOTICES.md) and
[artwork attribution](assets/LICENSE.txt). The artwork is redistributed unchanged
from the pinned upstream snapshot. This is an independent port, not an official
Dejunk release or a Blizzard product; no endorsement is implied.
