# Bagnon 3.3.5 integration

Supported source: [RichSteini/Bagnon-3.3.5](https://github.com/RichSteini/Bagnon-3.3.5),
pinned for this review to `27a08f89819311d772e7ec7a71a41eafb813f122`.
The integration is in Dejunk-WotLK 1.0.2; Bagnon itself is not modified or bundled.
No Bagnon source code or assets are redistributed.

## Source contract

- [`Bagnon/main.lua`](https://github.com/RichSteini/Bagnon-3.3.5/blob/27a08f89819311d772e7ec7a71a41eafb813f122/Bagnon/main.lua),
  lines 6, 25, 93–102: global addon object and existing window registry.
- [`components/item.lua`](https://github.com/RichSteini/Bagnon-3.3.5/blob/27a08f89819311d772e7ec7a71a41eafb813f122/Bagnon/components/item.lua),
  constructor/Create/Free/Update/GetBag/IsCached/GetItem: pooled item widgets,
  optional reuse of Blizzard buttons, live slot identity and cached-player status.
- [`utility/classy.lua`](https://github.com/RichSteini/Bagnon-3.3.5/blob/27a08f89819311d772e7ec7a71a41eafb813f122/Bagnon/utility/classy.lua):
  instances inherit methods from ItemSlot, so class post-hooks reach new/reused widgets.
- [`components/itemFrame.lua`](https://github.com/RichSteini/Bagnon-3.3.5/blob/27a08f89819311d772e7ec7a71a41eafb813f122/Bagnon/components/itemFrame.lua),
  lines 244–279: existing `itemSlots` registry and slot allocation/release.
- [`utility/bagSlotInfo.lua`](https://github.com/RichSteini/Bagnon-3.3.5/blob/27a08f89819311d772e7ec7a71a41eafb813f122/Bagnon/utility/bagSlotInfo.lua),
  `IsCached`: distinguishes other characters and unavailable bank snapshots.

## Behavior

Dejunk securely post-hooks ItemSlot Update and Free without replacing click,
drag/drop, tooltip or search scripts. Existing widgets are discovered from Bagnon's
window registry. ADDON_LOADED and PLAYER_LOGIN retry discovery, supporting either
load order. Hooks are installed once per class; weak-key registries track widgets.

Only visible, non-cached slots in carried bags 0–4 are eligible. The displayed link
must match the live slot link and the slot must be within the current bag size.
Bank, keyring, saved other-character inventories, stale links and unknown data are
not annotated. Reused Blizzard button names are not mistaken for original bag
positions. No inventory mutation is performed by the integration.

The existing Item Icons preference and SMALL/LARGE styles apply. Icons clear on
Free, invalid identity, KEEP decisions or disabled settings. List/profile/rule
changes redraw bag overlays immediately; completed bag-cache updates refresh them.
The existing live SetBagItem tooltip integration remains in use. Cached tooltips
are not given the current character's Dejunk decisions.

## Verification

Actual Lua 5.1 tests exercise pre-existing and newly allocated widgets, recycled
Blizzard widgets, delayed addon loading, hook uniqueness, original Update/Free
execution, untouched drag scripts, cached characters, bank slots, stale links,
small/large/off preferences and rule-driven clearing. All existing regressions
and deterministic package checks pass. Native-client visuals are not tested here.

## تست داخل بازی

1. همین نسخهٔ Bagnon و Dejunk-WotLK 1.0.2 را فعال و `/reload` کنید.
2. در Global Options گزینهٔ Item Icons را روشن کنید؛ یک آیتم بی‌ارزش را در
   Inclusions بگذارید و آیکن را در کیف باز Bagnon بررسی کنید.
3. حالت کوچک/بزرگ و سپس خاموش را امتحان کنید. انتقال آیتم به خانه/کیف دیگر و
   حذف آن از فهرست باید آیکن را به‌روز کند.
4. کیف را ببندید/باز کنید؛ جست‌وجو، مرتب‌سازی، درگ‌انددراپ و tooltip را تست کنید.
5. نمای شخصیت دیگر و بانک نباید آیکن مربوط به کیف شخصیت فعلی را نشان بدهند.
6. Bagnon را غیرفعال و reload کنید؛ آیکن‌های کیف استاندارد باید همچنان کار کنند.

این پشتیبانی مخصوص مخزن بالا است و به معنی سازگاری تمام نسخه‌های Bagnon یا
تمام افزونه‌های کیف نیست. در صورت خطا، متن Lua و نسخهٔ هر دو افزونه را گزارش کنید.
