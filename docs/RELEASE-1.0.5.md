# Dejunk-WotLK 1.0.5

Original WoW 3.3.5a build 12340. Includes previous fixes and Bagnon support.

- Transport and `/djw lists import` validate new item IDs asynchronously before
  updating a list. Validation requests at most 25 items per tick, waits up to
  five seconds per ID after its first request, and keeps the import atomic.
- If item information does not arrive, no new IDs are committed. This is
  reported as unavailable, not definitively invalid; retry when the item is
  cached or the server responds. Previously saved list entries are preserved.
- Changes to profile or settings while waiting cancel the import. Closing the
  window does not let a background result reopen it.

Tests use actual Lua 5.1 and fake game APIs, including delayed responses, timeout,
changes during validation, duplicate requests and batching; package reproducibility
was verified. Original-client acceptance remains required. Direct list additions
use the existing path; positive confirmation of item deletion remains unverified.
This release does not claim complete upstream parity.

## نصب و تست

از SavedVariables پشتیبان بگیر، پوشهٔ قبلی را کامل با ZIP جدید جایگزین کن و
`/reload` بزن. از پنجرهٔ Lists چند شناسهٔ معتبر Import کن؛ بعد از پیام موفقیت،
نام آیتم‌ها و ماندگاری آنها پس از reload را بررسی کن. یک شناسهٔ ناموجود یا
لودنشده را جداگانه امتحان کن؛ اگر پاسخ نرسد نباید به فهرست اضافه شود. هنگام
انتظار، پروفایل یا تنظیمات را تغییر بده و بررسی کن که درخواست لغو شود.

کیف Bagnon، میان‌برها، فروش آیتم بی‌ارزش و تعمیر خودکار را نیز دوباره بررسی کن.
برای مسیر حذف، ابتدا تأییدیه را باز و Cancel کن. خطای Lua و مراحل وقوع را بفرست.
