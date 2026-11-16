# Fresh review of 1.0.0

**Implementation update:** this is the historical baseline audit. Subsequent
code fixes and remaining work are tracked in [FIXES-REVIEW-1.0.0.md](FIXES-REVIEW-1.0.0.md).
Statements below that findings are open or no runtime changed describe the
review snapshot, not the current working tree.

Reviewed snapshot: local commit f416bdd52906d440ae060e194a15fb639f9e824b.
Reference: moody/Dejunk 04bafd5e411441ef5b51bb8ed10d208f2d7758f5.
This records verified findings, not an assertion that every runtime/UI line has
received exhaustive review. No executable code changed during this review.

## نتیجهٔ نهایی این دور بازبینی آفلاین — 2026-11-16

این دور بازبینی و گزارش آن جمع‌بندی شد. نتیجه: نسخهٔ 1.0.0 را نمی‌توان
«هم‌ارز کامل مرجع و بدون ایراد شناخته‌شده» تأیید کرد. ۲۴ یافته ثبت شده که
۱۵ مورد با Lua 5.1 و داده/API جعلی بازتولید شده‌اند. تمام یافته‌ها باز هستند؛
این گزارش جای اصلاح کد را نمی‌گیرد.

| حوزه | نتیجهٔ بازبینی | شرط بسته‌شدن |
|---|---|---|
| بارگذاری و حفظ داده‌ها | 1، 5، 23؛ توقف بارگذاری یا از دست‌رفتن عضویت سالم | تست بازیابی از ورودی خراب، بدون ازدست‌رفتن دادهٔ سالم |
| محافظ عملیات | 2، 9؛ نرمال‌سازی وضعیت و بازبینی revision | تست‌های جعلی که هیچ اقدام نامجاز را dispatch نکنند |
| قواعد و تطابق تصمیم‌ها | 3، 4، 7، 16، 17، 20، 21 | تصمیم یکسان در cache، Tooltip و adapter؛ تست قرارداد مرجع |
| فهرست و پروفایل | 6، 12، 18، 22 | عضویت مخالف، معنای میان‌بر، استفادهٔ مجدد از فریم و Reset |
| فروش و پیام‌ها | 8، 10، 11 | مشاهدهٔ نتیجهٔ فروش و گزارش مطابق تنظیمات |
| نمایش و پوشش محیط | 13، 14، 15، 19، 24 | تست کلاینت برای هندسه؛ تعیین پوشش زبان/کیف؛ هماهنگی مستندات |

اولویت اجرا: ابتدا 1، 2، 9 و 23؛ سپس اصلاح قواعد و ذخیره‌سازی؛ سپس رفتارهای
UI، پیام‌ها و مستندات. موارد 3 و 13 هنوز نیازمند شاهد کلاینت‌اند و نباید به
عنوان خطای بازتولیدشده در بازی معرفی شوند. موارد 14 و 15 کمبود پوشش‌اند.

**اعتبارسنجی نهایی:** مجموعهٔ کامل check.py با Lua/luac 5.1 دوباره پاس شد؛
شامل ۶۷ تست پایه، ۲۲ ذخیره‌ساز، ۸ سرویس، ۱۱ destroyer، ۶۲ مدل UI، تست‌های
تعامل و تراکنش و دو بستهٔ بازتولیدپذیر ۴۱‌فایلی. این موفقیت ایرادهای گزارش
را رد نمی‌کند؛ تعدادی از سناریوهای بازتولیدشده در تست‌های قبلی پوشش نداشتند.

**مرز نتیجه:** این جمع‌بندی، ممیزی مستقل تک‌تک خطوط همهٔ کدهای مرجع و
کتابخانه‌های vendored، تضمین نبود خطا یا تأیید بصری داخل بازی نیست. سورس
پورت، مسیرهای رفتاری مرتبط مرجع و شواهد FrameXML بررسی شده‌اند؛ کتابخانهٔ
Waffle از نظر pin/checksum و تست یکپارچگی بررسی شده، نه ممیزی مستقل هر خط.
تست واقعی کلاینت، چندزبان و کیف‌های شخص ثالث در این محیط اجرا نشده است.
بخش‌های «continuation» پایین سند، سابقهٔ بررسی و محدودیت‌های هر مرحله‌اند.

تغییر این دور فقط در REVIEW و VALIDATION است؛ هیچ اصلاح runtime، نصب در
بازی یا انتشار جدید GitHub انجام نشده است.

## خلاصهٔ فارسی و نحوهٔ استفاده از گزارش

