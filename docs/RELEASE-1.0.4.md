# Dejunk-WotLK 1.0.4

Reliability update for original WoW 3.3.5a, build 12340. Includes 1.0.3 and
Bagnon 3.3.5 support.

- Retry incomplete item data for up to five seconds; bag changes interrupt an
  older pending retry and trigger a prompt refresh.
- Reject mixed item observations when a slot or its rule metadata changes while
  binding information is read, including cache, preview and transaction paths.
- Block conflicting manual sale/destruction actions while another run or attempt
  is pending. On a destroy attempt, report unlock failure or an unconfirmed result;
  slot disappearance after pickup is not presented as proof of deletion.

Actual Lua 5.1 tests, fake-API action tests, Bagnon fixtures and reproducible ZIP
checks pass. No in-game deletion was performed. In-game acceptance is required;
positive destroy confirmation and asynchronous validation of newly imported item
IDs remain incomplete compared with upstream. This release is not a claim of
complete upstream parity.

## نصب و تست

از SavedVariables پشتیبان بگیرید، پوشهٔ قبلی افزونه را کامل با ZIP جدید
جایگزین کنید و `/reload` بزنید. نمایش کیف و Bagnon، فهرست‌ها، جابه‌جایی آیتم،
تغییر پروفایل و فروش یک آیتم بی‌ارزش را بررسی کنید. برای حذف فقط پنجرهٔ تأیید
را باز و Cancel را امتحان کنید. در صورت خطا، متن کامل Lua و مراحل را ارسال کنید.
