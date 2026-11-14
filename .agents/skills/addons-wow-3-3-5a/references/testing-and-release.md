# Verification, evidence and delivery

## Evidence ladder

Keep these distinct in notes and user-facing reports:

1. Source observation at an immutable commit/file/line.
2. An implementation proposal inferred from that source.
3. Passing pure/model or fake-API tests.
4. Actual target-client observations, tied to the installed addon build.
5. User acceptance for the tested scenario.

A modern client, a screenshot of an older build or a successful luac check does
not prove current original-client behavior. A report that "everything works"
confirms what was actually exercised; it does not fill untested Lootable/locale
or transaction cases. Never mark a parity matrix complete just to close a task.

## Useful automated checks

- TOC metadata, ordered Lua/XML dependencies, file existence and safe paths.
- Actual Lua 5.1 syntax plus pure store/filter/sort/migration fixtures.
- API tuple shapes: nil versus failure, lock flags, zero vendor value, refund's
  fifth field, missing item cache, binding/quest/sets and invalid slots.
- Scheduler cancellation, bounded retries, event coalescing and invalidation
  during a scan. Newly scheduled jobs must not recursively execute in one tick.
- UI: first/repeated open, each navigation route, external Escape hide, focused
  EditBox Escape, OnReceiveDrag, label clicks, modifier transfers, native 1/nil
  GetChecked, overflow scroll clamps and stale-row reuse.
- Actions: duplicate start, mixed sale/destroy rows, failed dispatched sale calls,
  cap, merchant close/refusal, settings revision changes, delayed repair expiry,
  confirmation cancel/single-use and changed slot/cursor.
- ZIP folder layout, source equality, CRC, determinism, notices and overwrite refusal.

Make mocks implement the methods and return shapes the real path uses. Missing
GetHeight/GetVerticalScroll/GetScript can create false conclusions in a fixture;
adding them must not replace an actual behavioral assertion. Directly calling
OnClick does not test mouse hit regions; inspect size/layer/input routing and
still seek native-client confirmation.

## Original-client test sequence

1. Identify the installed build with GetAddOnMetadata and GetBuildInfo. Back up
   SavedVariables; replace the old folder instead of mixing source revisions.
2. Enable Lua errors (`/console scriptErrors 1` then `/reload`). Test a minimal
   addon set before reintroducing other UI/bag addons.
3. Check all screens and routes, Escape, text input, drops, search, transport copy,
   profile CRUD, keybindings, scrollbars, saved points and reload persistence.
4. Test merchant/minimap controls in both contexts. Confirm disabled states and
   tooltip explanations before harmless action acceptance.
5. Only if authorized, use a disposable test character and low-value items for
   sale/repair/loot. Verify identities/counts/funds and stop/cancel behavior.
6. For destroy UI acceptance, open the confirmation and Cancel. Do not perform
   actual deletion during development verification.
7. Report success/failure/not run per scenario, version, build, settings, full Lua
   error and exact preceding action. Avoid personal account data in public logs.

## Packaging

A release ZIP should contain one directly installable addon folder. Include
runtime load-graph files, required assets, own license and all applicable third-party
notices. Do not ship `.git`, caches, old ZIPs, logs, WTF/SavedVariables, client files,
research checkouts, credentials or testing inventory records.

Use deterministic ordering/timestamps. Refuse accidental overwrites. Check both
archive contents and release metadata. Compare the downloaded release asset's
SHA-256 with the exact locally validated artifact when possible; GitHub API
asset digests can provide an independent comparison if binary downloads are blocked.

## Licensing

Audit the pinned source's README and asset credits, not only root LICENSE.
For the Dejunk reference:

- Compatibility code: project's own MIT notice.
- Vendored Waffle: MIT and retained moody notice, pinned checksum.
- Cash/Dejunk logo: Lorc, source link and CC BY 3.0 license link.
- Font Awesome UI art: Font Awesome/Fonticons, source link and CC BY 4.0 link.
- State whether art is unchanged or modified; preserve upstream attribution.

Do not generalize those licenses to another project's assets. No endorsement is
implied by attribution. Never redistribute Blizzard's client or FrameXML merely
because a research mirror is publicly accessible.

## GitHub publication and cleanup

- Honor prior user authorization and requested destination. The owner of this
  project asked to receive downloadable files **only from GitHub**.
- Prefer the available GitHub connector for supported operations. An invalid
  local gh token does not mean the connector is unavailable. Never print credentials.
- Inspect default branch, refs and existing releases before publication. In this
  project main initially had only README; code was on development/test branches.
- Build a clean tree, preserve ancestry and update refs with an expected head.
  Do not force-push past unrelated work. Artifact ZIPs belong in Releases.
- If no release-writing API is exposed, an ordinary, reviewed GitHub Actions
  release workflow can validate, package and create the release using its scoped
  builtin token, within the user's authorized scope. This is not a way around a
  rejected operation, access restriction or missing user authorization.
- Run source/tests before attaching artifacts. Use contents:read by default and
  contents:write only for the release/cleanup jobs. Avoid untrusted PR code in
  privileged release workflows. Pin actions and vendored code to known revisions.
- Delete superseded download branches only when authorized and after successful
  release publication. Inventory names/heads; retain changed refs, use leases,
  and preserve meaningful source/history. Do not delete licenses/tests as "junk".
- Verify workflow conclusion, release draft/prerelease flags, asset names/digests,
  source tree and branch cleanup. A generated URL is not proof of publication.
- If automatic approval review rejects an operation, report the action and stated
  reason. Complete unaffected work. Request the missing specific approval only
  if required; do not bypass rejection or ask again when existing authorization
  already satisfies it and evidence can establish that fact.

A complete installable package can still be a beta. In this case it was published
as 0.16.60-beta.1 because exact parity and untested client scenarios remained open.