این گزارش ۲۴ یافته دارد، نه ۲۴ خطای تأییدشده در بازی. پانزده مورد با Lua 5.1
و دادهٔ آزمایشی بازتولید شده‌اند؛ بقیه اختلاف مسیر کد، کمبود قابلیت یا ریسک
نیازمند آزمون هستند. شدت «High» اولویت اصلاح را نشان می‌دهد، نه اثبات وقوع
آسیب در بازی. نسخهٔ بررسی‌شده 1.0.0 است؛ این سند تغییر اجرایی ایجاد نمی‌کند.

| شماره | محرک / سناریو | اثر قابل‌انتظار | نوع شاهد | تست پذیرش اصلاح |
|---|---|---|---|---|
| 1 | مقدار quality در SavedVariables برابر true باشد | بارگذاری متوقف می‌شود | بازتولید Lua | دادهٔ خراب ترمیم شود و تنظیمات سالم حفظ شوند |
| 2 | API وضعیت جنگ یا مرگ مقدار 1 برگرداند | محافظ وضعیت آن را مجاز می‌بیند | بازتولید با API جعلی | true و 1 مسدود؛ nil/false طبق قرارداد واقعی؛ خطای API مسدود |
| 3 | زیرکلاس‌ها در Auction فهرست فشرده داشته باشند | نوع تجهیزات اشتباه انتخاب می‌شود | فرض ناسازگار در سورس؛ نیازمند جدول معتبر کلاینت | سپر، چوب ماهیگیری، سلاح و relic در چند زبان درست نگاشت شوند |
| 4 | Exclude Unbound Equipment روشن شود | آیتم Bound هم از نامزدهای کش‌شده حذف می‌شود | بازتولید مسیر Application با API جعلی | نتیجهٔ Tooltip، preview، Junk و اقدام برای یک آیتم یکسان باشد |
| 5 | کلید شناسه در فایل ذخیره به شکل رشته باشد | نمایش/خروجی هست ولی حذف و قواعد آن را نمی‌بینند | بازتولید Lua | کلیدهای عددی و رشته‌ای ادغام شوند؛ reload و حذف موفق باشد |
| 6 | یک آیتم به دو فهرست مخالف اضافه شود | Exclusion همچنان Inclusion را خنثی می‌کند | بازتولید و مقایسهٔ مرجع | افزودن معتبر، عضویت مخالف همان محدوده را رفع کند |
| 7 | تنظیمات آیتم quest/set را مجاز کنند | نامزد نمایش داده می‌شود ولی فروش رد می‌شود | بازتولید evaluator و adapter | وضعیت دکمه و نتیجهٔ اقدام با سیاست واحد مطابقت داشته باشد |
| 8 | کاربر گزارش تشخیصی بگیرد | گزارش ادعای نادرست Read-only می‌کند | متن اجرایی | نسخه، وضعیت و قابلیت‌های واقعی بدون ادعای قدیمی نمایش داده شوند |
| 9 | hook بعد از pickup تنظیمات را تغییر دهد | بازبینی پیش از حذف تغییر را نمی‌گیرد | بازتولید predicate؛ بدون حذف | تغییر revision پس از pickup، حذف جعلی را صفر نگه دارد |
| 10 | Chat Messages خاموش یا Verbose انتخاب شود | تنظیم خروجی رعایت نمی‌شود | نبود مصرف تنظیم در مسیر Print | خاموش، Reduced، Verbose و پیام اجباری help جدا آزموده شوند |
| 11 | API فروش خطا ندهد ولی سرور فروش را نپذیرد | تأیید نتیجه و خلاصهٔ معتبر وجود ندارد | مقایسهٔ مسیر production با Confirmer مرجع | عدم تغییر slot، unlock، timeout و فروش موفق در مسیر واقعیِ شبیه‌سازی‌شده |
| 12 | modifier-right-click | پیام انتقال با رفتار افزودن در مرجع ناسازگار است | مقایسهٔ مستقیم callback مرجع | متن Add باشد؛ Ctrl و Alt مبدأ را حفظ کنند؛ Shift از قاعدهٔ عضویت مخالف پیروی کند |
| 13 | پس از اسکرول، جست‌وجو نتایج را کوتاه کند | احتمال نمایش خالی یا موقعیت خارج محدوده | سورس؛ نیازمند تست هندسه/کلاینت | offset بعد از جست‌وجو، حذف و resize در بازهٔ جدید باشد |
| 14 | کلاینت غیرانگلیسی اجرا شود | رابط همچنان انگلیسی است | نبود ماژول ترجمه در TOC | متن و fallback زبان با پوشش کلیدهای ترجمه بررسی شود |
| 15 | کیف غیراستاندارد جای stock bags را بگیرد | overlay روی دکمه‌های جدید نصب نمی‌شود | محدودیت enumeration | برای هر افزونهٔ اعلام‌شده integration جداگانه آزموده شود |
| 16 | Cloth inclusion و یک Cloak معمولی | Cloak برخلاف مرجع Junk می‌شود | بازتولید Lua و استثنای صریح مرجع | Cloak با فیلتر نوع match نشود؛ قواعد مستقل همچنان کار کنند |
| 17 | فیلتر level روی fishing/generic equipment | موارد معاف مرجع match می‌شوند | بازتولید evaluator و مقایسهٔ IsItemEquipment | fishing/generic معاف؛ گردنبند، انگشتر، trinket و holdable حفظ شوند |
| 18 | تازه‌سازی مکرر Profiles | دکمه‌ها و منابع UI بدون استفادهٔ مجدد افزایش می‌یابند | بازتولید Lua با UI جعلی | بعد از گرم‌شدن صفحه، ۱۰۰ تازه‌سازی با پروفایل ثابت فریم جدید نسازد |
| 19 | مراجعه به README و ROADMAP | وضعیت انتشار و آمادگی متناقض است | متن مستندات | وضعیت نسخه، شواهد تست و موارد باز در هر دو سند هماهنگ شوند |
| 20 | خاموش/روشن کردن Exclude Equipment Sets یا Unbound | محدودهٔ SELL یا DESTROY به BOTH بازنشانی می‌شود | بازتولید Store و ردیابی UI | تغییر enabled، scope و qualities را حفظ کند؛ پس از reload نیز ثابت باشند |
| 21 | Apply مقدار فیلتر خاموش | فیلتر بدون تغییر مستقیم تیک فعال می‌شود؛ زیرکنترل‌ها برخلاف مرجع فعال‌اند | بازتولید UI و مقایسهٔ OptionsBuilder | ویرایش مقدار، enabled را تغییر ندهد؛ حالت غیرفعال و ثبت ورودی مطابق مرجع باشد |
| 22 | Reset پروفایل Default | دکمه فعال است ولی Store درخواست را رد می‌کند | بازتولید Lua و مقایسهٔ reducer مرجع | Reset با حفظ نام/شناسه/انتساب کاراکتر انجام شود؛ Rename و Delete همچنان ممنوع بمانند |
| 23 | یک کلید نامعتبر در فهرست ذخیره‌شده | همهٔ اعضای سالم فهرست نیز حذف می‌شوند و نسخهٔ بازیابی نگهداری نمی‌شود | بازتولید بارگذاری Store | اعضای سالم حفظ و دادهٔ ردشده برای بازیابی نگهداری شود؛ Exclusions بی‌صدا خالی نشود |
| 24 | بستن دستی Junk پس از نمایش خودکار | پنجره با تغییر کیف دوباره باز می‌شود | بازتولید Application و مقایسهٔ مرجع | در همان نشست، بسته‌ماندن دستی حفظ شود؛ نشست فروشگاه بعدی دوباره اجازهٔ نمایش داشته باشد |

