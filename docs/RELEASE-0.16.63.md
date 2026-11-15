# 0.16.63-beta.1 — WotLK clam and container coverage

All seven original-era clam identities are recognized even when their open-and-loot
use effect does not set the container loot flag: Small Barnacled, Thick-shelled,
Big-mouth, Soft-shelled, Jaggal, Darkwater and Giant Darkwater Clam.
Arbitrary bag items carrying the native loot flag remain supported without an ID
allowlist, matching the reference addon's `hasLoot` selection.

Source comparison and evidence: [LOOTABLE-PARITY.md](LOOTABLE-PARITY.md).
Regression fixtures cover every clam, an arbitrary flagged container and a
non-loot consumable. Actual Lua 5.1 checks and deterministic packaging pass.
Includes all 0.16.62 fixes for startup keybindings, Auto Repair and bag layering.

## تست

پوشه قبلی را کامل جایگزین کنید. هر نوع صدف موجود و یک جعبه/هدیه قابل‌بازشدن را
با `/dejunk loot` بررسی کنید. کلیک چپ باید همان آیتم را باز کند؛ Ignore باید
تمام نمونه‌های همان نوع را تا پایان نشست پنهان کند. خوراکی و معجون نباید وارد
این پنجره شوند. آیتم قفل‌شده همچنان به رفع قفل یا شرایط بازی نیاز دارد.
