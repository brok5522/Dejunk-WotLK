# راهنمای آزمایش فاز ۲

این نسخهٔ آزمایشی تنظیمات را در SavedVariables حساب ذخیره می‌کند. فرمان‌ها فقط
پروفایل و فهرست شناسهٔ آیتم‌ها را تغییر می‌دهند؛ هیچ فروش، حذف، تعمیر یا استفاده
از آیتمی انجام نمی‌دهند. پیش از آزمایش، از پوشهٔ `WTF/Account` نسخهٔ پشتیبان بگیرید.

## فرمان‌ها

```text
/djw profile list
/djw profile create Raid
/djw profile switch profile-1
/djw profile rename profile-1 Raid Main
/djw profile reset profile-1
/djw profile delete profile-1
```

پروفایل `default` حذف، بازنشانی یا تغییرنام داده نمی‌شود. ساختن پروفایل آن را
برای شخصیت فعلی فعال می‌کند. شناسهٔ پروفایل را از دستور `profile list` بردارید.

برای ویرایش فهرست:

```text
/djw lists add global inclusions 6948
/djw lists add profile exclusions 12345
/djw lists show global inclusions
/djw lists import profile inclusions 123, 456, 789
/djw lists remove profile exclusions 12345
```

فهرست‌ها فعلاً فقط تنظیمات هستند؛ در این فاز به تشخیص زباله یا عملیات کیف متصل
نیستند. واردکردن متن فقط عدد آیتم می‌پذیرد و کد یا دستور اجرا نمی‌کند.

## نصب

ZIP فاز ۲ را استخراج کنید و پوشهٔ `Dejunk-WotLK` را داخل
`World of Warcraft/Interface/AddOns/` بگذارید. افزونه را از صفحهٔ انتخاب
شخصیت فعال کنید. اگر `/djw status` وضعیت READY نشان داد، می‌توانید فرمان‌های
بالا را امتحان کنید. پس از ساخت پروفایل، از شخصیت خارج و دوباره وارد شوید تا
ذخیره‌شدن نتیجه را بررسی کنید. حذف یا تغییر دستی SavedVariables لازم نیست.

این نسخه هنوز پنجرهٔ تنظیمات ندارد. برای دیدن راهنمای فرمان‌ها `/djw help` را
اجرا کنید. فاز ۲ را پس از بررسی، از طریق Pull Request بازبینی کنید؛ فاز بعد
شامل موتور قوانین است و هنوز شروع نشده است.