### ترتیب پیشنهادی اصلاح و وابستگی‌ها

- ابتدا 1، 2 و 9: پایداری بارگذاری و محافظ عملیات. تمام تست‌های حذف فقط جعلی باشند.
- سپس 3، 4، 16 و 17: نگاشت نوع و اطلاعات Binding، پیش‌نیاز اعتماد به فیلترهاست.
- سپس 5، 6 و 12: یک مسیر واحد برای ویرایش و import؛ افزودن با میان‌برها مطابق مرجع باشد، نه حذف عمومی مبدأ.
- سپس 7 و 11: سیاست اقدام و مشاهدهٔ نتیجه در مسیر production؛ نه صرفاً مدل مستقل.
- سپس 10، 13 و 8: پیام‌ها، اسکرول و گزارش تشخیصی.
- موارد 20 و 21 همراه با اصلاح تنظیمات بررسی شوند؛ تغییر ناخواستهٔ محدوده یا
  فعال‌سازی فیلتر می‌تواند نامزدهای فروش/حذف را تغییر دهد.
- 14 و 15 پروژه‌های پوشش زبان/یکپارچه‌سازی‌اند؛ نام زبان‌ها و افزونه‌های پشتیبانی‌شده
  باید مشخص باشد، نه ادعای سازگاری با همهٔ محیط‌ها.

### آنچه این گزارش اثبات نمی‌کند

