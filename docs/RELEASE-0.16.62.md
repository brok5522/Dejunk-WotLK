# 0.16.62-beta.1 — Client feedback fixes

- Initialize saved keybinding actions at startup, before any settings page opens;
  reuse action buttons when the settings UI is later constructed.
- Accept legacy numeric `1` repair flags alongside booleans.
- Keep the main window below stock MEDIUM bag frames, including its fallback.
- Recognize Small Barnacled Clam (5523) as a use-effect loot item even when the
  container tuple does not mark it lootable. This is a narrow identity exception,
  not a generic consumable rule. Other spell-based containers need individual evidence.

Reference item: https://wotlk.evowow.com/?item=5523 (Use: open the clam).
Stock bag strata: build-12340 ContainerFrame.xml, ContainerFrameTemplate.
All regression suites run with actual Lua 5.1; inventory operations use mocks.
Native-client confirmation of these fixes is pending.

## تست مجدد

1. پوشه قبلی را کامل با این نسخه جایگزین کنید و `/reload` بزنید.
2. پیش از بازکردن پنجره افزونه، میان‌بر ذخیره‌شده را بزنید؛ باید همان ابتدا کار کند.
3. کیف و Lists را هم‌زمان باز کنید؛ کیف باید جلوی پنجره افزونه باشد و درگ آیتم کار کند.
4. با تجهیزات آسیب‌دیده، پول کافی و Auto Repair روشن، فروشگاه تعمیر را ببندید و
   دوباره باز کنید؛ تعمیر باید خودکار انجام شود.
5. با Small Barnacled Clam داخل کیف، `/dejunk loot` را بزنید؛ آیتم باید نمایش
   داده شود. با کلیک چپ بازش کنید و سپس Ignore و Auto Lootable را بررسی کنید.

پس از این اصلاحات، موارد قبلاً تأییدشده را هم کوتاه بازبینی کنید.
