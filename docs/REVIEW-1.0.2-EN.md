# Fresh source review — 1.0.2, English client

Scope: original 3.3.5a English client; upstream Dejunk revision
`04bafd5e411441ef5b51bb8ed10d208f2d7758f5`; Bagnon revision
`27a08f89819311d772e7ec7a71a41eafb813f122`. Other game languages and
other bag addons are outside the owner's requested scope. This is an
incremental record, not a claim that every line has been reviewed.

## Transaction dispatch and confirmation

Reviewed `src/compat/runtime.lua` lines 1–185 and `src/core/bootstrap.lua`
lines 675–825 against upstream `src/services/confirmer.lua`, including guarded
sale/repair/loot/destruction, pending-sale tracking and sequential dispatch.
The prior fixes recheck slot identity and settings, keep the cursor untouched on
mismatch, and distinguish sale dispatch from observed outcome. Tests use fake APIs.

**Open parity finding:** upstream tracks attempted destruction, reports unlock
failure or five-second uncertainty, and reports confirmation when the item
leaves the bag. The production destroy callback currently prints only
`Destroy attempted.` after dispatch and has no equivalent pending-destroy
observer. Thus a successful API call is not confirmation of destruction, and
failure or uncertainty is not subsequently reported. This is source-observed;
no real item was destroyed to reproduce it. A fix needs fake-API production-path
tests for success, unlock, timeout, and cancellation, and must not treat an
unrelated cursor/slot change as proof without documenting the inference.

**Review boundary:** the remainder of runtime, store, rules, services, UI and the
reference code still require systematic line-by-line comparison. Vendored Waffle
has checksum/integration coverage, not an independent exhaustive security audit.
Actual 1.0.2 client acceptance, including Bagnon, remains outstanding.

**Fixed during review:** sale and destroy decisions were evaluated before the
adapter's final read, but that read compared identity without comparing all
rule inputs. A changed price, quality, level, binding or protection state could
therefore invalidate the earlier decision without preventing dispatch. The
adapter now rejects changed rule inputs before sale or pickup. Lua 5.1 fake-API
regressions verify changed metadata does not dispatch either action. This fix is
local and not yet published.
