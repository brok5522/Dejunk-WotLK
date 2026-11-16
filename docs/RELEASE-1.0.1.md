# Dejunk-WotLK 1.0.1

Audit and stability update for **original WoW 3.3.5a, build 12340, Interface 30300**.

## Fixed

- Recover malformed saved settings without discarding valid list members; retain
  the original damaged data for recovery. Normalize string item IDs.
- Reconcile opposite list membership within the same global/profile scope.
- Preserve filter scopes and qualities when toggled; allow resetting Default.
- Recheck binding, slot identity and settings revisions during action preparation.
  Legacy numeric combat/death results and unknown states block transactions.
- Track actual sale-slot outcomes rather than counting dispatch as success.
  Handle duplicate requests, unlock failure, five-second timeout and run summaries.
- Honor chat enabled/reduced/verbose preferences while keeping help visible.
- Reuse profile rows, clamp scroll offsets and respect manually closed Auto Junk.
- Use canonical English equipment IDs instead of auction positions; fix staff,
  shield and fishing-pole classification and cloak/type-filter behavior.
- Save numeric options after typing, Enter or focus loss; Escape restores the saved
  value. Disable subordinate controls with their parent filter; remove Apply.
- Correct stale read-only diagnostics and list-action wording.

## Verification and remaining limits

Passed actual Lua 5.1 syntax and regression checks: 67 core, 22 store, 8 service,
11 destroyer and 62 UI-model cases, plus production-action, UI-interaction and
audit-regression fixtures. The ZIP was built twice and checked for identical
bytes, source equality, CRC, install layout and notices.

No live inventory operation was used for these checks. The new build needs
original-client acceptance. Comprehensive localization and third-party bag icon
adapters remain incomplete. English class/subclass labels are recognized;
unrecognized localized category labels are not assigned guessed numeric IDs.
This is a bug-fix release, not a claim of complete upstream parity.

## نصب و تست نسخهٔ جدید

فایل **Dejunk-WotLK-1.0.1.zip** را دانلود کنید، از SavedVariables نسخهٔ پشتیبان
بگیرید و پوشهٔ قبلی افزونه را کامل جایگزین کنید؛ فایل‌های نسخه‌ها را مخلوط نکنید.
مسیر نهایی باید `Interface/AddOns/Dejunk-WotLK/Dejunk-WotLK.toc` باشد.

1. با `/console scriptErrors 1` و `/reload` ورود، میان‌برها و فهرست‌های قبلی را بررسی کنید.
2. فیلتر خاموش باید زیرگزینه‌های غیرفعال داشته باشد. روشن کنید، مقدار عددی وارد کنید؛
   ذخیره با پایان تایپ/Enter و لغو تغییر با Escape را بررسی کنید. دوباره reload کنید.
3. پروفایل‌ها را چند بار باز کنید؛ جست‌وجو، اسکرول، انتقال فهرست و Reset پروفایل Default را تست کنید.
4. کنار تاجر یک آیتم بی‌ارزش بفروشید؛ تعداد واقعی کیف، پیام نتیجه و جمع نوبت فروش را مقایسه کنید.
   خاموش‌کردن پیام‌ها و Reduced/Verbose را هم بررسی کنید.
5. پنجرهٔ خودکار Junk را دستی ببندید و کیف را تغییر دهید؛ نباید فوراً دوباره باز شود.
6. تعمیر خودکار، صدف/Lootable و نمایش پنجره‌ها را دوباره تست کنید.
   برای بررسی رابط حذف، تأییدیه را باز کنید و Cancel بزنید.

اصلاحات اصلی ذخیره‌سازی، فیلترها، گزارش فروش و ورودی‌های تنظیمات انجام شده‌اند.
ترجمهٔ کامل و آیکن روی کیف افزونه‌های دیگر هنوز محدودیت دارند؛ تطابق صددرصدی ادعا نمی‌شود.
گزارش خطا را همراه نسخه، build، مراحل تکرار، خطای کامل Lua و `/djw report` ارسال کنید.