این سند وقوع حذف یا فروش اشتباه در بازی کاربر را گزارش نمی‌کند. تست‌های موفق
قبلی کاربر برای کیف، میان‌بر، تعمیر خودکار و Lootable همچنان معتبرند و با این
یافته‌های مسیرهای دیگر تعارض ندارند. بررسی تمام خطوط runtime، همهٔ ماژول‌های
مرجع و تست چندزبان/چندافزونه هنوز کامل نشده است. «پاس‌شدن تست‌های موجود» و
«نبودن ایراد» دو نتیجهٔ متفاوت‌اند.

## Findings

1. **High: saved-data recovery can crash.** store.lua:69 indexes value.quality
   when it is truthy, without requiring a table. Initialize a schema-2 profile
   with options.quality=true: Lua 5.1 raises an indexing error. This blocks load
   instead of repairing the malformed setting.
   A second reproduced load boundary exists at bootstrap.lua:347-348: a truthy
   nonnumeric schemaVersion (for example the string "2") is compared with the
   numeric Store.VERSION before Store.Initialize can perform recovery. Firing
   ADDON_LOADED with that saved table raises "attempt to compare number with
   string" in actual Lua 5.1. Validate the type at the application boundary too;
   fixing cleanOptions alone does not cover this startup failure.

2. **High: numeric combat/death flags bypass context guards.** runtime.lua:28
   compares only with true. Fake APIs returning 1 produce safeContext=true and
   inCombat=false. Requires legacy flag normalization throughout action guards;
   this is a reproduced input-shape defect, not evidence of a live deletion.

3. **High: equipment category IDs are guessed from auction positions.**
   legacy.lua:83/92 subtract one from compact list indices. Item subclass IDs
   need not be contiguous (shield/fishing categories in particular). Equipment
   inclusion/exclusion filters can therefore classify the wrong category.
   Qualification: item reads and option widgets currently share the positional
   mapping. Matching labels can still agree with one another despite noncanonical
   IDs, so an incorrect live selection is not demonstrated merely by proving
   sparse subclass IDs. The pinned legacy Auction UI uses these returns as UI
   filter positions; the inspected FrameXML does not supply their concrete
   localized return arrays or establish a canonical-ID crosswalk. Validate both
   class and subclass outputs on build 12340 before claiming a specific shield
   or fishing-pole misclassification. This remains an unverified mapping risk.

4. **Medium: unbound-equipment filter lacks binding data in cached projections.**
   bag-cache.lua calls ReadSlot but never ReadBinding. ReadSlot initializes bound
   UNKNOWN; evaluator requires known binding when that filter applies. Explicit
   ProbeSlot reads binding, but JunkItems.Build consumes the unresolved cache.
   Enabling this filter can hide bound items that should remain candidates.
   Follow-up actual Lua 5.1 probe used Harness.New():Load(), a Poor head item,
   localized ITEM_SOULBOUND tooltip text, Ready(), and the real Store option
   setter. GetJunkItems returned zero rows while GetSlotDecisions for the same
   slot returned JUNK/QUALITY for SELL and JUNK for DESTROY. The harness mutation
   count remained zero. This upgrades the finding from source tracing to an
   application-path reproduction; original-client rendering was not tested.

5. **Medium: numeric-string saved list keys are retained but cannot be edited.**
   listValid accepts ['123']; cleanGlobal/cleanProfile copy it unchanged. Rules
   and EditList use numeric keys. Reproduced: export retains ID, removal returns
   NOT_PRESENT. Normalize keys during loading/migration.

6. **Medium: opposite lists are not reconciled.** store.lua:400 and CommitImport
   retain both inclusion/exclusion entries. Reproduced through EditList. Upstream
   lists.lua's ListItemParsed callback removes the opposite membership after
   successful validation. The port's exclusion continues to override inclusion.

7. **Medium: action eligibility contradicts profile options.** runtime.lua:94
   always rejects quest/equipment-set items even after evaluator approval with
   those exclusions disabled or overridden by explicit inclusion. UI candidates
   can therefore silently fail to sell.
   Follow-up Lua 5.1 fixture put item 123 in profile inclusions and separately
   set quest=true or inEquipmentSet=true. Rules returned JUNK in both cases;
   AttemptSale returned false/STALE_OR_PROTECTED_ITEM with zero calls to the
   fake UseContainerItem. This confirms the predicate mismatch, not whether
   a particular live quest item is actually vendor-sellable. Resolve policy
   consistently across projection and dispatch; do not simply remove unknown-
   metadata or identity guards to make the tests pass.

8. **Low: diagnostics falsely describe the installed addon as read-only.**
   diagnostics.lua:34/64 state PHASE 1 and no mutation APIs. Production actions
   are connected; these claims mislead bug reports and users.

