# راهنمای بازبینی و ادغام فاز صفر

تغییرات روی شاخهٔ `phase-0/research-and-architecture` در مخزن محلی آماده شده‌اند.
مخزن مقصد تنظیم‌شده `brok5522/Dejunk-WotLK` است. هیچ انتشار یا ادغام خودکاری
انجام نمی‌شود. وضعیت push و commit واقعی در گزارش تحویل ذکر می‌شود؛ وجود
فایل‌های آماده به معنی ساخته‌شدن Pull Request در GitHub نیست.

۱. README و گزارش فارسی را بخوانید؛ سپس نقشهٔ راه، معماری، سیاست ایمنی و
AGENTS.md را بررسی کنید. مهم‌ترین تصمیم‌ها: هدف کلاینت اصلی، اطلاعات نامطمئن
مانع عملیات، و جدا بودن فاز تحقیق از پیاده‌سازی است.

۲. در محیط مخزن این دستورها را اجرا کنید:
```sh
git status --short --branch
python3 tools/check_phase0.py
git diff --check
git diff --stat
git diff
# After a local commit, compare the complete branch with the initial commit:
git diff a749c4a...HEAD --stat
git diff a749c4a...HEAD
```
فایل‌های جدید قبل از stage در `git diff` نمایش داده نمی‌شوند؛ آن‌ها را در ویرایشگر
باز کنید، یا پس از `git add` از `git diff --cached` استفاده کنید.

۳. اگر هنوز commit ساخته نشده است، تغییرات آماده را ثبت کنید:
```sh
git add AGENTS.md README.md docs src locales libs tests tools .github .gitignore .editorconfig
git diff --cached --check
git diff --cached --stat
git commit -m "docs: prepare Phase 0 WotLK research and architecture"
```
سپس شاخه را به مخزن خودتان بفرستید:
```sh
git push -u origin phase-0/research-and-architecture
```

۴. در GitHub گزینهٔ Compare & pull request را انتخاب کنید؛ شاخهٔ مقصد باید
شاخهٔ پیش‌فرض واقعی مخزن باشد. عنوان و متن آماده در
[PULL_REQUEST_PHASE0.md](PULL_REQUEST_PHASE0.md) است. در Files changed مطمئن
شوید هیچ کد اجرایی فروش/حذف، فایل SavedVariables شخصی یا سورس دانلودشدهٔ
بازی وارد تغییرات نشده است. Checks باید سبز باشد. اگر CI اجرا نشده، ادعای موفقیت
GitHub نکنید؛ خروجی محلی و CI دو نتیجهٔ جدا هستند.

۵. پس از مطالعه و رضایت، خودتان Merge pull request یا Squash and merge را بزنید.
ادغام مستندات به‌تنهایی مجوز شروع فاز بعد نیست. برای ادامه صریحاً بگویید:
«فاز صفر را تأیید می‌کنم؛ فاز ۱ را شروع کن.»

در این مرحله نیازی به نصب افزونه، ورود به بازی یا دست‌زدن به موجودی نیست.
