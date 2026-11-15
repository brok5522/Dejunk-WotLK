# Dejunk-WotLK 1.0.0

First numbered release for **original WoW 3.3.5a, build 12340, Interface 30300**.
Includes all fixes through the owner-tested 0.16.65 candidate. Runtime behavior
is unchanged in this release; release metadata and documentation are updated.

## Included

- Global/profile inclusion and exclusion lists, search, drag/drop and import/export.
- Profiles, options, persistent keybindings, minimap and merchant controls.
- Junk preview, manual/automatic selling, Safe Sell, automatic repair and confirmed destruction.
- Lootable window with generic container detection, seven WotLK clam types,
  localized openable-tooltip fallback and session Ignore.
- Bundled Waffle, deterministic installable ZIP and required license notices.

## Verification and limits

Owner confirmed main UI, lists, profiles, startup keybindings, merchant behavior,
Auto Repair, bag visibility, clam detection and Lootable layering. Actual Lua 5.1
regression, action/UI fixtures and reproducible packaging are checked before publication.
Tests never delete real inventory. The reference is moody/Dejunk commit
`04bafd5e411441ef5b51bb8ed10d208f2d7758f5`.

Version 1.0.0 does not claim exact upstream parity: full localization, arbitrary
third-party bag integrations, equipment-category edge cases, parser progress and
exact transaction messages/outcome observation remain documented limitations.
Custom-server openable items without native flags or standard tooltips need
separate evidence. See PARITY.md, LOOTABLE-PARITY.md and VALIDATION.md.

## Installation / نصب

Download `Dejunk-WotLK-1.0.0.zip`, back up SavedVariables and replace the old addon
folder completely. Extract into `Interface/AddOns/`, keeping `Dejunk-WotLK` as
the folder containing `Dejunk-WotLK.toc`. Open with `/dejunk`.

نسخهٔ اول شامل اصلاحات تأییدشدهٔ کیف، میان‌بر پس از reload، تعمیر خودکار،
تشخیص صدف و نمایش Lootable است. پوشهٔ نسخهٔ قبلی را کامل جایگزین کنید.
این انتشار به معنی تأیید تمام حالت‌های ممکن یا تطابق صددرصدی با مرجع نیست.
برای گزارش مشکل، نسخه، build کلاینت، مراحل تکرار، خطای Lua و `/djw report`
را ارسال کنید. فایل ZIP افزونه را بگیرید، نه آرشیو خودکار Source code.