9. **High: settings revision is not checked after pickup.**
   runtime.lua:131 builds a context containing currentSettingsRevision but never
   compares it with the intent. DeletePickedUpItem relies on this predicate.
   Actual Lua 5.1 fake-API reproduction returned true for an expected revision
   of 1 and current revision of 2, with matching cursor ID and empty source.
   A synchronous hook changing settings after pickup bypasses the intended
   cancellation boundary. No DeleteCursorItem was called during reproduction.

10. **Medium: Chat Messages and verbosity options have no output effect.**
    runtime.lua:481 always prints. chatMessages is referenced by option widgets
    but no output gate reads it; no production PrintVerbose path exists. Turning
    messages off continues printing, and Reduced/Verbose cannot change detail.

11. **Medium: production sale outcome tracking is absent.**
    bootstrap.lua:731-763 records attempted slot IDs and schedules the next call;
    runtime.lua:103 treats a non-throwing UseContainerItem call as success.
    Upstream services/confirmer.lua tracks pending attempts, item disappearance,
    unlock failures, five-second timeouts and profit summaries. The port's
    SimulationSeller:Observe covers a separate unused implementation. Passing
    its tests cannot establish the behavior of the production seller.

12. **Low: modifier-click wording incorrectly promises a move.**
    runtime.lua:1940-1972 says "Move" / "Item moved to list". The pinned reference
    `src/ui/components/list-panel.lua` explicitly says ADD_TO_LIST and calls Add
    for Shift, Ctrl and Alt. Its `src/lists/lists.lua:247` reconciles only the
    destination's opposite list in the same scope. Ctrl and Alt therefore need
    not remove the source. The earlier recommendation to remove every source
    entry was incorrect and is withdrawn. Fix wording separately from finding 6;
    preserve cross-scope memberships allowed by the reference.

13. **Medium: list scrolling does not clamp after content shrinks.**
    runtime.lua:1898 updateScrollThumb hides the track when content fits without
    resetting vertical scroll. ShowLists changes content height and invokes this
    helper, but clamps the offset only on a subsequent wheel event. Searching
    or removing rows while scrolled down can leave matching rows outside view.
    Native rendering should verify this source-level finding.

14. **Medium parity gap: localization is not implemented.** The TOC loads no
    locale module and runtime labels/messages are English literals. GetLocale
    is used for diagnostics; it does not translate controls. The reference
    includes locale resources and resolves UI strings through its Locale module.

15. **Integration limitation: custom bag overlays are absent.**
    runtime.lua:3645 enumerates stock ContainerFrameNItemN buttons only. It does
    not discover third-party bag widgets. Stock tooltip hooks may still work
    for addons invoking GameTooltip:SetBagItem, but that is not overlay support.

16. **High: equipment-type inclusion wrongly includes cloaks.**
    evaluator.lua:20 lacks the reference's INVTYPE_CLOAK exclusion in
    equipment-types.lua:IsItemTypeSelected. A reproduced common Cloth cloak
    with Cloth inclusion enabled returns JUNK/INCLUDED_EQUIPMENT_TYPE. The
    reference explicitly excludes cloaks from this filter because all classes
    wear them. This can sell a cloak based on a filter that should not match.

17. **Medium: equipment-level filters include fishing poles/generic equipment.**
    evaluator.lua:17 treats every nonempty equipLoc as equipment. Reference
    items.lua:133 additionally excludes generic/cosmetic armor and generic
    weapons/fishing poles, while preserving jewelry/holdable exceptions. Thus
    level-threshold filters can match categories the reference exempts. The
    fallback evaluator in bootstrap.lua needs the same correction as canonical code.
    Actual Lua 5.1 follow-up supplied a known common item, itemLevel=10, price=5,
    unlocked/nonrefundable, with includeBelowItemLevel enabled at 20. A Weapon
    Fishingpole (class 2/subclass 20, INVTYPE_2HWEAPON) and Generic armor
    (class 4/subclass 0, INVTYPE_CHEST) both returned JUNK/BELOW_MIN_ITEM_LEVEL.
    A Generic ring (INVTYPE_FINGER) also matched, as the reference exception
    intends. These are pure evaluator fixtures, not verified live metadata reads.

18. **Medium: Profiles refresh allocates a new set of frames every time.**
    runtime.lua:1630-1634 hides previous rows, drops `profileButtons`, then creates
    new row buttons. Line 1691 also creates four new action buttons per row;
    textures, labels and callbacks are recreated. Hidden WoW frames are not
    destroyed by dropping this Lua array. Repeated page visits and profile actions
    accumulate objects for the session. In actual Lua 5.1, running the existing
    UI interaction fixture and invoking `ShowProfiles(profileCallbacks)` twice
    increased the fixture's frame inventory by 24, then another 24 objects.
    This demonstrates repeated allocation, not a measured live FPS regression.
    Reuse rows/actions and update their bound profile data; verify clicks after
    reorder, rename, reset and deletion still target the correct profile.

