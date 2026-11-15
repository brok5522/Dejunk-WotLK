# 0.16.61-beta.1 — Comprehensive client-test candidate

Import now follows the pinned reference's numeric-token extraction with arbitrary
non-numeric separators. Zero and out-of-range IDs are skipped. Import commit
rejects malformed previews atomically and counts capacity once, preserving
duplicate handling without repeated full-list scans.

Junk and list sorting now use the reference's case-sensitive item-name order.
Junk/Lootable clear stale empty states when bag data invalidates; Lootable clears
the unavailable-data message when valid data returns and discards stale source data.

Actual Lua 5.1 regression suites, UI/action fixtures and reproducible packaging
pass. Lootable fixtures verify lock/busy/right-click refusal and one valid
left-click dispatch. Tests use fake inventory APIs.

This is a client-test candidate. Exact localization, third-party bag integrations,
special equipment/category edges, asynchronous parser progress/messages and
transaction outcome/message parity remain open. See PARITY.md and VALIDATION.md.

## تست جامع داخل بازی

نسخه قبلی را کامل جایگزین کنید و از SavedVariables پشتیبان بگیرید.
با `/console scriptErrors 1` و سپس `/reload` خطاها را فعال کنید.

1. هر پنج صفحه را از مینی‌مپ، دستور و پایین پنجره باز کنید؛ بستن با Escape،
   بازکردن مجدد، جابه‌جایی پنجره و اسکرول را بررسی کنید.
2. در هر چهار فهرست، درگ آیتم، جست‌وجوی نام/شناسه، راست‌کلیک و Shift/Ctrl/Alt
   را بررسی کنید. Export باید متن قابل کپی بدهد. Import را با شناسه‌های
   تکراری و جداکننده‌های مختلف بررسی کنید و پس از reload ماندگاری را ببینید.
3. پروفایل بسازید، کپی/تغییرنام/ریست/حذف کنید؛ محافظت Default و انصراف را تست کنید.
4. کلیدهای میان‌بر را تنظیم، پاک و پس از reload بررسی کنید؛ تضاد کلیدها و Escape
   در حالت تایپ را هم ببینید.
5. با آیتم کم‌ارزش در فروشگاه، فروش تک‌ردیف و Start Selling، Auto Sell خاموش/روشن،
   Safe Sell، بستن فروشگاه وسط کار و جای دکمه را بررسی کنید.
6. تعمیر دستی/خودکار را با تجهیزات آسیب‌دیده و پول کافی بررسی کنید.
7. با یک آیتم واقعاً قابل‌بازکردن، Lootable، Ignore، قفل آیتم و Auto Lootable را
   بررسی کنید. Ignore باید تمام نمونه‌های همان شناسه را تا پایان نشست مخفی کند.
8. برای Destroy فقط پنجره تأیید و Cancel را تست کنید؛ حذف واقعی لازم نیست.
9. ابتدا با افزونه‌های دیگر خاموش، سپس با افزونه کیف خودتان تکرار کنید.

برای هر خطا نسخه، build کلاینت، مراحل دقیق، متن کامل خطا و `/djw report` را ثبت کنید.
موفقیت، شکست و موارد تست‌نشده را جدا گزارش کنید.
