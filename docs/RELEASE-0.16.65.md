# 0.16.65-beta.1 — Lootable window layering

Lootable now uses DIALOG strata so the main window's child panels cannot obscure
its rows or intercept their clicks. Its dimensions and item behavior are unchanged.
This is a legacy-client presentation adjustment to upstream's LOW utility window.
UI regression fixtures enforce the layer choice; full actual Lua 5.1 checks and
reproducible packaging pass. Owner confirmed bag visibility, startup keybindings,
Auto Repair and clam detection in the previous candidate.

## تست

هنگامی که پنجره اصلی باز است روی Lootable Items در پایین پنجره کلیک کنید.
پنجره صدف باید کامل جلوی پنجره اصلی دیده شود و کلیک روی آیتم و Ignore کار کند.