19. **Low: release-readiness documentation contradicts itself.**
    README.md advertises release 1.0.0, while docs/ROADMAP.md says the current
    branch is not release-ready and that live acceptance remains unverified.
    Some owner acceptance has since been reported, but exhaustive parity has not.
    Replace stale status prose with a dated, scoped statement distinguishing
    released version, owner-tested paths and open audit findings. This finding
    is documentation consistency, not evidence of a runtime failure.

20. **Medium: toggling exclusions resets the saved action scope.**
    runtime.lua:2665-2674 sends a boolean to SetOption when toggling equipment-set,
    quest-item or unbound-equipment exclusions. store.lua:273-280 replaces the
    option with `{enabled=value,scope="BOTH"}`. Thus an exclusion deliberately
    scoped to SELL or DESTROY changes to BOTH after an off/on cycle. Unbound
    quality selections are copied, but the scope is lost. The reference profile
    option callbacks merge only `{enabled=value}`, preserving other properties.
    Actual Lua 5.1 reproduction initialized each option with scope SELL, then
    called SetOption(key,false) and SetOption(key,true); all three returned scope
    BOTH. Equipment-set and unbound scopes are exposed in the UI; quest scope
    was exercised through Store and is not claimed as a visible UI selector.
    Acceptance: both scope values and selected qualities survive checkbox/card
    toggles and serialization; evaluator results for the other action stay stable.

21. **Medium parity gap: threshold editing can activate a disabled filter.**
    runtime.lua:2788-2803 constructs `{enabled=true,...}` on Apply, and
    3058-3060 explicitly keep the editor active while its filter is off. The
    reference `src/ui/screens/main-window/options/options-builder.lua` disables
    SettingsBox when its card is unchecked and its numeric setters merge only
    `value`, not `enabled`. The port also introduces an Apply step; Enter merely
    clears focus. With the existing interaction fixture's real Store callbacks,
    disabling includeBelowItemLevel, entering 61 and clicking Apply produced
    `enabled=true,value=61`. No inventory action was performed.
    Acceptance: restore the reference enable/disable and value-commit contract;
    editing numeric values must not silently broaden active filter selection.
    Review price Tab/Shift+Tab navigation alongside this fix: reference builder
    wires OnTabPressed, whereas the inspected port threshold inputs do not.

22. **Medium: Default profile cannot be reset although its UI permits it.**
    store.lua:389 rejects id==DEFAULT in ResetProfile. The port profile card
    disables only Rename/Delete, so Reset opens confirmation and then fails.
    Reference profile-card.lua:197-202 likewise protects only Rename/Delete,
    and store/root-reducer.lua:191-201 resets any persisted profile, including
    Default, preserving its identity/name. Lua reproduction set Default.autoSell
    to true, requested ResetProfile("default"), and received false with autoSell
    still true. Acceptance: reset Default's settings/lists while preserving its
    id, name and character assignments; keep Rename/Delete protection unchanged.

23. **High: one malformed saved list entry discards all valid memberships.**
    store.lua:19-26 validates an entire list as one unit; cleanGlobal and
    cleanProfile only copy a list if every entry passes. Otherwise the empty
    default is retained. For current-schema data, Initialize does not retain a
    recovery copy. Reproduction: add exclusion 123, serialize, add key
    `invalid=true` to that same exclusion table, then reload. The resulting
    exclusion 123 and recovery field are both nil. Bootstrap's load path assigns
    the cleaned serialized state back to DejunkWotLKDB, so the original list is
    no longer the active SavedVariables value. This is demonstrated data loss
    in malformed-input recovery, not evidence of live item loss. Discarding
    valid exclusions can change subsequent item eligibility.
    Acceptance: salvage valid IDs, normalize keys consistently with finding 5,
    preserve rejected original data for recovery, and surface the recovery state.
    Exercise global/profile lists, invalid keys/values and over-limit data;
    ordinary valid saves must round-trip without membership changes.

