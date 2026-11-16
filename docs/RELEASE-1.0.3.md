# Dejunk-WotLK 1.0.3

- Fix a list loading indicator that could reappear indefinitely after an item-info timeout. Unresolved entries show their item ID instead of an anonymous Item label.
- Reject sale or destroy pickup if rule-relevant item data changes between evaluation and the final slot read.
- Includes Bagnon support and previous fixes. Lua 5.1 fake-API and UI regression tests pass; in-game acceptance remains required. A pending-destroy outcome observer remains an open parity issue; dispatch alone is not confirmation.

## نصب و تست

پوشهٔ قبلی Dejunk را با فایل ZIP جدید جایگزین و `/reload` کنید. فهرست‌هایی که آیتم نامشخص دارند را باز کنید؛ پس از حداکثر حدود ۳۰ ثانیه نشانگر باید خاموش شود و شناسهٔ آیتم نمایش داده شود. اگر هنوز نام لود نشد، شناسه و تصویر را برای بررسی بفرستید. آیتم را حذف نکنید مگر مطمئن باشید به آن نیاز ندارید.
