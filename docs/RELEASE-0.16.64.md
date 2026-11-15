# 0.16.64-beta.1 — Localized openable detection

Extends 0.16.63's native loot-flag and seven-clam coverage with an exact localized
`ITEM_OPENABLE` tooltip fallback. Color codes and surrounding whitespace are
normalized; generic Use text and partial matches are excluded. Slot link/count
are re-read after tooltip hooks, and the latest lock state is retained.
The same adapter is used for cache presentation and click-time revalidation.

Actual Lua 5.1 suites and deterministic packaging pass. New fake-API fixtures
cover localized/color-formatted markers and exclusion of ordinary Use text.
No live inventory operation was performed. Custom spell-only items lacking both
native loot flag and standard open instruction still need explicit evidence.

## تست

نسخه قبلی را کامل جایگزین کنید. صدف‌ها و جعبه/هدیه‌های قابل‌بازشدن را در
`/dejunk loot` بررسی کنید؛ متن استاندارد بازکردن در Tooltip هم برای تشخیص
پشتیبانی می‌شود. خوراکی، معجون و دستور ساخت نباید وارد این فهرست شوند.
آیتم‌های اختصاصی سرور با متن غیراستاندارد هنوز نیاز به بررسی جداگانه دارند.