24. **Medium UI parity gap: Auto Junk reopens after a manual close.**
    bootstrap.lua:786-802 checks current visibility but does not use
    junkFrameAutoShown to suppress another automatic open in the same run of
    auto-display. Reference ui/screens/junk-frame.lua:297-310 requires both
    wasAutoShown=false and the window hidden before auto-opening. After the
    reference auto-opens once, manually closing it does not make an unrelated
    bag refresh reopen it. Port reproduction used a real Application/cache,
    one junk item, autoJunkFrame=true and fake visibility methods: MERCHANT_SHOW
    opened once; manual Hide followed by BAG_UPDATE and Tick(0.2) opened again.
    Output: AUTO_JUNK_MANUAL_CLOSE 2 true; inventory mutation count stayed zero.
    Acceptance: preserve manual close while the reference's auto-show marker
    remains set, reset the marker at the same lifecycle boundaries as upstream,
    and verify empty-list and next-merchant-session behavior separately.

## Review evidence and limitations

### Merchant lifecycle continuation

Read bootstrap.lua:728-765,820-878 and scheduler.lua in full; compared the first
190 lines of reference Seller and the auto-show/merchant-close sections of
reference JunkFrame. Confirmed that the legacy vendor-refusal constant exists
in pinned GlobalStrings.lua:3580 and matches the port's constant name.

Reran tests/transaction-tests.lua with actual Lua 5.1: existing adapter, selection,
sale-run limit, duplicate-start, merchant-close cancellation, settings-change
cancellation, failed-dispatch counting, confirmation and delayed-repair checks
all passed. These are mock tests, not a live merchant acceptance run. They do
not establish production outcome tracking (finding 11).

Additional direct probes strengthened finding 7 and introduced finding 24.
No actual UseContainerItem, pickup, deletion or repair operation was performed.
Only the reviewed documents changed; these results are not fixes.

### Equipment and transaction review continuation

Read legacy.lua:65-225 and evaluator.lua:1-185, including the legacy rule-group
matcher, against reference equipment-types.lua in full and Items:IsItemEquipment.
Revisited transaction adapter runtime.lua:1-177 and production action callbacks
in bootstrap.lua:657-732,765-825. This confirmed the previously recorded guards
and mismatches; it did not establish absence of all transaction defects.

Pinned legacy source inspected for mapping evidence:
Blizzard_AuctionUI/Blizzard_AuctionUI.lua:365-407,592-632. It calls
GetAuctionItemClasses and passes selected UI index to GetAuctionItemSubClasses.
It does not prove index-minus-one equals a canonical item class/subclass ID.
No live client or captured API-return table was available for that validation.
Finding 3's confidence is therefore unchanged, and its qualification now notes
that shared positional mappings can agree internally while differing from IDs.

Finding 17 was upgraded with three actual Lua 5.1 fixtures: fishing pole,
generic chest armor and a ring control. All produced JUNK/BELOW_MIN_ITEM_LEVEL;
only the ring is intended to pass the reference's equipment predicate. No sale,
pickup or deletion was dispatched.

### Storage and transport continuation

Read store.lua:170-252 and 385-463, config.lua:1-217, runtime.lua:2100-2225,
and bootstrap.lua:344-380. Compared Default reset with reference ProfileCard,
Profiles screen and root-reducer.lua:191-201. Existing findings about list keys
and opposite memberships remain applicable to import as well as direct edits.

Verified positive properties in the inspected import path: data is parsed as
digit runs without Lua execution; CommitImport checks the store revision before
writing, validates entries into a copy, and replaces the destination only after
validation. A normal profile switch increments that revision, invalidating an
earlier preview. These checks do not solve findings 5, 6 or 23.

Additional schema-load probe for finding 1 used the Application event path, not
only Store.Initialize: `schemaVersion="2"` failed at bootstrap.lua:348 before
recovery. All probes used local fake APIs; no character inventory was touched.

### Application and window follow-up

Read bootstrap.lua:380-657 (slot probing, API classification, projections,
configuration callbacks, commands and setup), runtime.lua:1350-1530 (fallback
configuration, page selection and toggles), 3505-3615 (Lootable card actions and
visibility), 200-275 and 550-650 (tooltip explanations, scroll helper, command
dispatch, action dispatch and saved positions), and src/api.lua in full.

Rejected hypotheses, not defects:

- Lootable is deliberately absent from UISpecialFrames: pinned reference
  `src/ui/screens/lootable-frame.lua:58-68` explicitly sets isSpecialFrame=false.
  Adding Escape closure solely for parity would be incorrect.
- OpenConfig calls ShowProfiles only once. An overlapping pair of source reads
  printed the boundary line twice; a focused reread of bootstrap.lua:508-514
  confirmed no duplicate call in the file.
- ToggleLootableFrame returns true when closing an open window, so Command's
  "No lootable items" message is not triggered by a normal close.

