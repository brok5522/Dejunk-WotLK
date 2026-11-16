# Audit fixes — 2026-11-16

Baseline: f416bdd52906d440ae060e194a15fb639f9e824b (published 1.0.0).
Reference: moody/Dejunk 04bafd5e411441ef5b51bb8ed10d208f2d7758f5.
Changes are included in release 1.0.1. Original-client acceptance has not been run.

## خلاصهٔ فارسی

اصلاحات اجرایی اعمال شده‌اند؛ گزارش قبلی فقط سابقهٔ خطاهای نسخهٔ 1.0.0 است.
موارد زیر با تست Lua 5.1 بررسی می‌شوند. «پیاده‌سازی‌شده» به معنی تأیید بصری
یا عملیاتی داخل بازی نیست. موارد باز و نیمه‌کامل جداگانه آمده‌اند.

| یافته | وضعیت اصلاح |
|---|---|
| 1 | نوع quality و schemaVersion پیش از استفاده بررسی می‌شود؛ دادهٔ نسخهٔ نامعتبر بازیابی می‌شود |
| 2 | مقدار عددی 1 برای جنگ/مرگ و وضعیت غیرمنتظره عملیات را مسدود می‌کند |
| 4 | اطلاعات Binding در کش خوانده و هویت slot پس از خواندن دوباره بررسی می‌شود |
| 5 | کلیدهای رشته‌ای شناسه به عدد تبدیل و ادغام می‌شوند |
| 6 | افزودن مستقیم و import عضویت مخالف همان محدوده را رفع می‌کنند؛ محدودهٔ دیگر حفظ می‌شود |
| 7 | adapter وضعیت Quest/Set تأییدشدهٔ intent را می‌پذیرد؛ تغییر وضعیت و دادهٔ نامعلوم مسدود می‌ماند |
| 8 | ادعاهای Phase 1 و Read Only در وضعیت و diagnostics اصلاح شدند |
| 9 | revision پس از pickup و پیش از حذف دوباره بررسی می‌شود |
| 10 | خاموش‌کردن پیام‌ها و Reduced/Verbose اعمال می‌شوند؛ help به‌طور اجباری قابل مشاهده است |
| 11 | مسیر واقعی فروش، timeout پنج‌ثانیه‌ای، شکست Unlock، تغییر slot و خلاصهٔ نوبت فروش را مشاهده می‌کند |
| 12 | متن میان‌برها «افزودن» است؛ Ctrl/Alt حذف عمومی مبدأ انجام نمی‌دهند |
| 13 | offset اسکرول پس از کوچک‌شدن محتوا clamp می‌شود؛ تأیید رندر کلاینت باقی است |
| 16 | Cloak از انتخاب نوع تجهیزات مستثنا شد؛ fallback نیز اصلاح شد |
| 18 | ردیف‌ها و دکمه‌های Profiles بازاستفاده می‌شوند؛ refresh فریم جدید نمی‌سازد |
| 19 | وضعیت انتشار در README و ROADMAP از تغییرات منتشرنشده جدا شد |
| 20 | خاموش/روشن‌کردن فیلتر، scope و کیفیت‌های انتخاب‌شده را حفظ می‌کند |
| 22 | Default قابل Reset است؛ Rename و Delete همچنان ممنوع‌اند |
| 23 | اعضای معتبر فهرست خراب حفظ و اصل داده در recovery نگهداری می‌شود؛ پیام بازیابی نمایش داده می‌شود |
| 24 | بستن دستی Auto Junk تا پایان همان وضعیت خودکار حفظ می‌شود |

## Partial and open work

- **3 — Partial:** removed positional auction-to-enum guesses. English item class
  and subclass labels map explicitly to canonical IDs; UI and slot reads share
  the mapping. Staff=10, shield=6 and fishing pole=20 have regression coverage,
  including reordered auction lists. Unrecognized localized labels remain unknown.
  Comprehensive localized category support still needs original-client evidence.
- **17 — Partial:** canonical-ID equipment predicates exempt fishing poles,
  generic/cosmetic armor and generic weapons, retaining jewelry/holdable exceptions.
  Canonical and bootstrap fallback paths match; localized support depends on 3.
- **21 — Implemented offline:** removed Apply. Number inputs save after 0.5 seconds
  of user-input inactivity, Enter or focus loss. Escape/empty focus loss restores
  the saved value; price Tab/Shift-Tab cycles inputs. Disabled parent filters disable
  their scope/quality/type/input controls. Client focus and timing acceptance pending.
- **14 — Open:** comprehensive localization has not been ported.
- **15 — Open:** third-party bag widget discovery/integration has not been added.
  Stock ContainerFrame overlays remain the supported implementation.

## Validation and interpretation

`tests/review-regressions.lua` covers recovery, normalized IDs, opposite lists,
scope preservation, Default reset, schema startup, binding/cache agreement,
manual-close lifecycle, numeric guards, post-pickup revision and equipment cases.
UI fixtures additionally check constant frame count, scroll clamping, chat gating
and threshold persistence, debounce, Escape and disabled subcontrols. Production sale observation tests exercise
Application callbacks, not only the separate SimulationSeller service.

Sale confirmation follows the reference's slot-disappearance observation. It is
not a server transaction receipt; the summary reports vendor value, not a claim
that every money change came from this addon. Unknown/unchanged slots never count
as confirmed; five-second timeout reports uncertainty. No real inventory calls
were used for verification.

Client retest: clean install; load existing lists; reload; toggle scoped filters;
open Profiles repeatedly; shrink a scrolled list with search; close Auto Junk
manually and change a bag; verify disabled chat/help; test a disposable sale and
its resulting message. Destruction acceptance should remain cancel-only until a
separate deliberate disposable-item test is authorized.
