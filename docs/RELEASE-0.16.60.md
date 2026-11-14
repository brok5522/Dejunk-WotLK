# Dejunk-WotLK 0.16.60-beta.1

Complete installable package for **original WoW 3.3.5a / build 12340 / Interface 30300**.
Download `Dejunk-WotLK-0.16.60-beta.1.zip` below; do not install GitHub's source archive.

## Included

- Lists, Global Options, Profile Options, Profiles and Keybindings.
- Junk/Lootable windows, merchant/minimap controls, bag tooltips and overlays.
- Guarded manual/automatic selling, optional repair and deliberate item actions.
- Minimap reopen, Escape, drag/drop, input border, window layering and merchant
  portrait/name placement fixes from owner feedback.
- Footer navigation, readable filter reasons, plain scrollbars and action lifecycle fixes.
- English/Persian README files and MIT / CC BY artwork notices inside the ZIP.

## Install / upgrade

Close WoW, back up your WTF SavedVariables, and replace the old addon folder.
The resulting path must be `Interface/AddOns/Dejunk-WotLK/Dejunk-WotLK.toc`.
Enable the addon and run `/dejunk`. No external addon dependencies are required.

## Validation and remaining work

The owner reported successful main UI and merchant placement checks on 0.16.59.
Lua 5.1 regression, store, service, action-lifecycle and UI interaction checks pass;
ZIP contents and reproducibility are verified. The runtime in this publication
matches 0.16.59 apart from release metadata.

This is a **community beta**, not a claim of exact upstream parity. Lootable
client acceptance, localization, third-party bag adapters, filter edge cases and
exact upstream transaction messages/outcome observation remain under review.
Deletion was not tested on a live inventory. See the repository's `docs/PARITY.md`
and client-test guide before reporting completion.

## Licensing

Port code and Waffle: MIT. Cash logo by Lorc: CC BY 3.0. Font Awesome UI icons:
CC BY 4.0. Attribution and license links are included in the package. This is an
independent port based on moody/Dejunk's pinned design; no endorsement is implied.

---

## فارسی

بستهٔ کاملِ قابل‌نصب برای WoW اصلی 3.3.5a، بیلد 12340 است. فایل ZIP افزونه را
دانلود کنید و پس از بکاپ SavedVariables، پوشهٔ قدیمی را کامل جایگزین کنید.
این انتشار بتای عمومی است؛ موفقیت تست‌های اصلی به معنی تأیید همهٔ قابلیت‌ها نیست.
README فارسی و مجوزهای کد و آرت داخل بسته هستند. برای مشکلات، نسخهٔ افزونه،
متن خطا و مراحل ایجاد مشکل را در Issues ثبت کنید.
