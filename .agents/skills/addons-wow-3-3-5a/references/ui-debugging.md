# UI debugging patterns from the port

## Reproduce the route, not just the page

Test the minimap, slash command, footer, keybinding and gear shortcut separately.
Exercise first creation, repeated reopen, Escape, page switch, drag/drop and reload.
A constructor-only mock misses most of the observed client bugs.

| Symptom | Root cause / investigation | Durable correction |
|---|---|---|
| Lists selected but body blank after minimap reopen | Frame hidden directly while layout component remains VISIBLE; same page selection skips a change | Keep renderer/component visibility consistent; explicitly restore externally hidden root/selected frames; regress reopen cycles |
| Escape does not close a window | Root absent from `UISpecialFrames`; focused EditBox consumes Escape | Register named appropriate roots; choose deliberate edit-box behavior; test focused and unfocused cases |
| Search Escape only removes focus | Missing search-clear step | Clear text and focus; preserve selected page; match reference behavior |
| Transport X visible but unclickable | Button has icon but no width/height, or wrong frame level | Assign an actual click area (24×24 in this case), enable mouse and check layering |
| Drop fails although click works | Only OnMouseDown was implemented | Handle OnReceiveDrag on rows, panel/background and scroll content; forward through mouse-capturing child regions |
| Double/ornate input border | InputBoxTemplate inherited textures plus a custom backdrop | Use a plain EditBox with font/insets/size and one explicit border |
| Minimap looks like two icons | Tracking-border artwork anchored at CENTER rather than its stock offset | Inspect frame/texture count first; correct the stock tracking-border anchor to TOPLEFT where applicable |
| Profiles buttons draw through Junk | Child frame levels compete within same strata; translucent backgrounds | Use a coherent window/layer policy and opaque surfaces; fix mouse blocking too |
| Gear opens options behind Junk | Two roots remain centered and visible | Dismiss/bring forward according to requested product flow; port's gear dismisses Junk before opening options |
| Sell tooltip says no merchant when it is open | Callback captured a global because local was declared later | Declare shared state before closures; add a test for the tooltip's actual session state |
| Checkbox label does nothing | OnClick assigned only to the CheckButton | Route label-hit button through the same handler; include click button/modifiers |
| Profile/merchant controls drift over content | Screen coordinates copied from a different UI/client scale | Measure local parent anchors against target FrameXML; migrate obsolete defaults without overwriting custom points |
| Legacy yellow scroll arrows remain | UIPanelScrollFrameTemplate still used despite custom art elsewhere | Use native ScrollFrame with an explicit shared track, thumb, wheel/clamp and pointer handling |

## Escape and visibility

Native `UISpecialFrames` stores **global frame names**. Add a name once; ensure
that the name resolves in the actual global table. Never add anonymous frames or
register a new keyboard-capturing full-screen frame merely to receive Escape.
A Lootable utility window may deliberately be excluded if the reference does so.

If Escape hides the frame outside a layout library, its internal visibility cache
may still say VISIBLE. Reopening must reconcile both the root and selected child.
Track `mainWindowVisible` through actual OnHide as well as button callbacks.

Define edit behavior by context: search clears then loses focus; profile popup
cancels and hides its blocker; Transport can dismiss directly. Verify that a
hidden modal frame does not leave its mouse-blocking parent visible.

## Input and mouse delivery

- Use explicit sizes, text insets, font object, mouse enablement and click registration.
- Call SetFocus only after ancestors are visible; original 3.3.5 can drop a focus
  request made while the edit box's parent is hidden.
- Export fills/selects plain text; it does not create a file or set the OS clipboard.
  Copying is a user Ctrl+C action. Test replacing user-edited text as well as first open.
- A drop handler may have no item argument; inspect the cursor. Add the intended
  item ID first and clear only that deliberately submitted cursor after success.
- Do not route a bag drop into a loot/use handler. Changing list membership is not
  the same operation as opening an inventory item.
- Header/scroll/row children can capture the mouse. Wire the actual target regions,
  not only an unreachable parent. Avoid double-firing a drop followed by a click.
- Texture tint alone draws no stripe: assign a texture before SetVertexColor.
- Reused rows must reset quality color, disabled state, tooltip data and text when
  the new item has missing metadata; otherwise the previous row's style leaks.

## Layers, movement and scrollbars

Frame strata order includes LOW, MEDIUM, HIGH, DIALOG and FULLSCREEN_DIALOG.
Child frame levels matter within strata. Do not assign globally huge levels as a
substitute for a coherent hierarchy. Dim/disable competing actions while busy.
Separate mouse-blocking behavior from visual opacity. Check that native dialogs
remain operable above addon windows.

For merchant placement in stock 12340, the researched MerchantFrame is 384×512,
its name is anchored at y=-17 and the first item row begins at y=-80. The specific
Dejunk 108×28 control was moved to TOPLEFT (210,-44), away from the portrait.
These are **case-specific measurements**, not universal placement constants.
Old defaults (60,-28)/(60,-44) were migrated; intentional custom positions were kept.

A custom track should react to scroll-range and size changes, clamp offsets to
0..range, hide when content fits, and stop pointer-drag updates on mouse-up/hide.
Check GetVerticalScrollRange and effective scale in the target API; mocks should
provide realistic geometry. Test wheel input at both boundaries and changing content.

## Retained settings

Saved points are records with point, relative target, relative point and offsets.
Validate targets rather than resolving arbitrary global names from imported text.
Changing only fresh defaults does not fix existing installs: explicitly identify
and migrate obsolete defaults, while preserving user-dragged positions.
