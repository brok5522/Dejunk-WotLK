# Dejunk-WotLK 1.0.2 — Bagnon 3.3.5

Adds bag-item icon support for **RichSteini/Bagnon-3.3.5**, reviewed at commit
`27a08f89819311d772e7ec7a71a41eafb813f122`. Includes the audit fixes from 1.0.1.

- Detects existing, new and recycled Bagnon item buttons, including reused Blizzard buttons.
- Supports existing SMALL/LARGE/off Item Icons preferences without replacing Bagnon input scripts.
- Refreshes overlays after list, profile, rule and bag changes.
- Excludes cached other-character inventory, bank/keyring and stale displayed items.
- Supports either addon load order and preserves stock-bag behavior without Bagnon.

All Lua 5.1 regression suites, new Bagnon fixtures and deterministic packaging
checks pass. In-game visual acceptance is still required. Other Bagnon forks and
other bag addons are not implied to be supported. No Bagnon code is bundled.

## نصب و تست

فایل **Dejunk-WotLK-1.0.2.zip** را بگیرید و پوشهٔ قبلی Dejunk را کامل جایگزین کنید.
نیازی به تغییر فایل‌های Bagnon نیست. سپس `/reload` کنید.

در Global Options، Item Icons را روشن کنید. یک آیتم بی‌ارزش را به Inclusions
اضافه کنید و نمایش آیکن در Bagnon را بررسی کنید. حالت کوچک/بزرگ/خاموش، انتقال
آیتم بین خانه‌ها، حذف از فهرست، جست‌وجو و بازوبسته‌کردن کیف را تست کنید.
نمای بانک و شخصیت دیگر نباید آیکن مربوط به کیف فعلی را نشان بدهد.

[جزئیات اتصال و چک‌لیست فارسی](https://github.com/brok5522/Dejunk-WotLK/blob/main/docs/BAGNON-COMPATIBILITY.md)