Finding 13's source concern also exists in the shared scroll helper: refresh at
runtime.lua:252 onward hides the track at zero range and clamps a local value
for thumb positioning without writing the clamped scroll offset. This expands
the locations to check; native ScrollFrame behavior remains unverified and this
is not counted as a separately reproduced rendering defect.

Finding 4 now has a direct application-path reproduction with the existing
harness. Output: `BINDING_PROJECTION 0 JUNK QUALITY JUNK`; all mutation sentinels
remained untouched. This is stronger evidence than independently constructing
an evaluator input, because both UI data providers read the same simulated bag.

### Settings review evidence, continuation on 2026-11-16

Manually read runtime.lua:2380-3190 covering checkbox rendering, settings-page
construction, scope callbacks, quality/type/threshold controls, global controls,
refresh and responsive layout; compared the first 240 lines of reference
OptionsBuilder and relevant profile-options enabled callbacks. Also inspected
Store option/global-option setters. Finding 3 applies to UI type choices too:
readAuctionSubclasses at runtime.lua:2832 onward repeats the auction-position
assumption, so correcting only the item reader would leave UI IDs inconsistent.

The current interaction suite explicitly expects editable subcontrols on disabled
filters and Apply to activate them (tests/ui-interaction-tests.lua:1400 onward).
Those assertions encode port behavior, not reference parity. Change them using
the pinned reference contract when implementing finding 21, instead of treating
their current success as evidence that the mismatch is acceptable.

An initial threshold probe read an obsolete mock state after callbacks had been
switched by the fixture; that output was discarded. The accepted reproduction
uses persistedUiStore and persistedCallbacks, then reads the same real Store
after clicking Apply. This distinction prevents reporting a fixture artifact.

### Follow-up evidence, 2026-11-16

New manual inspection covered runtime.lua:1530-1835 (profile popup actions,
profile cards, list creation/search/drop handlers), 1940-1980 (modifier click),
and 2280-2358 (rule draft actions). Compared modifier behavior against pinned
`src/ui/components/list-panel.lua` and `src/lists/lists.lua:85-108,245-275`;
compared profile actions against the first 180 lines of reference
`src/ui/screens/main-window/options/profiles.lua`. Truncated command output is
not counted as fully reviewed source. This is added coverage, not a claim that
all remaining runtime lines or upstream components have now been reviewed.

The allocation probe appended a read-only check to the existing interaction
fixture in memory, measured `#uiFrames` before and after two identical refreshes,
and printed `PROFILE_FRAME_GROWTH 24 24`. No test file or executable source was
changed. Finding 12 was corrected after checking the actual reference semantics;
it must not be used as justification for deleting cross-scope list membership.

### Scope clarification

The report now contains 24 source findings/limitations. Findings 1, 2, 4, 5, 6, 7, 9,
16, 17, 18, 20, 21, 22, 23 and 24 have direct fake-API or pure Lua reproductions; others are source-path
comparisons or explicitly labeled integration/rendering limitations. This is
not 24 demonstrated in-client failures. No runtime or release changes were made.
Latest comparison additionally covered reference defaults, filter order,
equipment semantics and store option setters/profile creation.
An exhaustive every-line sign-off for the 3,714-line runtime and every upstream
UI component is still outstanding; this document must not be represented as one.

1. Fix and regress findings 1, 2 and 9 (saved-data load and action boundaries).
2. Replace guessed category mapping; provide binding data to cache decisions.
3. Reconcile list mutation/import/move semantics and normalize saved ID keys.
4. Align actual action eligibility with settings and implement production outcome
   observation, then connect message options to those events.
5. Clamp scrolling; implement/document localization and supported bag integrations;
   correct obsolete diagnostic strings.

Existing full Lua 5.1 validation was rerun after the review and passes, including
runtime/store/service/destroy/UI suites and reproducible 41-entry archives.
No executable files were changed and no release was published for this review.
The passing suite is not a clean bill of health: the reproductions above expose
missing input-shape, migration and production-path coverage.

Additional inspected paths: transaction pickup/match/delete, production confirmation
and seller loop, merchant repair/session lifecycle, Lootable refresh, global option
validation and chat-option/output wiring. Review remains incomplete for the full
runtime UI; no whole-project line-by-line completion claim is made.

Direct actual-Lua-5.1 probes reproduced malformed saved options, string-key list
removal, opposing membership and numeric context flags with fake APIs only.
Source inspection covered compatibility reads, rule evaluation, cache, store
loading, API/events/scheduler/diagnostics, simulation services and selected
production action paths. Full runtime UI and remaining reference module review
is still outstanding. Passing existing regression suites does not disprove
these findings; several concern inputs absent from current fixtures.
